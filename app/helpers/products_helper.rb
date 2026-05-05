module ProductsHelper
  def product_primary_image(product)
    return nil unless product
    return product.image if product.image.attached?

    nil
  end

  def variant_primary_image(variant)
    return nil unless variant
    return variant.images.first if variant.images.attached?

    product_primary_image(variant.product)
  end

  # Canonical storefront variant (16:9, centré — format unique décision bénévoles 2026-05).
  def square_image_variant(attachment, size: 800, quality: 82)
    return nil unless attachment.respond_to?(:attached?) && attachment.attached?

    attachment.variant(
      resize_to_fill: [ size, (size * 9.0 / 16).round ],
      format: :webp,
      saver: { quality: quality }
    )
  end

  # Helper pour obtenir l'URL de l'image d'un produit (Active Storage)
  def product_image_url(product)
    image = product_primary_image(product)
    return url_for(square_image_variant(image, size: 800)) if image

    nil
  end

  # Helper pour obtenir l'URL de l'image d'une variante (fallback produit si nécessaire)
  def variant_image_url(variant)
    image = variant_primary_image(variant)
    return url_for(square_image_variant(image, size: 800)) if image

    nil
  end

  # Helper pour obtenir l'objet image (pour image_tag direct)
  def product_image_tag(product)
    image = product_primary_image(product)
    square_image_variant(image, size: 800) if image
  end

  def variant_image_tag(variant)
    image = variant_primary_image(variant)
    square_image_variant(image, size: 800) if image
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
