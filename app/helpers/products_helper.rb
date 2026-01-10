module ProductsHelper
  # Helper pour obtenir l'URL de l'image d'un produit (Active Storage ou URL string)
  def product_image_url(product)
    return url_for(product.image) if product&.image&.attached?
    return product.image_url if product&.image_url.present?
    nil
  end

  # Helper pour obtenir l'URL de l'image d'une variante (Active Storage ou URL ou fallback produit)
  def variant_image_url(variant)
    # ProductVariant utilise has_many_attached :images (pluriel)
    return url_for(variant.images.first) if variant&.images&.attached?
    return variant.image_url if variant&.image_url.present?
    product_image_url(variant.product) if variant.product
  end

  # Helper pour obtenir l'objet image (pour image_tag direct)
  def product_image_tag(product)
    return product.image if product&.image&.attached?
    return product.image_url if product&.image_url.present?
    nil
  end

  def variant_image_tag(variant)
    # ProductVariant utilise has_many_attached :images (pluriel)
    return variant.images.first if variant&.images&.attached?
    return variant.image_url if variant&.image_url.present?
    product_image_tag(variant.product) if variant.product
  end

  # Calculer le stock disponible d'une variante
  # Utilise stock_qty de la variante comme source de vérité principale
  # Si l'inventaire existe et est synchronisé, utilise available_qty pour tenir compte des réservations
  def variant_available_stock(variant)
    return 0 unless variant
    if variant.inventory && variant.inventory.stock_qty == variant.stock_qty
      # Inventaire synchronisé : utiliser available_qty pour tenir compte des réservations
      variant.inventory.available_qty
    else
      # Inventaire désynchronisé ou inexistant : utiliser stock_qty de la variante
      variant.stock_qty.to_i
    end
  end
end
