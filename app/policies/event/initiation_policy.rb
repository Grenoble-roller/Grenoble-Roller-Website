class Event::InitiationPolicy < ApplicationPolicy
  attr_reader :child_membership_id_for_policy, :is_volunteer_for_policy

  def initialize(user, record, *args)
    super(user, record)
    # Pundit.policy peut recevoir un 3e argument (options hash)
    options = args.first.is_a?(Hash) ? args.first : {}
    @child_membership_id_for_policy = options[:child_membership_id]
    @is_volunteer_for_policy = options[:is_volunteer] || false
  end

  def index?
    true # Tous peuvent voir la liste
  end

  def show?
    true # Tous peuvent voir une initiation
  end

  def attend?
    return false unless user
    return false if record.past?

    # Utiliser les paramètres passés via l'initializer
    child_membership_id = child_membership_id_for_policy
    is_volunteer = is_volunteer_for_policy

    # Pour les bénévoles, vérifier l'autorisation AVANT de vérifier si l'initiation est pleine
    # Les bénévoles peuvent toujours s'inscrire même si l'initiation est pleine
    if is_volunteer && child_membership_id.nil?
      return false unless user.can_be_volunteer?
      # Les bénévoles peuvent toujours s'inscrire (pas besoin d'adhésion ni de vérifier la capacité)
      return true
    end

    # Pour les participants normaux, vérifier si l'initiation est pleine
    return false if record.full?

    # Vérifier que child_membership_id appartient bien à l'utilisateur si fourni
    if child_membership_id.present?
      unless user.memberships.exists?(id: child_membership_id, is_child_membership: true)
        return false
      end
      # Vérifier que l'adhésion enfant est active, trial ou pending
      # pending est autorisé car l'enfant peut utiliser l'essai gratuit même si l'adhésion n'est pas encore payée
      child_membership = user.memberships.find_by(id: child_membership_id)
      return false unless child_membership&.active? || child_membership&.trial? || child_membership&.pending?
    end

    # Vérifier si l'utilisateur est déjà inscrit avec le même statut
    existing_attendance = user.attendances.where(
      event: record,
      child_membership_id: child_membership_id,
      is_volunteer: is_volunteer || false
    ).where.not(status: "canceled")

    if existing_attendance.exists?
      # Si c'est pour un enfant, autoriser si d'autres enfants peuvent être inscrits
      if child_membership_id.present?
        registered_child_ids = user.attendances.where(event: record).where.not(child_membership_id: nil, status: "canceled").pluck(:child_membership_id).compact
        # Inclure les adhésions active, trial et pending pour les initiations
        available_children = user.memberships.where(is_child_membership: true)
          .where(status: [ Membership.statuses[:active], Membership.statuses[:trial], Membership.statuses[:pending] ])
          .where.not(id: registered_child_ids)
        return available_children.exists?
      end
      # Si c'est pour le parent, ne pas autoriser si déjà inscrit avec le même statut
      return false
    end

    # Vérifier si l'utilisateur est adhérent
    # ⚠️ v4.0 : Les essais gratuits sont NOMINATIFS - chaque personne doit avoir sa propre adhésion
    is_member = if child_membership_id.present?
      # Pour un enfant : vérifier l'adhésion enfant (active, trial ou pending, déjà vérifiée plus haut)
      child_membership&.active? || child_membership&.trial? || child_membership&.pending?
    else
      # Pour le parent : vérifier UNIQUEMENT l'adhésion parent (pas celle des enfants)
      user.memberships.active_now.where(is_child_membership: false).exists?
    end

    # Si l'option de limitation des non-adhérents est activée
    if record.allow_non_member_discovery?
      if is_member
        # Adhérent : vérifier qu'il reste des places pour adhérents
        return false if record.full_for_members?
        return true
      else
        # Non-adhérent : vérifier qu'il reste des places pour non-adhérents
        return false if record.full_for_non_members?
        # Autoriser l'inscription dans les places découverte (pas besoin d'essai gratuit)
        return true
      end
    end

    # Si l'option n'est pas activée : comportement classique
    # Vérifier adhésion ou essai gratuit disponible
    # Distinguer parent vs enfant pour l'essai gratuit
    if is_member
      true
    elsif child_membership_id.present?
      # Pour un enfant : vérifier si cet enfant spécifique a déjà utilisé son essai gratuit
      !user.attendances.active.where(free_trial_used: true, child_membership_id: child_membership_id).exists?
    else
      # Pour le parent : vérifier si le parent a déjà utilisé son essai gratuit (sans child_membership_id)
      !user.attendances.active.where(free_trial_used: true, child_membership_id: nil).exists?
    end
  end

  def cancel_attendance?
    return false unless user
    user.attendances.exists?(event: record)
  end

  def can_attend?
    attend?
  end

  def join_waitlist?
    return false unless user
    # Pour rejoindre la liste d'attente, l'événement doit être complet
    # Mais on ne vérifie pas les conditions d'adhésion/essai gratuit ici,
    # car elles seront vérifiées lors de l'inscription en liste d'attente
    # et lors de la conversion en inscription
    return false unless record.full?
    true
  end

  def leave_waitlist?
    return false unless user
    record.waitlist_entries.exists?(user: user, status: [ "pending", "notified" ])
  end

  def convert_waitlist_to_attendance?
    return false unless user
    record.waitlist_entries.exists?(user: user, status: "notified")
  end

  def refuse_waitlist?
    return false unless user
    record.waitlist_entries.exists?(user: user, status: "notified")
  end

  def manage?
    user&.role&.level.to_i >= 40 # INITIATION (40) ou plus - forcément membre Grenoble Roller
  end

  def create?
    # Les organisateurs (level 40) et plus peuvent créer des initiations
    user&.role&.level.to_i >= 40 # ORGANIZER (40) ou plus
  end

  def new?
    create?
  end

  def update?
    # L'instructeur peut modifier son initiation, mais pas le statut (sauf modos+)
    owner? || admin? || moderator?
  end

  def edit?
    update?
  end

  def destroy?
    admin? || owner?
  end

  def permitted_attributes
    attrs = [
      :title,
      :start_at,
      :duration_min,
      :description,
      :location_text,
      :meeting_lat,
      :meeting_lng,
      :max_participants,
      :level,
      :distance_km,
      :cover_image,
      :allow_non_member_discovery,
      :non_member_discovery_slots
    ]

    # Seuls les modérateurs+ peuvent modifier le statut
    attrs << :status if admin? || moderator?

    attrs
  end

  class Scope < Scope
    def resolve
      if admin? || moderator?
        scope.all
      elsif instructor?
        # Instructeurs voient leurs initiations + les initiations publiées
        scope.where(creator_user_id: user.id).or(scope.published)
      elsif user.present?
        # Utilisateurs connectés voient les initiations publiées + leurs propres initiations
        scope.published.or(scope.where(creator_user_id: user.id))
      else
        # Utilisateurs non connectés voient les initiations publiées
        scope.published
      end
    end

    private

    def instructor?
      user.present? && user.role&.level.to_i >= 40 # INITIATION (40) ou plus - forcément membre Grenoble Roller
    end

    def admin?
      user.present? && user.role&.level.to_i >= 60
    end

    def moderator?
      user.present? && user.role&.level.to_i >= 50
    end
  end

  private

  def owner?
    user.present? && record.creator_user_id == user.id
  end

  def admin?
    user.present? && user.role&.level.to_i >= 60
  end

  def moderator?
    user.present? && user.role&.level.to_i >= 50
  end
end
