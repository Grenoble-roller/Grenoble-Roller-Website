# frozen_string_literal: true

module AdminPanel
  class MembershipsController < BaseController
    # Pagy 43 : La méthode pagy() est disponible directement, plus besoin d'inclure Pagy::Backend

    before_action :set_membership, only: %i[show edit update destroy activate]
    before_action :authorize_membership, only: %i[show edit update destroy]
    before_action :authorize_activate, only: [:activate]

    # GET /admin-panel/memberships
    def index
      authorize [ :admin_panel, Membership ]

      # Recherche et filtres avec Ransack
      @q = Membership.ransack(params[:q])
      @memberships = @q.result.includes(:user, :payment, :tshirt_variant)

      # Scopes
      @memberships = @memberships.active_now if params[:scope] == "active"
      @memberships = @memberships.pending if params[:scope] == "pending"
      @memberships = @memberships.expired if params[:scope] == "expired"
      @memberships = @memberships.personal if params[:scope] == "personal"
      @memberships = @memberships.children if params[:scope] == "children"
      @memberships = @memberships.expiring_soon if params[:scope] == "expiring_soon"

      # Filtres supplémentaires
      @memberships = @memberships.where(status: params[:status]) if params[:status].present?
      @memberships = @memberships.where(category: params[:category]) if params[:category].present?
      @memberships = @memberships.where(is_child_membership: params[:is_child_membership]) if params[:is_child_membership].present?

      # Pagination
      @pagy, @memberships = pagy(@memberships.order(created_at: :desc), items: params[:per_page] || 25)
    end

    # GET /admin-panel/memberships/:id
    def show
      # Le membership est déjà chargé via set_membership
    end

    # GET /admin-panel/memberships/new
    def new
      @membership = Membership.new
      authorize [ :admin_panel, @membership ]
    end

    # POST /admin-panel/memberships
    def create
      params_hash = membership_params.to_h
      # Convertir amount_euros en amount_cents si présent
      if params[:amount_euros].present?
        params_hash[:amount_cents] = (params[:amount_euros].to_f * 100).to_i
      end
      @membership = Membership.new(params_hash)
      authorize [ :admin_panel, @membership ]

      if @membership.save
        flash[:notice] = "Adhésion créée avec succès"
        redirect_to admin_panel_membership_path(@membership)
      else
        render :new, status: :unprocessable_entity
      end
    end

    # GET /admin-panel/memberships/:id/edit
    def edit
      # Le membership est déjà chargé via set_membership
    end

    # PATCH/PUT /admin-panel/memberships/:id
    def update
      params_hash = membership_params.to_h
      # Convertir amount_euros en amount_cents si présent
      if params[:amount_euros].present?
        params_hash[:amount_cents] = (params[:amount_euros].to_f * 100).to_i
      end
      if @membership.update(params_hash)
        flash[:notice] = "Adhésion mise à jour avec succès"
        redirect_to admin_panel_membership_path(@membership)
      else
        render :edit, status: :unprocessable_entity
      end
    end

    # DELETE /admin-panel/memberships/:id
    def destroy
      if @membership.destroy
        flash[:notice] = "Adhésion supprimée avec succès"
      else
        flash[:alert] = "Erreur lors de la suppression: #{@membership.errors.full_messages.join(', ')}"
      end

      redirect_to admin_panel_memberships_path
    end

    # PATCH /admin-panel/memberships/:id/activate
    def activate
      if @membership.status == "pending"
        if @membership.update(status: :active)
          flash[:notice] = "Adhésion validée avec succès. L'adhésion est maintenant active."
        else
          flash[:alert] = "Erreur lors de la validation: #{@membership.errors.full_messages.join(', ')}"
        end
      else
        flash[:alert] = "Cette adhésion ne peut pas être validée (statut actuel : #{@membership.status})."
      end

      redirect_to admin_panel_membership_path(@membership)
    end

    private

    def set_membership
      @membership = Membership.find(params[:id])
    end

    def authorize_membership
      authorize [ :admin_panel, @membership ]
    end

    def authorize_activate
      authorize [ :admin_panel, @membership ], :activate?
    end

    def membership_params
      params.require(:membership).permit(
        :user_id, :category, :status, :start_date, :end_date, :amount_cents, :currency,
        :season, :is_child_membership, :is_minor, :child_first_name, :child_last_name,
        :child_date_of_birth, :parent_authorization, :parent_authorization_date,
        :parent_name, :parent_email, :parent_phone, :tshirt_variant_id, :tshirt_price_cents,
        :wants_whatsapp, :wants_email_info, :rgpd_consent, :legal_notices_accepted,
        :ffrs_data_sharing_consent, :payment_id,
        :health_q1, :health_q2, :health_q3, :health_q4, :health_q5,
        :health_q6, :health_q7, :health_q8, :health_q9, :health_questionnaire_status,
        :medical_certificate
      )
    end
  end
end
