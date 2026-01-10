class AttendancesController < ApplicationController
  before_action :authenticate_user!

  def index
    all_attendances = current_user.attendances
                                   .active
                                   .includes(event: [ :route, :creator_user ])

    # Appliquer les filtres
    all_attendances = apply_filters(all_attendances)

    # Séparer événements à venir et passés
    upcoming_scope = all_attendances.select { |a| a.event.start_at > Time.current }
                                    .sort_by { |a| a.event.start_at }

    past_scope = all_attendances.select { |a| a.event.start_at <= Time.current }
                                 .sort_by { |a| a.event.start_at }
                                 .reverse

    # Pagination pour les événements à venir
    @pagy_upcoming, @upcoming_attendances = pagy_array(upcoming_scope, page_param: :page_upcoming, items: 12)

    # Pagination pour les événements passés
    @pagy_past, @past_attendances = pagy_array(past_scope, page_param: :page_past, items: 12)
  end

  private

  # Appliquer les filtres depuis les paramètres
  def apply_filters(attendances)
    # Filtre par date (à venir / passés)
    # Note: Ce filtre est déjà géré par la séparation upcoming/past, mais on peut ajouter d'autres filtres ici

    # Filtre par statut rappel (wants_reminder)
    if params[:reminder].present?
      case params[:reminder]
      when "enabled"
        attendances = attendances.select { |a| a.wants_reminder == true }
      when "disabled"
        attendances = attendances.select { |a| a.wants_reminder == false }
      end
    end

    attendances
  end
end
