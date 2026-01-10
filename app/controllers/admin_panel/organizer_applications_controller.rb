# frozen_string_literal: true

module AdminPanel
  class OrganizerApplicationsController < BaseController
    before_action :set_organizer_application, only: %i[show approve reject destroy]
    before_action :authorize_organizer_application

    # GET /admin-panel/organizer_applications
    def index
      authorize ::OrganizerApplication, policy_class: AdminPanel::OrganizerApplicationPolicy

      base_scope = ::OrganizerApplication.includes(:user, :reviewed_by)

      # Filtres par statut
      base_scope = base_scope.where(status: params[:status]) if params[:status].present?

      # Scopes
      base_scope = base_scope.where(status: "pending") if params[:scope] == "pending"
      base_scope = base_scope.where(status: "approved") if params[:scope] == "approved"
      base_scope = base_scope.where(status: "rejected") if params[:scope] == "rejected"

      # Recherche Ransack
      @q = base_scope.ransack(params[:q])
      @organizer_applications = @q.result(distinct: true).order(created_at: :desc)

      # Pagination
      @pagy, @organizer_applications = pagy(@organizer_applications, @pagy_options)
    end

    # GET /admin-panel/organizer_applications/:id
    def show
      # L'application est déjà chargée via set_organizer_application
    end

    # PATCH /admin-panel/organizer_applications/:id/approve
    def approve
      authorize @organizer_application, :approve?, policy_class: AdminPanel::OrganizerApplicationPolicy

      if @organizer_application.update(
        status: "approved",
        reviewed_by: current_user,
        reviewed_at: Time.current
      )
        flash[:notice] = "Candidature approuvée avec succès"
        redirect_to admin_panel_organizer_application_path(@organizer_application)
      else
        flash[:alert] = "Impossible d'approuver la candidature : #{@organizer_application.errors.full_messages.join(', ')}"
        redirect_to admin_panel_organizer_application_path(@organizer_application)
      end
    end

    # PATCH /admin-panel/organizer_applications/:id/reject
    def reject
      authorize @organizer_application, :reject?, policy_class: AdminPanel::OrganizerApplicationPolicy

      if @organizer_application.update(
        status: "rejected",
        reviewed_by: current_user,
        reviewed_at: Time.current
      )
        flash[:notice] = "Candidature refusée"
        redirect_to admin_panel_organizer_application_path(@organizer_application)
      else
        flash[:alert] = "Impossible de refuser la candidature : #{@organizer_application.errors.full_messages.join(', ')}"
        redirect_to admin_panel_organizer_application_path(@organizer_application)
      end
    end

    # DELETE /admin-panel/organizer_applications/:id
    def destroy
      if @organizer_application.destroy
        flash[:notice] = "Candidature supprimée avec succès"
        redirect_to admin_panel_organizer_applications_path
      else
        flash[:alert] = "Impossible de supprimer la candidature : #{@organizer_application.errors.full_messages.join(', ')}"
        redirect_to admin_panel_organizer_application_path(@organizer_application)
      end
    end

    private

    def set_organizer_application
      @organizer_application = ::OrganizerApplication.find(params[:id])
    end

    def authorize_organizer_application
      authorize ::OrganizerApplication, policy_class: AdminPanel::OrganizerApplicationPolicy
    end
  end
end
