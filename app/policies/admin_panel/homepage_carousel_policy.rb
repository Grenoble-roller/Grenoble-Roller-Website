# frozen_string_literal: true

module AdminPanel
  class HomepageCarouselPolicy < BasePolicy
    # Pour homepage content, level >= 40 (ORGANIZER+) pour autonomie bénévoles
    def index?
      organizer_user?
    end

    def show?
      organizer_user?
    end

    def create?
      organizer_user?
    end

    def new?
      create?
    end

    def update?
      organizer_user?
    end

    def edit?
      update?
    end

    def destroy?
      organizer_user?
    end

    def publish?
      organizer_user?
    end

    def unpublish?
      organizer_user?
    end

    def move_up?
      organizer_user?
    end

    def move_down?
      organizer_user?
    end

    def reorder?
      organizer_user?
    end

    class Scope < ApplicationPolicy::Scope
      def resolve
        return scope if organizer_user?

        if scope.respond_to?(:none)
          scope.none
        else
          []
        end
      end

      private

      def organizer_user?
        # Level >= 40 (ORGANIZER+)
        user.present? && user.role&.level.to_i >= 40
      end
    end

    private

    def organizer_user?
      # Level >= 40 (ORGANIZER+) pour homepage content
      user.present? && user.role&.level.to_i >= 40
    end
  end
end
