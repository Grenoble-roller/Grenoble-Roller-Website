# frozen_string_literal: true

module AdminPanel
  module Event
    class InitiationPolicy < AdminPanel::BasePolicy
      # Permissions par level uniquement (les noms de grades ne sont pas utilisés) :
      # - Lecture (index?, show?) : level >= 30
      # - Écriture (create?, update?, destroy?) : level >= 60
      # - return_material? : level >= 40
      # - Actions spéciales (presences, waitlist, etc.) : level >= 60

      def index?
        can_view_initiations?
      end

      def show?
        can_view_initiations?
      end

      def create?
        admin_user?
      end

      def update?
        admin_user?
      end

      def destroy?
        admin_user?
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
        can_return_material?
      end

      private

      def can_view_initiations?
        user.present? && user.role&.level.to_i >= 30
      end

      def can_return_material?
        user.present? && user.role&.level.to_i >= 40
      end

      def admin_user?
        user.present? && user.role&.level.to_i >= 60
      end
    end
  end
end
