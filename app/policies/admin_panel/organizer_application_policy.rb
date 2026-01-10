# frozen_string_literal: true

module AdminPanel
  class OrganizerApplicationPolicy < BasePolicy
    # Permissions pour les candidatures organisateur :
    # IMPORTANT : Utilise le NUMÉRO du level, pas le code du rôle
    # - Toutes les actions : level >= 60 (ADMIN, SUPERADMIN)
    # - Les méthodes index?, show?, create?, update?, destroy? héritent de BasePolicy

    # Actions spéciales
    def approve?
      admin_user? # level >= 60
    end

    def reject?
      admin_user? # level >= 60
    end

    private

    def admin_user?
      # IMPORTANT : Utilise le NUMÉRO du level, pas le code du rôle
      # Level >= 60 permet toutes les actions sur les candidatures
      user.present? && user.role&.level.to_i >= 60
    end
  end
end
