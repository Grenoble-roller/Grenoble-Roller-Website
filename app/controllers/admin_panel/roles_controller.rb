# frozen_string_literal: true

module AdminPanel
  class RolesController < BaseController
    # Pagy 43 : La méthode pagy() est disponible directement, plus besoin d'inclure Pagy::Backend

    # IMPORTANT : Les rôles sont accessibles UNIQUEMENT pour level >= 70 (SUPERADMIN)
    before_action :ensure_superadmin
    before_action :set_role, only: %i[show edit update destroy]
    before_action :authorize_role, only: %i[show edit update destroy]

    # GET /admin-panel/roles
    def index
      authorize [ :admin_panel, Role ]

      # Recherche et filtres avec Ransack
      @q = Role.ransack(params[:q])
      @roles = @q.result

      # Filtre par level
      @roles = @roles.where(level: params[:level]) if params[:level].present?

      # Pagination
      @pagy, @roles = pagy(@roles.order(level: :asc), items: params[:per_page] || 25)
    end

    # GET /admin-panel/roles/:id
    def show
      # Le role est déjà chargé via set_role
      @users = @role.users.order(:email).limit(50)
    end

    # GET /admin-panel/roles/new
    def new
      @role = Role.new
      authorize [ :admin_panel, @role ]
    end

    # POST /admin-panel/roles
    def create
      @role = Role.new(role_params)
      authorize [ :admin_panel, @role ]

      if @role.save
        flash[:notice] = "Rôle créé avec succès"
        redirect_to admin_panel_role_path(@role)
      else
        render :new, status: :unprocessable_entity
      end
    end

    # GET /admin-panel/roles/:id/edit
    def edit
      # Le role est déjà chargé via set_role
    end

    # PATCH/PUT /admin-panel/roles/:id
    def update
      if @role.update(role_params)
        flash[:notice] = "Rôle mis à jour avec succès"
        redirect_to admin_panel_role_path(@role)
      else
        render :edit, status: :unprocessable_entity
      end
    end

    # DELETE /admin-panel/roles/:id
    def destroy
      if @role.destroy
        flash[:notice] = "Rôle supprimé avec succès"
      else
        flash[:alert] = "Erreur lors de la suppression: #{@role.errors.full_messages.join(', ')}"
      end

      redirect_to admin_panel_roles_path
    end

    private

    def set_role
      @role = Role.find(params[:id])
    end

    def authorize_role
      authorize [ :admin_panel, @role ]
    end

    def role_params
      params.require(:role).permit(:name, :code, :description, :level)
    end

    def ensure_superadmin
      # IMPORTANT : Utilise le NUMÉRO du level, pas le code du rôle
      # Level 70 = SUPERADMIN uniquement
      unless current_user&.role&.level.to_i >= 70
        redirect_to admin_panel_initiations_path, alert: "Accès réservé aux super-administrateurs"
      end
    end
  end
end
