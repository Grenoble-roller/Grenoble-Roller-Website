# frozen_string_literal: true

module AdminPanel
  class PaymentPolicy < BasePolicy
    # Permissions pour les paiements :
    # IMPORTANT : Utilise le NUMÉRO du level, pas le code du rôle
    # - index?, show? : level >= 60 (ADMIN, SUPERADMIN)
    # - destroy? : level >= 70 (SUPERADMIN uniquement) - Action critique

    def destroy?
      # IMPORTANT : Utilise le NUMÉRO du level, pas le code du rôle
      # Level 70 = SUPERADMIN uniquement pour la suppression
      user.present? && user.role&.level.to_i >= 70
    end
  end
end
