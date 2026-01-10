class Event::Initiation < Event
  # Scopes spécifiques
  scope :upcoming_initiations, -> { where("start_at > ?", Time.current).order(:start_at) }
  scope :by_season, ->(season) { where(season: season) }

  # Validations spécifiques aux initiations
  # distance_km : doit être 0 (pas de parcours) - la validation du parent est désactivée avec unless: :initiation?
  validates :distance_km, presence: true, numericality: { greater_than_or_equal_to: 0 }

  # description : assouplir la validation (minimum 10 caractères au lieu de 20)
  # La validation du parent est désactivée avec unless: :initiation?, on redéfinit ici
  validates :description, presence: true, length: { minimum: 10, maximum: 1000 }

  # Validations spécifiques
  validates :max_participants, presence: true, numericality: { greater_than: 0 }

  # Callback pour forcer distance_km = 0 pour les initiations (avant validation)
  before_validation :set_distance_km_to_zero, on: [ :create, :update ]

  # Callback pour planifier l'envoi du rapport participants le jour de l'initiation à 7h
  # Créé automatiquement quand l'initiation est publiée
  after_commit :schedule_participants_report, on: [ :create, :update ], if: -> { should_schedule_report? && (saved_change_to_status? || saved_change_to_start_at?) }

  # Callback pour annuler le job si l'initiation est annulée/rejetée après publication
  after_commit :cancel_scheduled_report, on: [ :update ], if: -> { should_cancel_report? && saved_change_to_status? }

  # Méthodes métier
  def full?
    if allow_non_member_discovery?
      # Si l'option est activée, vérifier les places séparément
      # Si non_member_discovery_slots est nil (illimité), vérifier seulement les places adhérents
      if non_member_discovery_slots.nil?
        available_member_places <= 0
      else
        available_member_places <= 0 && available_non_member_places <= 0
      end
    else
      # Sinon, comportement classique : tout le monde peut s'inscrire
      available_places <= 0
    end
  end

  def full_for_members?
    return false unless allow_non_member_discovery?
    available_member_places <= 0
  end

  def full_for_non_members?
    return false unless allow_non_member_discovery?
    # Si non_member_discovery_slots est nil, c'est illimité → jamais complet
    return false if non_member_discovery_slots.nil?
    # Si non_member_discovery_slots est défini, vérifier si on a atteint la limite
    available_non_member_places <= 0
  end

  def available_places
    if allow_non_member_discovery?
      # Si l'option est activée, retourner le total des places disponibles
      # Si non_member_discovery_slots est nil (illimité), retourner Float::INFINITY
      if available_non_member_places == Float::INFINITY
        Float::INFINITY
      else
        available_member_places + available_non_member_places
      end
    else
      # Sinon, comportement classique
      max_participants - participants_count
    end
  end

  def available_member_places
    return max_participants - participants_count unless allow_non_member_discovery?
    # Places pour adhérents = max_participants - non_member_discovery_slots - non_member_count
    member_slots = max_participants - (non_member_discovery_slots || 0)
    member_slots - member_participants_count
  end

  def available_non_member_places
    return 0 unless allow_non_member_discovery?
    # Si non_member_discovery_slots est nil, c'est illimité → retourner un grand nombre
    return Float::INFINITY if non_member_discovery_slots.nil?
    # Si non_member_discovery_slots est défini, calculer les places restantes
    non_member_discovery_slots - non_member_participants_count
  end

  # Comptage des participants (exclut les bénévoles)
  # Inclut les "pending" pour l'affichage visuel (places verrouillées)
  def participants_count
    attendances.where(is_volunteer: false, status: [ "registered", "present", "pending" ]).count
  end

  # Comptage des participants adultes (parent, pas d'enfant)
  # Inclut les "pending" pour l'affichage visuel
  def adult_participants_count
    attendances.where(is_volunteer: false, child_membership_id: nil, status: [ "registered", "present", "pending" ]).count
  end

  # Comptage des participants enfants
  # Inclut les "pending" pour l'affichage visuel
  def child_participants_count
    attendances.where(is_volunteer: false).where.not(child_membership_id: nil).where(status: [ "registered", "present", "pending" ]).count
  end

  # Comptage des participants adhérents (optimisé pour éviter N+1)
  # Inclut les "pending" pour l'affichage visuel
  def member_participants_count
    # Utiliser includes pour éviter les requêtes N+1
    participant_attendances = attendances.includes(:user, :child_membership)
                                         .where(is_volunteer: false, status: [ "registered", "present", "pending" ])

    count = 0
    participant_attendances.each do |attendance|
      is_member = false

      if attendance.child_membership_id.present?
        # Pour un enfant : vérifier l'adhésion enfant
        is_member = attendance.child_membership&.active?
      else
        # Pour le parent : vérifier UNIQUEMENT l'adhésion parent (pas celle des enfants)
        # ⚠️ v4.0 : Les essais gratuits sont NOMINATIFS - pas d'adhésion "famille"
        is_member = attendance.user.memberships.active_now.where(is_child_membership: false).exists?
      end

      count += 1 if is_member
    end
    count
  end

  # Comptage des participants non-adhérents
  def non_member_participants_count
    participants_count - member_participants_count
  end

  # Comptage des bénévoles (exclut les participants)
  # Inclut les "pending" pour l'affichage visuel
  def volunteers_count
    attendances.where(is_volunteer: true, status: [ "registered", "present", "pending" ]).count
  end

  # Comptage total (participants + bénévoles)
  def total_attendances_count
    participants_count + volunteers_count
  end

  # Override pour initiations : max_participants doit être > 0 (pas illimité)
  def unlimited?
    false
  end

  private

  def set_distance_km_to_zero
    self.distance_km = 0
  end

  # Détermine si on doit planifier le rapport (initiation publiée avec start_at dans le futur)
  def should_schedule_report?
    published? && start_at.present? && start_at.future? && participants_report_sent_at.nil?
  end

  # Détermine si on doit annuler le job planifié (initiation annulée/rejetée après publication)
  def should_cancel_report?
    (canceled? || rejected?) && participants_report_sent_at.nil? && start_at.present? && start_at.future?
  end

  # Planifie l'envoi du rapport le jour de l'initiation à 7h00
  def schedule_participants_report
    return unless should_schedule_report?

    # Calculer la date/heure d'exécution : jour de l'initiation à 7h00
    report_time = start_at.beginning_of_day + 7.hours

    # Si l'heure est déjà passée aujourd'hui, ne pas planifier (sécurité)
    return if report_time.past?

    # Planifier le job avec perform_at
    InitiationParticipantsReportJob.set(wait_until: report_time).perform_later(id)

    Rails.logger.info("[Event::Initiation] Rapport participants planifié pour initiation ##{id} le #{report_time}")
  rescue StandardError => e
    Rails.logger.error("[Event::Initiation] Erreur lors de la planification du rapport pour initiation ##{id}: #{e.message}")
    Sentry.capture_exception(e, extra: { initiation_id: id }) if defined?(Sentry)
  end

  # Annule le job planifié si l'initiation est annulée/rejetée
  def cancel_scheduled_report
    return unless should_cancel_report?

    # Trouver et annuler les jobs planifiés pour cette initiation
    # Solid Queue stocke les jobs dans solid_queue_jobs avec les arguments en JSON
    scheduled_jobs = SolidQueue::Job
                      .where(class_name: "InitiationParticipantsReportJob")
                      .where(finished_at: nil)
                      .where.not(scheduled_at: nil) # Jobs planifiés uniquement

    canceled_count = 0
    scheduled_jobs.find_each do |job|
      # Vérifier que c'est bien le bon job (arguments contient l'ID)
      # Les arguments sont stockés en JSON dans Solid Queue
      begin
        job_args = JSON.parse(job.arguments) if job.arguments.present?
        if job_args.is_a?(Array) && job_args.first == id
          job.update(finished_at: Time.current)
          canceled_count += 1
        end
      rescue JSON::ParserError
        # Si les arguments ne sont pas en JSON valide, ignorer
        next
      end
    end

    Rails.logger.info("[Event::Initiation] #{canceled_count} job(s) de rapport annulé(s) pour initiation ##{id}") if canceled_count > 0
  rescue StandardError => e
    Rails.logger.error("[Event::Initiation] Erreur lors de l'annulation du job pour initiation ##{id}: #{e.message}")
    Sentry.capture_exception(e, extra: { initiation_id: id }) if defined?(Sentry)
  end
end
