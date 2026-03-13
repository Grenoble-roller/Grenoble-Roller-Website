class EventPolicy < ApplicationPolicy
  def index?
    true
  end

  def show?
    # Visible si publié ou annulé, ou si l'utilisateur est modo+, ou si c'est le créateur
    record.published? || record.canceled? || admin? || moderator? || owner?
  end

  def create?
    organizer?
  end

  def new?
    create?
  end

  def update?
    # L'organisateur peut modifier son événement, mais pas le statut (sauf modos+)
    owner? || admin? || moderator?
  end

  def edit?
    update?
  end

  def destroy?
    # Seul un admin peut supprimer un événement
    admin?
  end

  def reject?
    # Seuls les modérateurs et admins peuvent refuser un événement
    admin? || moderator?
  end

  def attend?
    return false unless user.present?
    return false if record.full?

    # Pour les événements normaux (randos) : ouverts à tous, aucune restriction d'adhésion
    # Les initiations ont leur propre politique (Event::InitiationPolicy)
    return true if record.is_a?(Event::Initiation)

    # Pour les événements normaux : ouvert à tous les utilisateurs connectés
    true
  end

  def cancel_attendance?
    user.present?
  end

  # Vérifie si l'utilisateur peut s'inscrire (pas déjà inscrit et événement pas plein)
  def can_attend?
    attend? && !user_has_attendance?
  end

  # Vérifie si l'utilisateur est déjà inscrit
  def user_has_attendance?
    return false unless user.present?

    record.attendances.exists?(user_id: user.id)
  end

  def join_waitlist?
    return false unless user
    return false unless record.full? # Ne peut rejoindre la liste d'attente que si l'événement est complet
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

  def permitted_attributes
    attrs = [
      :title,
      :start_at,
      :duration_min,
      :description,
      :price_cents,
      :currency,
      :location_text,
      :meeting_lat,
      :meeting_lng,
      :route_id,
      :cover_image,
      :max_participants,
      :level,
      :distance_km,
      :loops_count
    ]

    # Seuls les modérateurs+ peuvent modifier le statut
    attrs << :status if admin? || moderator?

    attrs
  end

  class Scope < ApplicationPolicy::Scope
    def resolve
      if admin? || moderator?
        # Admins et modérateurs voient tous les événements
        scope.all
      elsif organizer?
        # Organisateurs voient leurs événements + les événements publiés et annulés
        scope.where(creator_user_id: user.id).or(scope.visible)
      elsif user.present?
        # Utilisateurs connectés voient les événements publiés/annulés + leurs propres événements
        scope.visible.or(scope.where(creator_user_id: user.id))
      else
        # Utilisateurs non connectés voient les événements publiés et annulés
        scope.visible
      end
    end

    private

    def organizer?
      user.present? && user.role&.level.to_i >= 30 # ORGANIZER (30) ou plus
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

  def organizer?
    user.present? && user.role&.level.to_i >= 30 # ORGANIZER (30) ou plus
  end

  def admin?
    user.present? && user.role&.level.to_i >= 60
  end

  def moderator?
    user.present? && user.role&.level.to_i >= 50
  end
end
