# frozen_string_literal: true

module AdminPanel
  class ProductsController < BaseController
    # Pagy 43 : La méthode pagy() est disponible directement, plus besoin d'inclure Pagy::Backend

    before_action :set_product, only: %i[show edit update destroy publish unpublish]
    before_action :authorize_product, only: %i[show edit update destroy publish unpublish]

    # GET /admin-panel/products
    def index
      authorize [ :admin_panel, Product ]

      # Recherche et filtres
      @q = Product.ransack(params[:q])
      @products = @q.result.with_associations

      # Filtres supplémentaires
      @products = @products.where(is_active: params[:is_active]) if params[:is_active].present?
      @products = @products.where(category_id: params[:category_id]) if params[:category_id].present?

      # Pagination
      @pagy, @products = pagy(@products.order(created_at: :desc), items: params[:per_page] || 25)

      respond_to do |format|
        format.html
        format.csv { send_data ProductExporter.to_csv(@products), filename: csv_filename, type: "text/csv" }
      end
    end

    # GET /admin-panel/products/:id
    def show
      @variants = @product.product_variants.includes(:option_values).order(sku: :asc)
      @variant_pages, @variants = pagy(@variants, items: 10)  # NOUVEAU : pagination
    end

    # GET /admin-panel/products/new
    def new
      @product = Product.new
      @product.price_cents = 0
      @product.currency = "EUR"
      @product.is_active = true
      authorize [ :admin_panel, @product ]

      @categories = ProductCategory.order(:name)
      @option_types = OptionType.includes(:option_values).order(:name)
    end

    # GET /admin-panel/products/:id/edit
    def edit
      @categories = ProductCategory.order(:name)
      @option_types = OptionType.includes(:option_values).order(:name)
    end

    # POST /admin-panel/products
    def create
      params_hash = product_params.to_h
      # Convertir price_euros en price_cents si présent
      if params[:price_euros].present?
        params_hash[:price_cents] = (params[:price_euros].to_f * 100).to_i
      end
      @product = Product.new(params_hash)
      authorize [ :admin_panel, @product ]

      @categories = ProductCategory.order(:name)
      @option_types = OptionType.includes(:option_values).order(:name)

      if @product.save
        # NOUVEAU : Génération auto si options sélectionnées
        if params[:generate_variants] == "true"
          # Accepter soit option_value_ids (nouveau) soit option_ids (ancien pour compatibilité)
          if params[:option_value_ids].present?
            count = ProductVariantGenerator.generate_combinations_from_values(@product, params[:option_value_ids])
            flash[:notice] = "Produit créé avec #{count} variante(s) générée(s)"
          elsif params[:option_ids].present?
            count = ProductVariantGenerator.generate_combinations(@product, params[:option_ids])
            flash[:notice] = "Produit créé avec #{count} variante(s) générée(s)"
          end
        elsif params[:option_type_ids].present?
          # Ancien système de compatibilité
          option_types = OptionType.where(id: params[:option_type_ids])
          generator = ProductVariantGenerator.new(@product, option_types: option_types)
          variants = generator.generate(
            base_price_cents: @product.price_cents,
            base_stock_qty: params[:base_stock_qty].to_i
          )

          if generator.errors.any?
            flash[:alert] = "Produit créé mais erreurs lors de la génération des variantes: #{generator.errors.join(', ')}"
          else
            flash[:notice] = "Produit créé avec #{variants.count} variante(s)"
          end
        else
          flash[:notice] = "Produit créé avec succès"
        end

        redirect_to admin_panel_product_path(@product)
      else
        render :new, status: :unprocessable_entity
      end
    end

    # PATCH/PUT /admin-panel/products/:id
    def update
      # Gérer l'auto-save (save_draft) : ignorer la validation des variantes
      if params[:save_draft] == "true"
        @product.assign_attributes(product_params)
        @product.instance_variable_set(:@save_draft, true)
        # Sauvegarder sans valider les variantes (pour l'auto-save)
        if @product.save(validate: false)
          render json: { success: true, message: "Brouillon enregistré" }, status: :ok
        else
          render json: { success: false, errors: @product.errors.full_messages }, status: :unprocessable_entity
        end
        return
      end
      
      # Si génération de variantes manquantes, ignorer la validation des variantes
      if params[:generate_missing] == "true"
        @product.instance_variable_set(:@generate_missing, true)
      end
      
      params_hash = product_params.to_h
      # Convertir price_euros en price_cents si présent
      if params[:price_euros].present?
        params_hash[:price_cents] = (params[:price_euros].to_f * 100).to_i
      end
      if @product.update(params_hash)
        # NOUVEAU : Générer options manquantes si ajoutées après création
        if params[:generate_missing] == "true"
          # Accepter soit option_value_ids (nouveau) soit option_ids (ancien pour compatibilité)
          if params[:option_value_ids].present?
            option_value_ids = Array(params[:option_value_ids]).map(&:to_i).reject(&:zero?)
            if option_value_ids.empty?
              flash[:alert] = "Aucune valeur d'option sélectionnée."
              redirect_to edit_admin_panel_product_path(@product)
              return
            end
            
            count = ProductVariantGenerator.generate_missing_combinations_from_values(@product, option_value_ids)
            if count > 0
              flash[:notice] = "Produit mis à jour avec #{count} nouvelle(s) variante(s) générée(s)"
              # Recharger le produit pour avoir les nouvelles variantes
              @product.reload
            else
              flash[:alert] = "Aucune nouvelle variante générée. Les combinaisons sélectionnées existent peut-être déjà."
            end
          elsif params[:option_ids].present?
            option_ids = Array(params[:option_ids]).map(&:to_i).reject(&:zero?)
            if option_ids.empty?
              flash[:alert] = "Aucun type d'option sélectionné."
              redirect_to edit_admin_panel_product_path(@product)
              return
            end
            
            count = ProductVariantGenerator.generate_missing_combinations(@product, option_ids)
            if count > 0
              flash[:notice] = "Produit mis à jour avec #{count} nouvelle(s) variante(s) générée(s)"
              # Recharger le produit pour avoir les nouvelles variantes
              @product.reload
            else
              flash[:alert] = "Aucune nouvelle variante générée. Les combinaisons sélectionnées existent peut-être déjà."
            end
          else
            flash[:alert] = "Aucune option sélectionnée pour générer les variantes."
          end
          # Rediriger vers edit pour voir les nouvelles variantes
          redirect_to edit_admin_panel_product_path(@product)
        else
          flash[:notice] = "Produit mis à jour avec succès"
          redirect_to admin_panel_product_path(@product)
        end
      else
        @categories = ProductCategory.order(:name)
        @option_types = OptionType.includes(:option_values).order(:name)
        render :edit, status: :unprocessable_entity
      end
    end

    # DELETE /admin-panel/products/:id
    def destroy
      if @product.destroy
        flash[:notice] = "Produit supprimé avec succès"
      else
        flash[:alert] = "Erreur lors de la suppression: #{@product.errors.full_messages.join(', ')}"
      end

      redirect_to admin_panel_products_path
    end

    # POST /admin-panel/products/:id/publish
    def publish
      if @product.update(is_active: true)
        flash[:notice] = "Produit publié avec succès"
      else
        flash[:alert] = "Erreur : #{@product.errors.full_messages.join(', ')}"
      end

      redirect_to admin_panel_product_path(@product)
    end

    # POST /admin-panel/products/:id/unpublish
    def unpublish
      if @product.update(is_active: false)
        flash[:notice] = "Produit dépublié avec succès"
      else
        flash[:alert] = "Erreur : #{@product.errors.full_messages.join(', ')}"
      end

      redirect_to admin_panel_product_path(@product)
    end

    # GET /admin-panel/products/check_sku
    # Vérifie si un SKU est disponible (pour validation AJAX)
    def check_sku
      sku = params[:sku]&.strip
      variant_id = params[:variant_id]&.to_i

      if sku.blank?
        render json: { available: false, message: "SKU requis" }, status: :bad_request
        return
      end

      # Vérifier si le SKU existe déjà (sauf pour la variante en cours d'édition)
      existing = ProductVariant.find_by(sku: sku)
      available = existing.nil? || (variant_id.present? && existing.id == variant_id)

      render json: {
        available: available,
        message: available ? "SKU disponible" : "SKU déjà utilisé"
      }
    end

    # POST /admin-panel/products/import
    def import
      authorize Product

      unless params[:file].present?
        flash[:alert] = "Aucun fichier fourni"
        redirect_to admin_panel_products_path
        return
      end

      # TODO: Implémenter ProductImporter (PHASE 4)
      flash[:alert] = "Import non implémenté (PHASE 4)"
      redirect_to admin_panel_products_path
    end

    # GET /admin-panel/products/export
    def export
      authorize [ :admin_panel, Product ]

      @q = Product.ransack(params[:q])
      @products = @q.result.with_associations

      respond_to do |format|
        format.csv do
          send_data ProductExporter.to_csv(@products), filename: csv_filename, type: "text/csv"
        end
      end
    end

    # NOUVEAU : Preview variantes avant génération
    def preview_variants
      # Accepter soit option_value_ids (nouveau) soit option_ids (ancien pour compatibilité)
      option_value_ids = Array(params[:option_value_ids] || []).map(&:to_i).reject(&:zero?)
      option_ids = Array(params[:option_ids] || []).map(&:to_i).reject(&:zero?)
      
      if option_value_ids.present?
        # Nouveau mode : valeurs individuelles sélectionnées
        preview = ProductVariantGenerator.preview_from_values(nil, option_value_ids)
      elsif option_ids.present?
        # Ancien mode : types d'options entiers (compatibilité)
        preview = ProductVariantGenerator.preview(nil, option_ids)
      else
        preview = { count: 0, preview_skus: [], estimated_time: 0, warning: nil }
      end
      
      render json: preview
    end

    # NOUVEAU : Édition en masse variantes
    def bulk_update_variants
      # Extraire et valider AVANT where() pour que Brakeman reconnaisse la variable locale sécurisée
      input_ids = validate_variant_ids(params[:variant_ids])

      if input_ids.empty?
        render json: { success: false, message: "Aucun ID de variante valide fourni" }, status: :bad_request
        return
      end

      updates = params[:updates] || {}

      if updates.empty?
        render json: { success: false, message: "Aucune donnée de mise à jour fournie" }, status: :bad_request
        return
      end

      updates_params = updates.is_a?(ActionController::Parameters) ? updates : ActionController::Parameters.new(updates)
      permitted_updates = updates_params.permit(:price_cents, :stock_qty, :is_active)

      if permitted_updates.empty? || permitted_updates.values.all?(&:nil?)
        render json: { success: false, message: "Aucun champ valide à mettre à jour. Champs autorisés: price_cents, stock_qty, is_active" }, status: :bad_request
        return
      end

      # Maintenant input_ids est une variable locale validée, pas params directement
      # Brakeman reconnaît que c'est sécurisé
      existing_variants = ProductVariant.where(id: input_ids)

      if existing_variants.empty?
        render json: { success: false, message: "Aucune variante valide trouvée pour les IDs fournis" }, status: :bad_request
        return
      end

      begin
        count = existing_variants.update_all(permitted_updates.to_h)
        render json: { success: true, count: count }
      rescue StandardError => e
        Rails.logger.error("Erreur lors de la mise à jour en masse: #{e.message}")
        render json: { success: false, message: "Erreur lors de la mise à jour: #{e.message}" }, status: :unprocessable_entity
      end
    end

    private

    # Helper method pour valider les IDs de variantes
    # Brakeman reconnaît cette méthode comme une validation sécurisée
    def validate_variant_ids(variant_ids)
      Array(variant_ids).filter_map { |id| id.to_i if id.to_i.positive? }
    end

    def set_product
      @product = Product.find(params[:id])
    end

    def authorize_product
      authorize [ :admin_panel, @product ]
    end

    def product_params
      params.require(:product).permit(
        :category_id,
        :name,
        :slug,
        :description,
        :price_cents,
        :currency,
        :stock_qty,
        :is_active,
        :image
      )
    end

    def csv_filename
      "products_#{Time.current.strftime('%Y%m%d_%H%M%S')}.csv"
    end
  end
end
