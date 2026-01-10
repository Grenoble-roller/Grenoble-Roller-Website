class ProductsController < ApplicationController
  def index
    @categories = ProductCategory.order(:name)

    # Filtrer par catégorie si un slug est fourni
    @selected_category = nil
    if params[:category].present?
      @selected_category = ProductCategory.find_by(slug: params[:category])
    end

    products = Product.includes(:category, product_variants: { inventory: {}, variant_option_values: :option_value })
                      .where(is_active: true)

    # Appliquer le filtre de catégorie si une catégorie est sélectionnée
    if @selected_category
      products = products.where(category_id: @selected_category.id)
    end

    # Trier : produits avec stock en premier, puis par nom
    # Utiliser inventory.available_qty si disponible, sinon fallback sur stock_qty
    @products = products.to_a.sort_by do |product|
      has_stock = product.product_variants.any? { |v|
        v.is_active && (v.inventory&.available_qty || v.stock_qty.to_i) > 0
      }
      [ has_stock ? 0 : 1, product.name ]
    end

    # Compter les produits par catégorie (pour afficher dans les filtres)
    @category_counts = ProductCategory.left_joins(:products)
                                      .where(products: { is_active: true })
                                      .group("product_categories.id")
                                      .count("products.id")
  end

  def show
    # Try slug first, then numeric id; raise 404 if not found
    @product = Product.includes(product_variants: { variant_option_values: { option_value: :option_type } })
                      .where(is_active: true)
                      .find_by(slug: params[:id])

    if @product.nil? && params[:id].to_s.match?(/\A\d+\z/)
      @product = Product.includes(product_variants: { variant_option_values: { option_value: :option_type } })
                        .where(is_active: true)
                        .find_by(id: params[:id])
    end

    # Si toujours nil, essayer avec Hashid (pour les IDs encodés)
    if @product.nil?
      begin
        decoded_id = Product.decode_id(params[:id])
        @product = Product.includes(product_variants: { variant_option_values: { option_value: :option_type } })
                          .where(is_active: true)
                          .find_by(id: decoded_id) if decoded_id
      rescue Hashid::Rails::InvalidHashidError
        # Ignorer l'erreur Hashid, continuer
      end
    end

    raise ActiveRecord::RecordNotFound, "Product not found" if @product.nil?

    # Charger les variantes actives avec toutes les associations nécessaires
    # IMPORTANT: option_values est une relation through, donc il faut charger variant_option_values avec option_value et option_type
    # Cela permet d'accéder à v.option_values et ov.option_type sans requêtes supplémentaires
    @variants = @product.product_variants
                        .where(is_active: true)
                        .includes(
                          :inventory,
                          variant_option_values: { option_value: :option_type }
                        )
                        .order(:sku)
  end
end
