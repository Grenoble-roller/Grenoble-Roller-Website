# frozen_string_literal: true

module AdminPanel
  class MembershipPolicy < BasePolicy
    # Hérite de BasePolicy qui vérifie user.role.level.to_i >= 60
    # Les restrictions utilisent le NUMÉRO du level, pas le code du rôle
    # Level 60 = ADMIN, Level 70 = SUPERADMIN

    def activate?
      admin_user? # Vérifie user.role.level.to_i >= 60
    end

    def check_payment?
      admin_user? # Vérifie user.role.level.to_i >= 60
    end
  end
end
