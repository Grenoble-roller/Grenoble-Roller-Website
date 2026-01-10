class CartsController < ApplicationController
  before_action :ensure_cart

  def show
    @cart_items = build_cart_items
    @total_cents = @cart_items.sum { |ci| ci[:subtotal_cents] }
  end

  def add_item
    variant_id = params.require(:variant_id).to_i
    quantity = params[:quantity].to_i
    quantity = 1 if quantity <= 0

    variant = ProductVariant.includes(:product, :inventory).find_by(id: variant_id)
    unless variant && variant.is_active && variant.product&.is_active
      return redirect_to shop_path, alert: "Cette variante n'est pas disponible."
    end
    # Utiliser inventory.available_qty si disponible, sinon fallback sur stock_qty
    available_stock = variant.inventory&.available_qty || variant.stock_qty.to_i
    if available_stock <= 0
      return redirect_to shop_path, alert: "Article en rupture de stock."
    end

    key = variant_id.to_s
    current_qty = (session[:cart][key] || 0).to_i
    requested_total = current_qty + quantity
    capped_qty = [ requested_total, available_stock ].min
    session[:cart][key] = capped_qty

    if capped_qty == current_qty
      redirect_to shop_path, alert: "Stock insuffisant pour ajouter plus d'unités."
    else
      product_name = variant.product.name
      added_qty = capped_qty - current_qty

      # Afficher un message d'alerte si la quantité demandée dépasse le stock disponible
      if requested_total > available_stock
        flash[:alert] = "Stock insuffisant. Seulement #{added_qty} unité#{added_qty > 1 ? 's' : ''} ajoutée#{added_qty > 1 ? 's' : ''} au panier."
      end

      message = if added_qty == 1
        "#{product_name} ajouté au panier"
      else
        "#{added_qty}x #{product_name} ajoutés au panier"
      end
      flash[:notice] = message
      flash[:notice_type] = "success"
      flash[:show_cart_button] = true
      # Rediriger vers la boutique pour que le toast "Voir le panier" ait du sens
      redirect_to shop_path
    end
  end

  def update_item
    variant_id = params.require(:variant_id).to_i
    quantity = params.require(:quantity).to_i

    key = variant_id.to_s
    if quantity <= 0
      session[:cart].delete(key)
      variant = ProductVariant.includes(:product, :inventory).find_by(id: variant_id)
      product_name = variant&.product&.name || "Article"
      flash[:notice] = "#{product_name} retiré du panier"
      flash[:notice_type] = "info"
      return redirect_to cart_path
    end

    variant = ProductVariant.includes(:product, :inventory).find_by(id: variant_id)
    unless variant && variant.is_active && variant.product&.is_active
      session[:cart].delete(key)
      return redirect_to cart_path, alert: "Cette variante n’est plus disponible et a été retirée."
    end

    # Utiliser inventory.available_qty si disponible, sinon fallback sur stock_qty
    max_qty = variant.inventory&.available_qty || variant.stock_qty.to_i
    if max_qty <= 0
      session[:cart].delete(key)
      return redirect_to cart_path, alert: "Article en rupture, retiré du panier."
    end

    new_qty = [ quantity, max_qty ].min
    session[:cart][key] = new_qty
    if new_qty < quantity
      redirect_to cart_path, alert: "Quantité ajustée au stock disponible (#{new_qty})."
    else
      flash[:notice] = "Panier mis à jour"
      flash[:notice_type] = "info"
      redirect_to cart_path
    end
  end

  def remove_item
    variant_id = params.require(:variant_id).to_i
    key = variant_id.to_s
    variant = ProductVariant.includes(:product).find_by(id: variant_id)
    product_name = variant&.product&.name || "Article"
    session[:cart].delete(key)
    flash[:notice] = "#{product_name} retiré du panier"
    flash[:notice_type] = "info"
    redirect_to cart_path
  end

  def clear
    session[:cart] = {}
    flash[:notice] = "Panier vidé"
    flash[:notice_type] = "info"
    redirect_to cart_path
  end

  private

  def ensure_cart
    session[:cart] ||= {}
  end

  def build_cart_items
    variant_ids = session[:cart].keys
    return [] if variant_ids.empty?
    variants = ProductVariant.where(id: variant_ids).includes(:product, :inventory).index_by(&:id)
    session[:cart].map do |vid, qty|
      variant = variants[vid.to_i]
      next nil unless variant
      price_cents = variant.price_cents
      {
        variant: variant,
        product: variant.product,
        quantity: qty.to_i,
        unit_price_cents: price_cents,
        subtotal_cents: price_cents * qty.to_i
      }
    end.compact
  end
end
