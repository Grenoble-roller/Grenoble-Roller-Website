# frozen_string_literal: true

module AdminPanel
  module Event
    class InitiationPolicy < AdminPanel::BasePolicy
      # Permissions pour les initiations :
      # IMPORTANT : Utilise le NUMÉRO du level, pas le code du rôle
      # - Lecture (index?, show?) : level >= 40
      # - Écriture (create?, update?, destroy?) : level >= 40
      # - Actions spéciales (presences, waitlist, etc.) : level >= 60

      def index?
        can_view_initiations?
      end

      def show?
        can_view_initiations?
      end

      def create?
        can_view_initiations? # level >= 40 (ORGANIZER, MODERATOR, ADMIN, SUPERADMIN)
      end

      def update?
        can_view_initiations? # level >= 40 (ORGANIZER, MODERATOR, ADMIN, SUPERADMIN)
      end

      def destroy?
        can_view_initiations? # level >= 40 (ORGANIZER, MODERATOR, ADMIN, SUPERADMIN)
      end

      def presences?
        admin_user? # level >= 60
      end

      def update_presences?
        admin_user? # level >= 60
      end

      def convert_waitlist?
        admin_user? # level >= 60
      end

      def notify_waitlist?
        admin_user? # level >= 60
      end

      def toggle_volunteer?
        admin_user? # level >= 60
      end

      def return_material?
        can_view_initiations? # level >= 40 (INITIATION, ORGANIZER, MODERATOR, ADMIN, SUPERADMIN)
      end

      private

      def can_view_initiations?
        # IMPORTANT : Utilise le NUMÉRO du level, pas le code du rôle
        # Level >= 40 permet la lecture des initiations
        user.present? && user.role&.level.to_i >= 40
      end

      def admin_user?
        # IMPORTANT : Utilise le NUMÉRO du level, pas le code du rôle
        # Level >= 60 permet l'écriture et les actions spéciales
        user.present? && user.role&.level.to_i >= 60
      end
    end
  end
end
