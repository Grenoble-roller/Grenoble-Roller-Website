# frozen_string_literal: true

module AdminPanel
  class UsersController < BaseController
    # Pagy 43 : La méthode pagy() est disponible directement, plus besoin d'inclure Pagy::Backend

    before_action :set_user, only: %i[show edit update destroy]
    before_action :authorize_user, only: %i[show edit update destroy]

    # GET /admin-panel/users
    def index
      authorize [ :admin_panel, User ]

      # Recherche et filtres avec Ransack
      @q = User.ransack(params[:q])
      @users = @q.result.includes(:role)

      # Filtres supplémentaires
      @users = @users.where(role_id: params[:role_id]) if params[:role_id].present?
      @users = @users.where("can_be_volunteer = ?", params[:volunteer] == "true") if params[:volunteer].present?
      @users = @users.where.not(confirmed_at: nil) if params[:confirmed] == "true"
      @users = @users.where(confirmed_at: nil) if params[:confirmed] == "false"

      # Pagination
      @pagy, @users = pagy(@users.order(created_at: :desc), items: params[:per_page] || 25)
    end

    # GET /admin-panel/users/:id
    def show
      # Le user est déjà chargé via set_user
      @attendances = @user.attendances.includes(:event).order(created_at: :desc).limit(10)
    end

    # GET /admin-panel/users/new
    def new
      @user = User.new
      authorize [ :admin_panel, @user ]
    end

    # POST /admin-panel/users
    def create
      @user = User.new(user_params)
      authorize [ :admin_panel, @user ]

      # Vérifier que le rôle assigné n'est pas supérieur au rôle de l'utilisateur actuel
      if user_params[:role_id].present?
        new_role = Role.find_by(id: user_params[:role_id])
        unless RoleAssignmentService.can_assign_role_to_user?(
          assigner: current_user,
          target_user: @user,
          new_role: new_role
        )
          @user.errors.add(:role_id, "Vous ne pouvez pas assigner un rôle supérieur au vôtre")
          render :new, status: :unprocessable_entity
          return
        end
      end

      # Passer l'utilisateur assigneur pour la validation du modèle
      @user.assigner_user = current_user

      if @user.save
        flash[:notice] = "Utilisateur créé avec succès"
        redirect_to admin_panel_user_path(@user)
      else
        render :new, status: :unprocessable_entity
      end
    end

    # GET /admin-panel/users/:id/edit
    def edit
      # Le user est déjà chargé via set_user
    end

    # PATCH/PUT /admin-panel/users/:id
    def update
      # Gérer les champs password (si vides, ne pas les mettre à jour)
      user_params_to_update = user_params.dup
      if user_params_to_update[:password].blank? && user_params_to_update[:password_confirmation].blank?
        user_params_to_update.delete(:password)
        user_params_to_update.delete(:password_confirmation)
      end

      # Gérer le boolean can_be_volunteer (si non présent dans les params, c'est false)
      unless params[:user].key?(:can_be_volunteer)
        user_params_to_update[:can_be_volunteer] = false
      end

      # Vérifier que le rôle assigné n'est pas supérieur au rôle de l'utilisateur actuel
      if user_params_to_update[:role_id].present?
        new_role = Role.find_by(id: user_params_to_update[:role_id])
        # Empêcher un admin de se mettre Super_Admin (ou tout auto-élévation)
        if @user.id == current_user.id && new_role && current_user.role&.level && new_role.level.to_i > current_user.role.level.to_i
          @user.errors.add(:role_id, "Vous ne pouvez pas vous attribuer un rôle supérieur au vôtre")
          render :edit, status: :unprocessable_entity
          return
        end
        unless RoleAssignmentService.can_assign_role_to_user?(
          assigner: current_user,
          target_user: @user,
          new_role: new_role
        )
          @user.errors.add(:role_id, "Vous ne pouvez pas assigner un rôle supérieur au vôtre")
          render :edit, status: :unprocessable_entity
          return
        end
      end

      # Passer l'utilisateur assigneur pour la validation du modèle
      @user.assigner_user = current_user

      if @user.update(user_params_to_update)
        flash[:notice] = "Utilisateur mis à jour avec succès"
        redirect_to admin_panel_user_path(@user)
      else
        render :edit, status: :unprocessable_entity
      end
    end

    # DELETE /admin-panel/users/:id
    def destroy
      if @user.destroy
        flash[:notice] = "Utilisateur supprimé avec succès"
      else
        flash[:alert] = "Erreur lors de la suppression: #{@user.errors.full_messages.join(', ')}"
      end

      redirect_to admin_panel_users_path
    end

    private

    def set_user
      @user = User.find(params[:id])
    end

    def authorize_user
      authorize [ :admin_panel, @user ]
    end

    def user_params
      params.require(:user).permit(
        :email, :password, :password_confirmation,
        :first_name, :last_name, :bio, :phone, :avatar_url,
        :role_id, :date_of_birth,
        :address, :city, :postal_code, :skill_level,
        :wants_email_info, :wants_events_mail, :wants_initiation_mail, :wants_whatsapp,
        :can_be_volunteer,
        :avatar
      )
    end
  end
end
