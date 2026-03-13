class Attendance < ApplicationRecord
  include Hashid::Rails

  belongs_to :user
  belongs_to :event, counter_cache: true
  belongs_to :payment, optional: true
  belongs_to :child_membership, class_name: "Membership", optional: true

  enum :status, {
    pending: "pending",      # En attente de confirmation (liste d'attente)
    registered: "registered",
    paid: "paid",
    canceled: "canceled",
    present: "present",
    no_show: "no_show"
  }, validate: true

  validates :status, presence: true
  # Permettre plusieurs attendances pour le même user_id et event_id si :
  # - child_membership_id est différent (parent + enfants)
  # - OU is_volunteer est différent (bénévole + participant)
  # Note: Un utilisateur peut être inscrit comme bénévole ET participant (deux inscriptions distinctes)
  validates :user_id, uniqueness: {
    scope: [ :event_id, :child_membership_id, :is_volunteer ],
    message: "a déjà une inscription pour cet événement avec ce statut",
    conditions: -> { where.not(status: "canceled") } # Ne pas compter les inscriptions annulées
  }
  validates :free_trial_used, inclusion: { in: [ true, false ] }
  validates :roller_size, presence: true, if: :needs_equipment?
  validates :roller_size, inclusion: { in: RollerStock::SIZES }, if: :needs_equipment?
  validate :event_has_available_spots, on: :create
  validate :can_use_free_trial, on: :create
  validate :can_register_to_initiation, on: :create
  validate :can_register_to_event, on: :create
  validate :child_membership_belongs_to_user
  validate :no_duplicate_registration, on: :create

  after_create :decrement_roller_stock, if: :should_decrement_stock? # Décrémenter le stock si matériel demandé
  after_update :handle_stock_on_equipment_change # Gérer le stock si besoin matériel change
  after_update :handle_stock_on_status_change, if: :saved_change_to_status? # Gérer le stock si statut change
  after_destroy :increment_roller_stock, if: :should_increment_stock_on_destroy? # Incrémenter le stock si matériel était demandé
  after_destroy :notify_waitlist_if_needed # Notifier la liste d'attente si une place se libère
  after_update :notify_waitlist_on_cancellation, if: :saved_change_to_status? # Notifier si le statut passe à "canceled"

  scope :active, -> { where.not(status: "canceled") }
  scope :canceled, -> { where(status: "canceled") }
  scope :volunteers, -> { where(is_volunteer: true) }
  scope :participants, -> { where(is_volunteer: false) }
  scope :for_parent, -> { where(child_membership_id: nil) }
  scope :for_children, -> { where.not(child_membership_id: nil) }

  # Vérifier si c'est une inscription pour un enfant
  def for_child?
    child_membership_id.present?
  end

  # Vérifier si c'est une inscription pour le parent
  def for_parent?
    child_membership_id.nil?
  end

  # Nom de la personne inscrite (parent ou enfant)
  def participant_name
    if for_child?
      child_membership&.child_full_name || "Enfant"
    else
      # Construire le nom complet à partir de first_name et last_name
      if user
        name_parts = [ user.first_name, user.last_name ].compact.reject(&:blank?)
        name_parts.any? ? name_parts.join(" ") : user.email
      else
        "Parent"
      end
    end
  end

  def self.ransackable_attributes(_auth_object = nil)
    %w[id user_id event_id status payment_id stripe_customer_id wants_reminder free_trial_used is_volunteer equipment_note needs_equipment roller_size created_at updated_at]
  end

  def self.ransackable_associations(_auth_object = nil)
    %w[user event payment]
  end

  private

  def event_has_available_spots
    return unless event
    return if event.unlimited?
    # Ne pas vérifier la limite pour les inscriptions annulées (elles ne comptent pas)
    return if status == "canceled"
    # Les inscriptions "pending" verrouillent une place mais ne sont pas comptées dans has_available_spots
    # Elles sont créées lors de la notification de la liste d'attente
    return if status == "pending"
    # Bénévoles ne comptent pas dans la limite
    return if is_volunteer

    # Pour les initiations avec limitation des non-adhérents
    # ⚠️ v4.0 : Les essais gratuits sont NOMINATIFS - chaque personne doit avoir sa propre adhésion
    if event.is_a?(Event::Initiation) && event.allow_non_member_discovery?
      is_member = if child_membership_id.present?
        # Pour un enfant : vérifier UNIQUEMENT l'adhésion de cet enfant
        child_membership&.active?
      else
        # Pour le parent : vérifier UNIQUEMENT l'adhésion parent (pas celle des enfants)
        user.memberships.active_now.where(is_child_membership: false).exists?
      end

      if is_member
        # Vérifier places pour adhérents
        if event.full_for_members?
          errors.add(:event, "Les places pour adhérents sont complètes (#{event.max_participants - (event.non_member_discovery_slots || 0)} places maximum)")
        end
      else
        # Vérifier places pour non-adhérents
        if event.full_for_non_members?
          errors.add(:event, "Les places pour non-adhérents sont complètes (#{event.non_member_discovery_slots || 0} places maximum)")
        end
      end
    else
      # Comportement classique : vérifier le total
      # Exclure "pending" du comptage car elles verrouillent une place mais ne sont pas encore confirmées
      active_attendances_count = event.attendances.where.not(status: [ "canceled", "pending" ]).where(is_volunteer: false).count

      # Si on crée une nouvelle inscription, vérifier qu'il reste de la place
      # (ne pas compter cette inscription si elle n'est pas encore sauvegardée)
      if new_record?
        if active_attendances_count >= event.max_participants
          errors.add(:event, "L'événement est complet (#{event.max_participants} participants maximum)")
        end
      end
    end
  end

  def can_use_free_trial
    return unless free_trial_used
    return unless user

    # Distinguer parent vs enfant : vérifier essai gratuit par child_membership_id si présent
    # IMPORTANT : Exclure les attendances annulées (si annulation, l'essai gratuit redevient disponible)
    if child_membership_id.present?
      # Pour un enfant : vérifier si cet enfant spécifique a déjà utilisé son essai gratuit (attendance active uniquement)
      if user.attendances.active.where(free_trial_used: true, child_membership_id: child_membership_id).where.not(id: id).exists?
        errors.add(:free_trial_used, "Cet enfant a déjà utilisé son essai gratuit")
      end
    else
      # Pour le parent : vérifier si le parent a déjà utilisé son essai gratuit (sans child_membership_id, attendance active uniquement)
      if user.attendances.active.where(free_trial_used: true, child_membership_id: nil).where.not(id: id).exists?
        errors.add(:free_trial_used, "Vous avez déjà utilisé votre essai gratuit")
      end
    end
  end

  def can_register_to_initiation
    return unless event.is_a?(Event::Initiation)
    return if is_volunteer # Bénévoles bypassent les validations

    # Vérifier places disponibles selon le type (adhérent/non-adhérent)
    # ⚠️ v4.0 : Les essais gratuits sont NOMINATIFS - chaque personne doit avoir sa propre adhésion
    # Un parent ne peut PAS utiliser l'adhésion de son enfant
    is_member = if child_membership_id.present?
      # Pour un enfant : vérifier UNIQUEMENT l'adhésion de cet enfant
      child_membership&.active?
    else
      # Pour le parent : vérifier UNIQUEMENT l'adhésion parent (pas celle des enfants)
      user.memberships.active_now.where(is_child_membership: false).exists?
    end

    if event.allow_non_member_discovery?
      if is_member
        if event.full_for_members?
          errors.add(:event, "Les places pour adhérents sont complètes")
          return
        end
      else
        if event.full_for_non_members?
          errors.add(:event, "Les places pour non-adhérents sont complètes")
          return
        end
      end
    else
      # Comportement classique
      if event.full?
        errors.add(:event, "Cette séance est complète")
        return
      end
    end

    # Vérifier adhésion ou essai gratuit
    if free_trial_used
      # Essai utilisé → vérifier qu'il n'a pas déjà été utilisé ailleurs (distinguer parent vs enfant)
      # IMPORTANT : Exclure les attendances annulées (si annulation, l'essai gratuit redevient disponible)
      if child_membership_id.present?
        # Pour un enfant : vérifier si cet enfant spécifique a déjà utilisé son essai gratuit (attendance active uniquement)
        if user.attendances.active.where(free_trial_used: true, child_membership_id: child_membership_id).where.not(id: id).exists?
          errors.add(:free_trial_used, "Cet enfant a déjà utilisé son essai gratuit")
        end
      else
        # Pour le parent : vérifier si le parent a déjà utilisé son essai gratuit (sans child_membership_id, attendance active uniquement)
        if user.attendances.active.where(free_trial_used: true, child_membership_id: nil).where.not(id: id).exists?
          errors.add(:free_trial_used, "Vous avez déjà utilisé votre essai gratuit")
        end
      end
    else
      # Si c'est pour un enfant, vérifier que l'adhésion enfant est active, trial ou pending
      # pending est autorisé car l'enfant peut utiliser l'essai gratuit même si l'adhésion n'est pas encore payée
      if for_child?
        unless child_membership&.active? || child_membership&.trial? || child_membership&.pending?
          errors.add(:child_membership_id, "L'adhésion de cet enfant n'est pas active")
        end

        # RÈGLE MÉTIER CRITIQUE v4.0 : Les essais gratuits sont NOMINATIFS
        # Chaque enfant (pending ou trial) DOIT utiliser son propre essai gratuit, même si le parent est adhérent
        if child_membership&.trial? || child_membership&.pending?
          # Essai gratuit OBLIGATOIRE pour cet enfant (nominatif)
          unless free_trial_used
            errors.add(:free_trial_used, "L'essai gratuit est obligatoire pour cet enfant. Veuillez cocher la case correspondante.")
          end

          # Vérifier que cet enfant n'a pas déjà utilisé son essai gratuit (attendance active uniquement)
          # IMPORTANT : Exclure les attendances annulées (si annulation, l'essai gratuit redevient disponible)
          if user.attendances.active.where(free_trial_used: true, child_membership_id: child_membership_id).where.not(id: id).exists?
            errors.add(:free_trial_used, "Cet enfant a déjà utilisé son essai gratuit. Une adhésion est maintenant requise.")
          end
        end
      elsif !event.allow_non_member_discovery?
        # Si l'option n'est pas activée, vérifier adhésion active ou essai gratuit
        # ⚠️ v4.0 : Les essais gratuits sont NOMINATIFS - chaque personne doit avoir sa propre adhésion
        has_active_membership = if child_membership_id.present?
          # Pour un enfant : vérifier UNIQUEMENT l'adhésion de cet enfant
          child_membership&.active?
        else
          # Pour le parent : vérifier UNIQUEMENT l'adhésion parent (pas celle des enfants)
          user.memberships.active_now.where(is_child_membership: false).exists?
        end

        unless has_active_membership || free_trial_used
          errors.add(:base, "Adhésion requise. Utilisez votre essai gratuit ou adhérez à l'association.")
        end
      else
        # Si l'option est activée et que l'utilisateur n'est pas adhérent,
        # SÉCURITÉ : Vérifier que l'essai gratuit n'a pas déjà été utilisé
        # Si l'essai gratuit a déjà été utilisé, l'utilisateur ne peut plus s'inscrire sans adhésion
        # même si allow_non_member_discovery est activé
        unless is_member
          if child_membership_id.present?
            # Pour un enfant : vérifier si cet enfant a déjà utilisé son essai gratuit
            if user.attendances.active.where(free_trial_used: true, child_membership_id: child_membership_id).where.not(id: id).exists?
              errors.add(:base, "Cet enfant a déjà utilisé son essai gratuit. Une adhésion est maintenant requise.")
            end
          else
            # Pour le parent : vérifier si le parent a déjà utilisé son essai gratuit
            if user.attendances.active.where(free_trial_used: true, child_membership_id: nil).where.not(id: id).exists?
              errors.add(:base, "Vous avez déjà utilisé votre essai gratuit. Une adhésion est maintenant requise pour continuer.")
            end
          end
        end
      end
    end
  end

  def can_register_to_event
    return if event.is_a?(Event::Initiation) # Les initiations ont leur propre validation
    return if is_volunteer # Bénévoles bypassent les validations

    # Pour les événements normaux (randos) : ouverts à tous, aucune restriction d'adhésion
    # Vérifier seulement que l'adhésion enfant appartient à l'utilisateur si un enfant est inscrit
    if for_child?
      unless child_membership && user.memberships.exists?(id: child_membership_id, is_child_membership: true)
        errors.add(:child_membership_id, "Cette adhésion enfant ne vous appartient pas")
      end
    end
    # Pour le parent : aucune restriction, ouvert à tous
  end

  def child_membership_belongs_to_user
    return unless child_membership_id.present?
    return unless user

    unless user.memberships.exists?(id: child_membership_id)
      errors.add(:child_membership_id, "Cette adhésion enfant ne vous appartient pas")
    end
  end

  # Validation pour éviter les inscriptions en double (race condition)
  def no_duplicate_registration
    return unless user && event

    # Vérifier s'il existe déjà une inscription identique
    existing = event.attendances.where(
      user: user,
      child_membership_id: child_membership_id,
      is_volunteer: is_volunteer || false
    ).where.not(status: "canceled")

    # Exclure cette instance si elle existe déjà en base
    existing = existing.where.not(id: id) if persisted?

    if existing.exists?
      if for_child?
        child_name = child_membership&.child_full_name || "cet enfant"
        errors.add(:base, "#{child_name} est déjà inscrit(e) à cette séance.")
      elsif is_volunteer
        errors.add(:base, "Vous êtes déjà inscrit(e) en tant que bénévole pour cette séance.")
      else
        errors.add(:base, "Vous êtes déjà inscrit(e) à cette séance.")
      end
    end
  end

  # Callbacks pour la liste d'attente
  def notify_waitlist_if_needed
    # Quand une inscription est supprimée, vérifier si on doit notifier la liste d'attente
    # Ne pas notifier si c'est une inscription "pending" (c'est une place verrouillée par la liste d'attente)
    # Note: dans after_destroy, l'objet existe encore en mémoire avec ses attributs
    return if status == "pending"

    # Ne pas notifier si c'est un bénévole (ils ne comptent pas dans les places)
    return if is_volunteer

    # Recharger l'événement pour avoir le bon comptage après la destruction
    event.reload

    # Vérifier si l'événement a maintenant des places disponibles
    if event.has_available_spots?
      # Notifier la première personne en liste d'attente
      WaitlistEntry.notify_next_in_queue(event, count: 1)
      Rails.logger.info("Attendance destroyed, notifying waitlist for event #{event.id}")
    end
  end

  def notify_waitlist_on_cancellation
    # Si l'inscription passe à "canceled", notifier la liste d'attente
    if status == "canceled" && status_before_last_save != "canceled"
      # Vérifier si l'événement a maintenant des places disponibles
      if event.has_available_spots?
        # Notifier la première personne en liste d'attente
        WaitlistEntry.notify_next_in_queue(event, count: 1)
      end
    end
  end

  # Gestion du stock de rollers
  def should_decrement_stock?
    needs_equipment? && roller_size.present? && status != "canceled"
  end

  def should_increment_stock_on_destroy?
    needs_equipment? && roller_size.present?
  end

  def decrement_roller_stock
    return unless needs_equipment? && roller_size.present?

    roller_stock = RollerStock.find_by(size: roller_size)
    if roller_stock && roller_stock.quantity > 0
      roller_stock.decrement!(:quantity)
      Rails.logger.info("Stock décrémenté pour taille #{roller_size}: #{roller_stock.quantity} restants")
    elsif roller_stock
      Rails.logger.warn("Impossible de décrémenter le stock : taille #{roller_size} déjà à 0")
    else
      Rails.logger.warn("Taille de roller #{roller_size} non trouvée dans le stock")
    end
  end

  def increment_roller_stock
    return unless needs_equipment? && roller_size.present?

    roller_stock = RollerStock.find_by(size: roller_size)
    if roller_stock
      roller_stock.increment!(:quantity)
      Rails.logger.info("Stock incrémenté pour taille #{roller_size}: #{roller_stock.quantity} disponibles")
    else
      Rails.logger.warn("Taille de roller #{roller_size} non trouvée dans le stock lors de l'incrémentation")
    end
  end

  def handle_stock_on_equipment_change
    # Si le besoin de matériel change
    if saved_change_to_needs_equipment? || saved_change_to_roller_size?
      old_needs = saved_change_to_needs_equipment? ? saved_change_to_needs_equipment[0] : needs_equipment?
      old_size = saved_change_to_roller_size? ? saved_change_to_roller_size[0] : roller_size
      new_needs = needs_equipment?
      new_size = roller_size

      # Si on passait de "besoin matériel" à "pas besoin", incrémenter le stock de l'ancienne taille
      if old_needs && old_size.present? && !new_needs && status != "canceled"
        old_stock = RollerStock.find_by(size: old_size)
        old_stock&.increment!(:quantity)
        Rails.logger.info("Stock incrémenté (changement besoin matériel) pour taille #{old_size}")
      end

      # Si on passe de "pas besoin" à "besoin matériel", décrémenter le stock de la nouvelle taille
      if !old_needs && new_needs && new_size.present? && status != "canceled"
        new_stock = RollerStock.find_by(size: new_size)
        if new_stock && new_stock.quantity > 0
          new_stock.decrement!(:quantity)
          Rails.logger.info("Stock décrémenté (changement besoin matériel) pour taille #{new_size}")
        end
      end

      # Si la taille change mais qu'on a toujours besoin de matériel
      if old_needs && new_needs && old_size != new_size && old_size.present? && new_size.present? && status != "canceled"
        old_stock = RollerStock.find_by(size: old_size)
        old_stock&.increment!(:quantity)
        new_stock = RollerStock.find_by(size: new_size)
        if new_stock && new_stock.quantity > 0
          new_stock.decrement!(:quantity)
          Rails.logger.info("Stock mis à jour : taille #{old_size} incrémentée, taille #{new_size} décrémentée")
        end
      end
    end
  end

  def handle_stock_on_status_change
    return unless needs_equipment? && roller_size.present?

    old_status = status_before_last_save
    new_status = status

    # Si on passe de "non canceled" à "canceled", incrémenter le stock
    if old_status != "canceled" && new_status == "canceled"
      increment_roller_stock
    end

    # Si on passe de "canceled" à "non canceled", décrémenter le stock
    if old_status == "canceled" && new_status != "canceled"
      decrement_roller_stock
    end
  end
end
