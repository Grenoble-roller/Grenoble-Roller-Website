# frozen_string_literal: true

module AdminPanel
  class ContactMessagePolicy < BasePolicy
    # Permissions pour les messages de contact :
    # IMPORTANT : Utilise le NUMÉRO du level, pas le code du rôle
    # - Toutes les actions : level >= 60 (ADMIN, SUPERADMIN)
    # - Lecture seule (pas de création/édition via AdminPanel)
    # - Les méthodes index?, show?, destroy? héritent de BasePolicy
  end
end
