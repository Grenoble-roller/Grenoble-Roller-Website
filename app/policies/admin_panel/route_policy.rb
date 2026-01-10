# frozen_string_literal: true

module AdminPanel
  class RoutePolicy < BasePolicy
    # Permissions pour les routes (parcours) :
    # IMPORTANT : Utilise le NUMÉRO du level, pas le code du rôle
    # - Toutes les actions : level >= 60 (ADMIN, SUPERADMIN)
    # - Les méthodes index?, show?, create?, update?, destroy? héritent de BasePolicy
  end
end
