# frozen_string_literal: true

module AdminPanel
  class ProductVariantsController < BaseController
    # Pagy 43 : La méthode pagy() est disponible directement, plus besoin d'inclure Pagy::Backend

    before_action :set_product
    before_action :set_variant, only: %i[show edit update destroy toggle_status]
    before_action :authorize_product

    # GET /admin-panel/products/:product_id/product_variants
    def index
      @variants = @product.product_variants
        .includes(:inventory, :option_values)
        .order(sku: :asc)

      @pagy, @variants = pagy(@variants, items: 50)
    end

    # GET /admin-panel/products/:product_id/product_variants/bulk_edit
    def bulk_edit
      @variant_ids = params[:variant_ids] || []
      @variants = @product.product_variants.where(id: @variant_ids)

      if @variants.empty?
        redirect_to admin_panel_product_product_variants_path(@product),
                    alert: "Aucune variante sélectionnée"
      end
    end

    # PATCH /admin-panel/products/:product_id/product_variants/bulk_update
    def bulk_update
      variant_ids = params[:variant_ids] || []

      if variant_ids.empty?
        flash[:alert] = "Aucune variante sélectionnée"
        redirect_to admin_panel_product_product_variants_path(@product)
        return
      end

      # Récupérer les champs globaux à appliquer
      updates = {}
      # Convertir price_euros en price_cents si présent (bulk_edit utilise maintenant price_euros)
      if params[:price_euros].present?
        updates[:price_cents] = (params[:price_euros].to_f * 100).to_i
      elsif params[:price_cents].present?
        # Compatibilité avec l'ancien système (si price_cents est encore envoyé)
        updates[:price_cents] = (params[:price_cents].to_f * 100).to_i
      end
      updates[:stock_qty] = params[:stock_qty].to_i if params[:stock_qty].present?
      updates[:is_active] = params[:is_active] == "1" if params[:is_active].present? && params[:is_active] != ""

      if updates.empty?
        flash[:alert] = "Aucune modification à appliquer"
        redirect_to bulk_edit_admin_panel_product_product_variants_path(@product, variant_ids: variant_ids)
        return
      end

      # Appliquer les modifications à toutes les variantes sélectionnées
      updated_count = 0
      variant_ids.each do |id|
        variant = @product.product_variants.find_by(id: id)
        next unless variant

        if variant.update(updates)
          updated_count += 1
        end
      end

      if updated_count > 0
        flash[:notice] = "#{updated_count} variante(s) mise(s) à jour avec succès"
      else
        flash[:alert] = "Aucune variante n'a pu être mise à jour"
      end

      redirect_to admin_panel_product_product_variants_path(@product)
    end

    # PATCH /admin-panel/products/:product_id/product_variants/:id/toggle_status
    def toggle_status
      @variant.update(is_active: !@variant.is_active)

      respond_to do |format|
        format.html do
          redirect_back(
            fallback_location: admin_panel_product_product_variants_path(@product),
            notice: "Variante #{@variant.is_active ? 'activée' : 'désactivée'}"
          )
        end
        format.json { render json: { is_active: @variant.is_active } }
      end
    end

    # GET /admin-panel/products/:product_id/product_variants/:id
    def show
      redirect_to edit_admin_panel_product_product_variant_path(@product, @variant)
    end

    # GET /admin-panel/products/:product_id/product_variants/new
    def new
      @variant = @product.product_variants.build
      @variant.price_cents = @product.price_cents || 0
      @variant.currency = @product.currency || "EUR"
      @variant.stock_qty = 0
      @variant.is_active = true

      @option_types = OptionType.includes(:option_values).order(:name)
    end

    # POST /admin-panel/products/:product_id/product_variants
    def create
      params_hash = variant_params.to_h
      # Convertir price_euros en price_cents si présent
      if params[:price_euros].present?
        params_hash[:price_cents] = (params[:price_euros].to_f * 100).to_i
      end
      @variant = @product.product_variants.build(params_hash)
      @option_types = OptionType.includes(:option_values).order(:name)

      # Associer les OptionValues si fournis
      if params[:option_value_ids].present?
        option_values = OptionValue.where(id: params[:option_value_ids])
        @variant.option_values = option_values
      end

      if @variant.save
        flash[:notice] = "Variante créée avec succès"
        redirect_to admin_panel_product_path(@product)
      else
        render :new, status: :unprocessable_entity
      end
    end

    # GET /admin-panel/products/:product_id/product_variants/:id/edit
    def edit
      @option_types = OptionType.includes(:option_values).order(:name)
    end

    # PATCH/PUT /admin-panel/products/:product_id/product_variants/:id
    def update
      @option_types = OptionType.includes(:option_values).order(:name)

      # Mettre à jour les OptionValues si fournis
      if params[:option_value_ids].present?
        option_values = OptionValue.where(id: params[:option_value_ids])
        @variant.option_values = option_values
      end

      params_hash = variant_params.to_h
      # Convertir price_euros en price_cents si présent
      if params[:price_euros].present?
        params_hash[:price_cents] = (params[:price_euros].to_f * 100).to_i
      end
      if @variant.update(params_hash)
        respond_to do |format|
          format.html do
            flash[:notice] = "Variante mise à jour avec succès"
            redirect_to admin_panel_product_path(@product)
          end
          format.json do
            render json: {
              success: true,
              message: "Variante mise à jour avec succès",
              variant: {
                id: @variant.id,
                price_cents: @variant.price_cents
              }
            }
          end
        end
      else
        respond_to do |format|
          format.html do
            render :edit, status: :unprocessable_entity
          end
          format.json do
            render json: {
              success: false,
              message: @variant.errors.full_messages.join(", ")
            }, status: :unprocessable_entity
          end
        end
      end
    end

    # DELETE /admin-panel/products/:product_id/product_variants/:id
    def destroy
      if @variant.destroy
        flash[:notice] = "Variante supprimée avec succès"
      else
        flash[:alert] = "Erreur lors de la suppression: #{@variant.errors.full_messages.join(', ')}"
      end

      redirect_to admin_panel_product_path(@product)
    end

    private

    def set_product
      id = params[:product_id]
      # Accepter hashid (ex: JKqN4TbV) ou id numérique pour les URLs admin
      @product = if id.to_s.match?(/\A\d+\z/)
        Product.find_by(id: id)
      else
        Product.find_by_hashid(id)
      end
      raise ActiveRecord::RecordNotFound, "Produit introuvable" if @product.nil?
    end

    def set_variant
      @variant = @product.product_variants.find(params[:id])
    end

    def authorize_product
      authorize [ :admin_panel, @product ], :update?
    end

    def variant_params
      params.require(:product_variant).permit(
        :sku,
        :price_cents,
        :currency,
        :stock_qty,
        :is_active,
        images: []  # Images multiples
      )
    end
  end
end
