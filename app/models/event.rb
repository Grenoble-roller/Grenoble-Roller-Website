class Event < ApplicationRecord
  include Hashid::Rails
  include Auditable

  belongs_to :creator_user, class_name: "User"
  belongs_to :organizer, class_name: "EventOrganizer", optional: true
  belongs_to :route, optional: true # Parcours principal (rétrocompatibilité)
  has_many :event_loop_routes, dependent: :destroy
  has_many :loop_routes, through: :event_loop_routes, source: :route
  has_many :attendances, dependent: :destroy
  has_many :users, through: :attendances
  has_many :waitlist_entries, dependent: :destroy

  # Active Storage attachments
  has_one_attached :cover_image

  # Canonical variants — format unique 16:9 centré (décision bénévoles 2026-05)
  # - banner (16:9, 1200×675) : hero, surfaces larges
  # - square (16:9, 800×450)  : cartes, listes (nommé square pour compat appels existants)
  # - thumb  (16:9, 400×225)  : miniatures

  def cover_image_banner
    return nil unless cover_image.attached?
    cover_image.variant(resize_to_fill: [ 1200, 675 ], format: :webp, saver: { quality: 85 })
  end

  def cover_image_square
    return nil unless cover_image.attached?
    cover_image.variant(resize_to_fill: [ 800, 450 ], format: :webp, saver: { quality: 82 })
  end

  def cover_image_thumb
    return nil unless cover_image.attached?
    cover_image.variant(resize_to_fill: [ 400, 225 ], format: :webp, saver: { quality: 75 })
  end

  # Legacy aliases
  def cover_image_hero
    cover_image_banner
  end

  def cover_image_card
    cover_image_square
  end

  def cover_image_card_featured
    cover_image_banner
  end

  enum :status, {
    draft: "draft",      # Brouillon / En attente de validation
    published: "published", # Publié / Validé
    rejected: "rejected",   # Refusé (demande non aboutie)
    canceled: "canceled"    # Annulé
  }, validate: true

  # Traductions des statuts en français
  def status_label
    case status
    when "draft"
      "En attente de validation"
    when "published"
      "Publié"
    when "rejected"
      "Refusé"
    when "canceled"
      "Annulé"
    else
      status.humanize
    end
  end
  enum :level, { beginner: "beginner", intermediate: "intermediate", advanced: "advanced", all_levels: "all_levels" }, validate: true, prefix: true

  validates :status, presence: true
  validates :start_at, presence: true
  validates :duration_min, presence: true, numericality: { only_integer: true, greater_than: 0 }
  validate :duration_multiple_of_five
  validates :title, presence: true, length: { minimum: 5, maximum: 140 }
  # Max 5000: balance between detail and readability; DB is text (unlimited); iCal has no DESCRIPTION limit
  validates :description, presence: true, length: { minimum: 20, maximum: 5000 }, unless: :initiation?
  validates :price_cents, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :currency, presence: true, length: { is: 3 }
  validates :location_text, presence: true, length: { minimum: 3, maximum: 255 }
  validates :max_participants, presence: true, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validate :cover_image_must_be_present, unless: :skip_cover_image_validation?
  validate :initiation_cannot_require_payment

  # GPS optionnel, mais si meeting_lat présente, meeting_lng obligatoire et vice-versa
  validates :meeting_lat, presence: true, if: :meeting_lng?
  validates :meeting_lng, presence: true, if: :meeting_lat?
  validates :meeting_lat, numericality: { greater_than_or_equal_to: -90, less_than_or_equal_to: 90 }, allow_nil: true
  validates :meeting_lng, numericality: { greater_than_or_equal_to: -180, less_than_or_equal_to: 180 }, allow_nil: true

  # Niveau et distance toujours requis
  validates :level, presence: true
  validates :distance_km, presence: true, numericality: { greater_than_or_equal_to: 0.1 }, unless: :initiation?

  # Méthode helper pour vérifier si c'est une initiation
  def initiation?
    is_a?(Event::Initiation)
  end

  # Public display name for the organizing entity (association) or event creator fallback
  def display_organizer_name
    organizer&.name.presence || creator_user&.display_name
  end

  # External URL for the organizing entity, if configured
  def display_organizer_url
    organizer&.url
  end

  scope :upcoming, -> { where("start_at + (duration_min * INTERVAL '1 minute') > ?", Time.current) }
  scope :past, -> { where("start_at + (duration_min * INTERVAL '1 minute') <= ?", Time.current) }
  scope :published, -> { where(status: "published") }

  # Événements visibles pour les utilisateurs (publiés + annulés pour information)
  scope :visible, -> { where(status: [ "published", "canceled" ]) }

  # Exclure les initiations (pour n'afficher que les événements/randos)
  scope :not_initiations, -> { where(type: [ nil, "Event" ]) }

  # Événements en attente de validation (pour les modérateurs)
  scope :pending_validation, -> { where(status: "draft") }

  # Événements refusés (pour les modérateurs)
  scope :rejected, -> { where(status: "rejected") }

  def self.ransackable_attributes(_auth_object = nil)
    %w[
      id
      title
      status
      start_at
      duration_min
      price_cents
      currency
      location_text
      meeting_lat
      meeting_lng
      route_id
      level
      distance_km
      creator_user_id
      organizer_id
      max_participants
      attendances_count
      type
      created_at
      updated_at
    ]
  end

  def self.ransackable_associations(_auth_object = nil)
    %w[attendances creator_user organizer route users]
  end

  # Vérifie si l'événement a une limite de participants (0 = illimité)
  def unlimited?
    max_participants.zero?
  end

  def requires_online_payment?
    payment_required? && !initiation?
  end

  # Spots counted toward capacity (payment-pending holds count for paid randos only).
  def occupied_spots_for_capacity
    base = attendances.where(is_volunteer: false).where.not(status: "canceled")

    if requires_online_payment?
      base.where(
        "status != 'pending' OR (status = 'pending' AND payment_expires_at IS NOT NULL AND payment_expires_at > ?)",
        Time.current
      ).count
    else
      base.where.not(status: "pending").count
    end
  end

  # Vérifie si l'événement est plein
  def full?
    return false if unlimited?

    occupied_spots_for_capacity >= max_participants
  end

  # Retourne le nombre de places restantes
  def remaining_spots
    return nil if unlimited?

    [ max_participants - occupied_spots_for_capacity, 0 ].max
  end

  # Vérifie s'il reste des places disponibles
  def has_available_spots?
    return true if unlimited?

    occupied_spots_for_capacity < max_participants
  end

  # Compte les inscriptions actives (non annulées, incluant pending pour verrouiller les places)
  def active_attendances_count
    attendances.where.not(status: "canceled").count
  end

  # Notifier la prochaine personne en liste d'attente
  def notify_next_waitlist_entry
    WaitlistEntry.notify_next_in_queue(self, count: 1)
  end

  # Inscriptions closes at start; "past" listings use end time (start_at + duration_min).
  def started?
    start_at.present? && start_at <= Time.current
  end

  def past?
    finished?
  end

  def ongoing?
    started? && !finished?
  end

  # Calcule la date de fin de l'événement (start_at + duration_min)
  def end_at
    return nil unless start_at && duration_min
    start_at + duration_min.minutes
  end

  # Vérifie si l'événement est terminé (après sa date de fin)
  def finished?
    end_at.present? && end_at <= Time.current
  end

  # Remet en stock tous les rollers prêtés pour cet événement
  # Vérifie si l'événement a du matériel prêté
  def has_equipment_loaned?
    return false unless is_a?(Event::Initiation)

    attendances
      .where(needs_equipment: true)
      .where.not(roller_size: nil)
      .where.not(status: "canceled")
      .exists?
  end

  # Marks equipment as returned for this initiation (releases reservations, physical stock unchanged).
  def return_roller_stock
    return unless is_a?(Event::Initiation)

    if stock_returned_at.present?
      Rails.logger.info("Stock déjà remis en place pour initiation ##{id} le #{stock_returned_at}")
      return nil
    end

    attendances_to_process = attendances
      .where(needs_equipment: true)
      .where.not(roller_size: nil)
      .where.not(status: "canceled")

    count = attendances_to_process.count

    if count.positive?
      update_column(:stock_returned_at, Time.current)
      Rails.logger.info("Matériel marqué rendu pour initiation ##{id}: #{count} réservation(s) clôturée(s)")
    end

    count
  end

  # Calculer la distance totale si plusieurs boucles (formulaire admin, stats internes)
  def total_distance_km
    # Si on utilise le nouveau système avec event_loop_routes
    if event_loop_routes.any?
      event_loop_routes.sum(:distance_km)
    # Sinon, utiliser l'ancien système (rétrocompatibilité)
    elsif loops_count && loops_count > 1
      (distance_km || 0) * loops_count
    else
      distance_km
    end
  end

  # Distances par boucle, dans l'ordre (affichage public sans total cumulé)
  def loop_distance_km_values
    if loops_count && loops_count > 1
      loops_with_routes.map { |loop_data| loop_data[:distance_km] }.compact
    else
      [ distance_km ].compact
    end
  end

  # Retourne les parcours par boucle (pour affichage)
  def loops_with_routes
    return [] unless loops_count && loops_count > 1

    if event_loop_routes.any?
      # Nouveau système : parcours différents par boucle
      # S'assurer que toutes les boucles sont présentes (y compris la boucle 1)
      loops_data = {}

      # Charger les boucles depuis event_loop_routes
      event_loop_routes.order(:loop_number).each do |elr|
        loops_data[elr.loop_number] = {
          loop_number: elr.loop_number,
          route: elr.route,
          distance_km: elr.distance_km
        }
      end

      # Si la boucle 1 n'est pas dans event_loop_routes, utiliser le parcours principal
      unless loops_data[1]
        loops_data[1] = {
          loop_number: 1,
          route: route,
          distance_km: distance_km
        }
      end

      # Retourner dans l'ordre des boucles
      (1..loops_count).map { |num| loops_data[num] }.compact
    else
      # Ancien système : même parcours pour toutes les boucles
      (1..loops_count).map do |num|
        {
          loop_number: num,
          route: route,
          distance_km: distance_km
        }
      end
    end
  end

  # Vérifie si l'événement a été créé récemment (dans les 4 dernières semaines)
  def recent?
    created_at >= 7.days.ago
  end

  # Désactiver la validation de cover image uniquement dans le contexte RSpec
  # (tests automatisés), pour éviter de dépendre du stockage distant (S3/MinIO).
  def skip_cover_image_validation?
    defined?(RSpec)
  end

  # Vérifie si l'événement a des coordonnées GPS
  def has_gps_coordinates?
    meeting_lat.present? && meeting_lng.present?
  end

  # Retourne l'URL Google Maps (utilise les coordonnées GPS si disponibles, sinon l'adresse textuelle)
  def google_maps_url
    if has_gps_coordinates?
      "https://www.google.com/maps?q=#{meeting_lat},#{meeting_lng}"
    elsif location_text.present?
      # Utiliser l'adresse textuelle si pas de coordonnées GPS
      encoded_address = URI.encode_www_form_component(location_text)
      "https://www.google.com/maps/search/?api=1&query=#{encoded_address}"
    else
      nil
    end
  end

  # Retourne l'URL Waze (utilise les coordonnées GPS si disponibles, sinon l'adresse textuelle)
  def waze_url
    if has_gps_coordinates?
      "https://www.waze.com/ul?ll=#{meeting_lat},#{meeting_lng}&navigate=yes"
    elsif location_text.present?
      # Utiliser l'adresse textuelle si pas de coordonnées GPS
      encoded_address = URI.encode_www_form_component(location_text)
      "https://www.waze.com/ul?q=#{encoded_address}&navigate=yes"
    else
      nil
    end
  end

  # Callback pour notifier tous les inscrits et bénévoles quand l'événement est annulé
  after_commit :notify_attendees_on_cancellation, on: [ :update ], if: -> { saved_change_to_status? && canceled? }

    # Auditable concern methods
    def audit_actor
      creator_user
    end

    def audit_attributes
      {
        title: title,
        start_at: start_at,
        duration_min: duration_min,
        status: status,
        max_participants: max_participants,
        location_text: location_text,
        level: level,
        distance_km: distance_km,
        price_cents: price_cents,
        currency: currency,
        meeting_lat: meeting_lat,
        meeting_lng: meeting_lng,
        cover_image_attached: cover_image.attached?
      }
    end

  private

  def initiation_cannot_require_payment
    return unless initiation? && payment_required?

    errors.add(:payment_required, "ne peut pas être activé pour une initiation")
  end

  def duration_multiple_of_five
    return if duration_min.blank?

    errors.add(:duration_min, "doit être un multiple de 5") unless (duration_min % 5).zero?
  end

  def cover_image_must_be_present
    errors.add(:cover_image, "doit être présente") unless cover_image.attached?
  end

  # Notifie tous les inscrits et bénévoles quand l'événement est annulé
  def notify_attendees_on_cancellation
    # Ne notifier que si l'événement était publié avant (pas si c'était déjà annulé ou en draft)
    previous_status = status_before_last_save
    return unless previous_status == "published"

    is_initiation = is_a?(Event::Initiation)

    # Récupérer toutes les attendances actives (inscrits et bénévoles)
    active_attendances = attendances.active.includes(:user, :child_membership)

    # Grouper les attendances par utilisateur (parent)
    # Un parent peut avoir plusieurs attendances pour le même événement (lui-même + enfants)
    attendances_by_user = active_attendances.group_by(&:user_id)

    attendances_by_user.each do |user_id, user_attendances|
      user = user_attendances.first.user
      next unless user&.email.present?

      # Vérifier les préférences utilisateur
      if is_initiation
        next unless user.wants_initiation_mail?
      else
        next unless user.wants_events_mail?
      end

      # Envoyer UN SEUL email avec toutes les attendances de cet utilisateur pour cet événement
      EventMailer.event_cancelled(user, self, user_attendances).deliver_later
    end

    Rails.logger.info("[Event] #{attendances_by_user.count} email(s) d'annulation envoyé(s) pour événement ##{id}")
  rescue StandardError => e
    Rails.logger.error("[Event] Erreur lors de l'envoi des emails d'annulation pour événement ##{id}: #{e.message}")
    Rails.logger.error(e.backtrace.join("\n"))
    Sentry.capture_exception(e, extra: { event_id: id, event_title: title }) if defined?(Sentry)
  end
end
