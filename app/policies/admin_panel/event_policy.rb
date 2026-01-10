# frozen_string_literal: true

module AdminPanel
  class EventPolicy < BasePolicy
    # Permissions pour les événements (randonnées) :
    # IMPORTANT : Utilise le NUMÉRO du level, pas le code du rôle
    # - Toutes les actions : level >= 60 (ADMIN, SUPERADMIN)
    # - Les méthodes index?, show?, create?, update?, destroy? héritent de BasePolicy

    # Actions spéciales pour les événements
    def convert_waitlist?
      admin_user? # level >= 60
    end

    def notify_waitlist?
      admin_user? # level >= 60
    end

    private

    def admin_user?
      # IMPORTANT : Utilise le NUMÉRO du level, pas le code du rôle
      # Level >= 60 permet toutes les actions sur les événements
      user.present? && user.role&.level.to_i >= 60
    end
  end
end
