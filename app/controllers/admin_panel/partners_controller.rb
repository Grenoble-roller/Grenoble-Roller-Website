# frozen_string_literal: true

module AdminPanel
  class PartnersController < BaseController
    # Pagy 43 : La méthode pagy() est disponible directement, plus besoin d'inclure Pagy::Backend

    before_action :set_partner, only: %i[show edit update destroy]
    before_action :authorize_partner, only: %i[show edit update destroy]

    # GET /admin-panel/partners
    def index
      authorize [ :admin_panel, Partner ]

      # Recherche et filtres Ransack
      @q = Partner.ransack(params[:q])
      @partners = @q.result

      # Scope par statut
      @partners = @partners.active if params[:scope] == "active"
      @partners = @partners.inactive if params[:scope] == "inactive"

      # Pagination
      @pagy, @partners = pagy(@partners.order(created_at: :desc), items: params[:per_page] || 25)
    end

    # GET /admin-panel/partners/:id
    def show
      # Le partner est déjà chargé via set_partner
    end

    # GET /admin-panel/partners/new
    def new
      @partner = Partner.new
      authorize [ :admin_panel, @partner ]
    end

    # POST /admin-panel/partners
    def create
      @partner = Partner.new(partner_params)
      authorize [ :admin_panel, @partner ]

      if @partner.save
        flash[:notice] = "Partenaire créé avec succès"
        redirect_to admin_panel_partner_path(@partner)
      else
        render :new, status: :unprocessable_entity
      end
    end

    # GET /admin-panel/partners/:id/edit
    def edit
      # Le partner est déjà chargé via set_partner
    end

    # PATCH/PUT /admin-panel/partners/:id
    def update
      if @partner.update(partner_params)
        flash[:notice] = "Partenaire mis à jour avec succès"
        redirect_to admin_panel_partner_path(@partner)
      else
        render :edit, status: :unprocessable_entity
      end
    end

    # DELETE /admin-panel/partners/:id
    def destroy
      if @partner.destroy
        flash[:notice] = "Le partenaire ##{@partner.id} a été supprimé avec succès."
        redirect_to admin_panel_partners_path
      else
        flash[:alert] = "Impossible de supprimer le partenaire : #{@partner.errors.full_messages.join(', ')}"
        redirect_to admin_panel_partner_path(@partner)
      end
    end

    private

    def set_partner
      @partner = Partner.find(params[:id])
    end

    def authorize_partner
      authorize [ :admin_panel, @partner ]
    end

    def partner_params
      params.require(:partner).permit(:name, :url, :logo_url, :description, :is_active)
    end
  end
end
