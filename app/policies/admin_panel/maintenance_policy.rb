# frozen_string_literal: true

module AdminPanel
  # Policy pour le mode maintenance
  # MaintenanceMode n'est pas un modèle ActiveRecord, donc on utilise une classe wrapper
  class MaintenancePolicy < BasePolicy
    # IMPORTANT : Utilise le NUMÉRO du level, pas le code du rôle
    # Level >= 60 permet d'activer/désactiver le mode maintenance
    def toggle?
      admin_user? # Vérifie user.role.level.to_i >= 60
    end
  end
end
