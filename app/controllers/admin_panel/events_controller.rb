# frozen_string_literal: true

module AdminPanel
  class EventsController < BaseController
    before_action :set_event, only: %i[show destroy convert_waitlist notify_waitlist]
    before_action :authorize_event

    # GET /admin-panel/events
    def index
      authorize ::Event, policy_class: AdminPanel::EventPolicy

      # Exclure les initiations (STI)
      base_scope = ::Event.not_initiations
        .includes(:creator_user, :route, :attendances, :waitlist_entries)

      # Filtres par statut
      base_scope = base_scope.where(status: params[:status]) if params[:status].present?
      base_scope = base_scope.where(status: "published") if params[:scope] == "published"
      base_scope = base_scope.pending_validation if params[:scope] == "pending_validation"
      base_scope = base_scope.rejected if params[:scope] == "rejected"
      base_scope = base_scope.where(status: "canceled") if params[:scope] == "canceled"

      # Recherche Ransack
      @q = base_scope.ransack(params[:q])
      base_scope = @q.result(distinct: true)

      # Séparer événements à venir et passés
      now = Time.current

      # Si filtre "upcoming", ne garder que les à venir
      if params[:scope] == "upcoming"
        @upcoming_events = base_scope
          .where("start_at > ?", now)
          .order(start_at: :asc)
        @past_events = []
      else
        # Sinon, afficher les deux sections
        @upcoming_events = base_scope
          .where("start_at > ?", now)
          .order(start_at: :asc)

        @past_events = base_scope
          .where("start_at <= ?", now)
          .order(start_at: :desc)
      end

      # Pour la pagination, on combine les deux listes
      @events = @upcoming_events + @past_events
    end

    # GET /admin-panel/events/:id
    def show
      @attendances = @event.attendances
        .includes(:user, :child_membership, :payment)
        .order(:created_at)

      @waitlist_entries = @event.waitlist_entries
        .includes(:user, :child_membership)
        .active
        .ordered_by_position
    end

    # DELETE /admin-panel/events/:id
    def destroy
      if @event.destroy
        flash[:notice] = "Événement supprimé avec succès"
        redirect_to admin_panel_events_path
      else
        flash[:alert] = "Impossible de supprimer l'événement : #{@event.errors.full_messages.join(', ')}"
        redirect_to admin_panel_event_path(@event)
      end
    end

    # POST /admin-panel/events/:id/convert_waitlist
    def convert_waitlist
      waitlist_entry = @event.waitlist_entries.find_by_hashid(params[:waitlist_entry_id])

      unless waitlist_entry&.notified?
        redirect_to admin_panel_event_path(@event),
                    alert: "Entrée de liste d'attente non notifiée"
        return
      end

      pending_attendance = @event.attendances.find_by(
        user: waitlist_entry.user,
        child_membership_id: waitlist_entry.child_membership_id,
        status: "pending"
      )

      if pending_attendance&.update(status: "registered")
        waitlist_entry.update!(status: "converted")
        WaitlistEntry.notify_next_in_queue(@event) if @event.has_available_spots?
        redirect_to admin_panel_event_path(@event),
                    notice: "Entrée convertie en inscription"
      else
        redirect_to admin_panel_event_path(@event),
                    alert: "Impossible de convertir l'entrée"
      end
    end

    # POST /admin-panel/events/:id/notify_waitlist
    def notify_waitlist
      waitlist_entry = @event.waitlist_entries.find_by_hashid(params[:waitlist_entry_id])

      unless waitlist_entry&.pending?
        redirect_to admin_panel_event_path(@event),
                    alert: "Entrée non en attente"
        return
      end

      if waitlist_entry.notify!
        redirect_to admin_panel_event_path(@event),
                    notice: "Personne notifiée avec succès"
      else
        redirect_to admin_panel_event_path(@event),
                    alert: "Impossible de notifier"
      end
    end

    private

    def set_event
      @event = ::Event.not_initiations.find(params[:id])
    end

    def authorize_event
      authorize ::Event, policy_class: AdminPanel::EventPolicy
    end
  end
end
