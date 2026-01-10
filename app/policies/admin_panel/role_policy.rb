# frozen_string_literal: true

module AdminPanel
  class RolePolicy < BasePolicy
    # IMPORTANT : Les rôles sont accessibles UNIQUEMENT pour level >= 70 (SUPERADMIN)
    # Les restrictions utilisent le NUMÉRO du level, pas le code du rôle
    # Level 70 = SUPERADMIN uniquement

    # Surcharge toutes les méthodes pour vérifier level >= 70
    def index?
      superadmin_user?
    end

    def show?
      superadmin_user?
    end

    def create?
      superadmin_user?
    end

    def new?
      superadmin_user?
    end

    def update?
      superadmin_user?
    end

    def edit?
      superadmin_user?
    end

    def destroy?
      superadmin_user?
    end

    class Scope < ApplicationPolicy::Scope
      def resolve
        return scope if superadmin_user?

        if scope.respond_to?(:none)
          scope.none
        else
          []
        end
      end

      private

      def superadmin_user?
        user.present? && user.role&.level.to_i >= 70
      end
    end

    private

    def superadmin_user?
      # IMPORTANT : Utilise le NUMÉRO du level, pas le code du rôle
      # Level 70 = SUPERADMIN uniquement
      user.present? && user.role&.level.to_i >= 70
    end
  end
end
