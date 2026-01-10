# frozen_string_literal: true

module AdminPanel
  class PartnerPolicy < BasePolicy
    # Permissions pour les partenaires :
    # IMPORTANT : Utilise le NUMÉRO du level, pas le code du rôle
    # - Toutes les actions : level >= 60 (ADMIN, SUPERADMIN)
    # - CRUD complet
    # - Les méthodes index?, show?, create?, update?, destroy? héritent de BasePolicy
  end
end
