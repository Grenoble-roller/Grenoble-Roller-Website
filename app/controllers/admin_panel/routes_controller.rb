# frozen_string_literal: true

module AdminPanel
  class RoutesController < BaseController
    before_action :set_route, only: %i[show edit update destroy]
    before_action :authorize_route

    # GET /admin-panel/routes
    def index
      authorize ::Route, policy_class: AdminPanel::RoutePolicy

      base_scope = ::Route.includes(:events)

      # Filtres par difficulté
      base_scope = base_scope.where(difficulty: params[:difficulty]) if params[:difficulty].present?

      # Scopes
      base_scope = base_scope.where(difficulty: "easy") if params[:scope] == "easy"
      base_scope = base_scope.where(difficulty: "medium") if params[:scope] == "medium"
      base_scope = base_scope.where(difficulty: "hard") if params[:scope] == "hard"

      # Recherche Ransack
      @q = base_scope.ransack(params[:q])
      @routes = @q.result(distinct: true).order(name: :asc)

      # Pagination
      @pagy, @routes = pagy(@routes, @pagy_options)
    end

    # GET /admin-panel/routes/:id
    def show
      @events = @route.events
        .includes(:creator_user, :attendances)
        .order(start_at: :desc)
    end

    # GET /admin-panel/routes/new
    def new
      @route = ::Route.new
      authorize @route, policy_class: AdminPanel::RoutePolicy
    end

    # POST /admin-panel/routes
    def create
      @route = ::Route.new(route_params)
      authorize @route, policy_class: AdminPanel::RoutePolicy

      if @route.save
        flash[:notice] = "Route créée avec succès"
        redirect_to admin_panel_route_path(@route)
      else
        render :new, status: :unprocessable_entity
      end
    end

    # GET /admin-panel/routes/:id/edit
    def edit
      # La route est déjà chargée via set_route
    end

    # PATCH/PUT /admin-panel/routes/:id
    def update
      if @route.update(route_params)
        flash[:notice] = "Route mise à jour avec succès"
        redirect_to admin_panel_route_path(@route)
      else
        render :edit, status: :unprocessable_entity
      end
    end

    # DELETE /admin-panel/routes/:id
    def destroy
      if @route.destroy
        flash[:notice] = "Route supprimée avec succès"
        redirect_to admin_panel_routes_path
      else
        flash[:alert] = "Impossible de supprimer la route : #{@route.errors.full_messages.join(', ')}"
        redirect_to admin_panel_route_path(@route)
      end
    end

    private

    def set_route
      @route = ::Route.find(params[:id])
    end

    def authorize_route
      authorize ::Route, policy_class: AdminPanel::RoutePolicy
    end

    def route_params
      params.require(:route).permit(
        :name, :description, :distance_km, :elevation_m, :difficulty,
        :gpx_url, :map_image, :map_image_url, :safety_notes
      )
    end
  end
end
