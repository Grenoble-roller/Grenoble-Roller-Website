# frozen_string_literal: true

module AdminPanel
  class RollerStockPolicy < BasePolicy
    # Les méthodes index?, show?, create?, update?, destroy? héritent de BasePolicy
    # qui vérifie admin_user? (ADMIN ou SUPERADMIN)

    # Pas de méthodes supplémentaires nécessaires pour l'instant
  end
end
