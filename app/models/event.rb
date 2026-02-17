class Event < ApplicationRecord
  include Hashid::Rails

  belongs_to :creator_user, class_name: "User"
  belongs_to :route, optional: true # Parcours principal (rétrocompatibilité)
  has_many :event_loop_routes, dependent: :destroy
  has_many :loop_routes, through: :event_loop_routes, source: :route
  has_many :attendances, dependent: :destroy
  has_many :users, through: :attendances
  has_many :waitlist_entries, dependent: :destroy

  # Active Storage attachments
  has_one_attached :cover_image

  # Variants optimisés pour différents contextes d'affichage
  # Utilisation: event.cover_image.variant(:hero), event.cover_image.variant(:card), etc.

  def cover_image_hero
    return nil unless cover_image.attached?
    # Hero image (page détail) : 1200x500px max (ratio 2.4:1)
    # Desktop: 500px height, Tablet: 400px, Mobile: 300px
    cover_image.variant(resize_to_limit: [ 1200, 500 ], format: :webp, saver: { quality: 85 })
  end

  def cover_image_card
    return nil unless cover_image.attached?
    # Card event (liste) : 800x200px (ratio 4:1)
    cover_image.variant(resize_to_limit: [ 800, 200 ], format: :webp, saver: { quality: 80 })
  end

  def cover_image_card_featured
    return nil unless cover_image.attached?
    # Card featured (événement mis en avant) : 1200x350px (ratio ~3.4:1)
    cover_image.variant(resize_to_limit: [ 1200, 350 ], format: :webp, saver: { quality: 85 })
  end

  def cover_image_thumb
    return nil unless cover_image.attached?
    # Thumbnail (formulaire/admin) : 400x200px
    cover_image.variant(resize_to_limit: [ 400, 200 ], format: :webp, saver: { quality: 75 })
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
  validates :description, presence: true, length: { minimum: 20, maximum: 1000 }, unless: :initiation?
  validates :price_cents, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :currency, presence: true, length: { is: 3 }
  validates :location_text, presence: true, length: { minimum: 3, maximum: 255 }
  validates :max_participants, presence: true, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validate :cover_image_must_be_present, unless: :skip_cover_image_validation?

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

  # Quand la capacité augmente, notifier en priorité la file d'attente (avant toute autre inscription)
  after_save :notify_waitlist_if_capacity_increased, if: :saved_change_to_max_participants?

  scope :upcoming, -> { where("start_at > ?", Time.current) }
  scope :past, -> { where("start_at <= ?", Time.current) }
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
      max_participants
      attendances_count
      type
      created_at
      updated_at
    ]
  end

  def self.ransackable_associations(_auth_object = nil)
    %w[attendances creator_user route users]
  end

  # Vérifie si l'événement a une limite de participants (0 = illimité)
  def unlimited?
    max_participants.zero?
  end

  # Vérifie si l'événement est plein (compte uniquement les inscriptions actives, excluant "pending")
  # Les inscriptions "pending" verrouillent une place mais ne sont pas comptées dans has_available_spots
  def full?
    return false if unlimited?

    # Compter seulement les inscriptions confirmées (registered, paid, present), pas "pending"
    attendances.where.not(status: [ "canceled", "pending" ]).where(is_volunteer: false).count >= max_participants
  end

  # Retourne le nombre de places restantes (excluant "pending")
  def remaining_spots
    return nil if unlimited?

    confirmed_count = attendances.where.not(status: [ "canceled", "pending" ]).where(is_volunteer: false).count
    [ max_participants - confirmed_count, 0 ].max
  end

  # Vérifie s'il reste des places disponibles (excluant "pending" qui verrouillent une place)
  def has_available_spots?
    return true if unlimited?
    # Compter seulement les inscriptions confirmées (registered, paid, present), pas "pending"
    attendances.where.not(status: [ "canceled", "pending" ]).where(is_volunteer: false).count < max_participants
  end

  # Compte les inscriptions actives (non annulées, incluant pending pour verrouiller les places)
  def active_attendances_count
    attendances.where.not(status: "canceled").count
  end

  # Notifier la prochaine personne en liste d'attente
  def notify_next_waitlist_entry
    WaitlistEntry.notify_next_in_queue(self, count: 1)
  end

  # Appelé après sauvegarde : si max_participants a augmenté, notifier la file d'attente en priorité
  def notify_waitlist_if_capacity_increased
    return if max_participants.zero?
    old_max = max_participants_before_last_save
    return unless old_max && max_participants > old_max
    extra_places = max_participants - old_max
    waitlist_count = waitlist_entries.pending_notification.count
    count = [ extra_places, waitlist_count ].min
    WaitlistEntry.notify_next_in_queue(self, count: count) if count > 0
  end

  # Vérifie si l'événement est passé
  def past?
    start_at <= Time.current
  end

  # Calcule la date de fin de l'événement (start_at + duration_min)
  def end_at
    return nil unless start_at && duration_min
    start_at + duration_min.minutes
  end

  # Vérifie si l'événement est terminé (après sa date de fin)
  def finished?
    return false unless end_at
    end_at <= Time.current
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

  # Cette méthode doit être appelée après qu'un événement soit terminé
  # Retourne le nombre de rollers remis en stock, ou nil si déjà traité
  def return_roller_stock
    return unless is_a?(Event::Initiation) # Seulement pour les initiations

    # Sécurité : éviter de remettre le stock plusieurs fois
    if stock_returned_at.present?
      Rails.logger.info("Stock déjà remis en place pour initiation ##{id} le #{stock_returned_at}")
      return nil
    end

    attendances_to_process = attendances
      .where(needs_equipment: true)
      .where.not(roller_size: nil)
      .where.not(status: "canceled") # Ne pas traiter les annulées (déjà remises en stock)

    count = 0
    attendances_to_process.find_each do |attendance|
      next unless attendance.roller_size.present?

      roller_stock = RollerStock.find_by(size: attendance.roller_size)
      if roller_stock
        roller_stock.increment!(:quantity)
        count += 1
        Rails.logger.info("Stock remis en place pour taille #{attendance.roller_size} (initiation ##{id}, attendance ##{attendance.id})")
      else
        Rails.logger.warn("Taille de roller #{attendance.roller_size} non trouvée dans le stock lors de la remise en stock pour initiation ##{id}")
      end
    end

    # Marquer que le stock a été remis en place (même si count = 0, pour éviter de retraiter)
    if count > 0 || attendances_to_process.exists?
      update_column(:stock_returned_at, Time.current)
      Rails.logger.info("Remise en stock terminée pour initiation ##{id}: #{count} roller(s) remis en stock")
    end

    count
  end

  # Calculer la distance totale si plusieurs boucles
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

  private

  def duration_multiple_of_five
    return if duration_min.blank?

    errors.add(:duration_min, "must be a multiple of 5") unless (duration_min % 5).zero?
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
