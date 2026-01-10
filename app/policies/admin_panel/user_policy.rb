# frozen_string_literal: true

module AdminPanel
  class UserPolicy < BasePolicy
    # Hérite de BasePolicy qui vérifie user.role.level.to_i >= 60
    # Les restrictions utilisent le NUMÉRO du level, pas le code du rôle
    # Level 60 = ADMIN, Level 70 = SUPERADMIN
  end
end
