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

  # Storefront square (1:1) — catalog + PDP frames are square.
  def square_image_variant(attachment, size: 800, quality: 82)
    return nil unless attachment_ready?(attachment)

    attachment.variant(
      resize_to_fill: [ size, size ],
      format: :webp,
      saver: { quality: quality }
    )
  end

  # Gallery for PDP: product image + unique variant images (pro multi-photo strip).
  def product_gallery_entries(product, variants = [])
    seen = {}
    entries = []

    append_gallery_entry = lambda do |attachment, label: nil, variant_id: nil|
      return unless attachment_ready?(attachment)

      blob_id = attachment.blob_id
      return if seen[blob_id]

      seen[blob_id] = true
      full = square_image_variant(attachment, size: 900)
      thumb = square_image_variant(attachment, size: 160)
      return unless full && thumb

      entries << {
        blob_id: blob_id,
        full_url: url_for(full),
        thumb_url: url_for(thumb),
        label: label,
        variant_id: variant_id
      }
    end

    append_gallery_entry.call(product.image, label: product.name) if product&.image&.attached?

    Array(variants).each do |variant|
      next unless variant.images.attached?

      variant.images.each_with_index do |img, idx|
        append_gallery_entry.call(
          img,
          label: "#{product.name} — vue #{idx + 1}",
          variant_id: variant.id
        )
      end
    end

    entries
  end

  def product_image_url(product)
    image = product_primary_image(product)
    return url_for(square_image_variant(image, size: 800)) if image

    nil
  end

  def variant_image_url(variant)
    image = variant_primary_image(variant)
    return url_for(square_image_variant(image, size: 800)) if image

    nil
  end

  def product_image_tag(product)
    image = product_primary_image(product)
    square_image_variant(image, size: 800) if image
  end

  # Alias used by storefront views that wrap the variant in lazy_image_tag.
  alias_method :product_lazy_image_tag, :product_image_tag

  def variant_image_tag(variant)
    image = variant_primary_image(variant)
    square_image_variant(image, size: 800) if image
  end

  alias_method :variant_lazy_image_tag, :variant_image_tag

  # Storefront urgency threshold (aligned with events/initiations ≤5 and admin low-stock cues).
  LOW_STOCK_THRESHOLD = 5

  # Prefer inventory.available_qty (stock − reserved). Never fall back to raw stock_qty when
  # an inventory row exists — that falsely showed "En stock" while CTA stayed disabled.
  def variant_available_stock(variant)
    return 0 unless variant

    if variant.inventory
      [ variant.inventory.available_qty.to_i, 0 ].max
    else
      [ variant.stock_qty.to_i, 0 ].max
    end
  end

  def product_available_stock(variants)
    Array(variants).sum { |v| variant_available_stock(v) }
  end

  # :out_of_stock | :low_stock | :in_stock
  def stock_availability_level(qty)
    q = qty.to_i
    return :out_of_stock if q <= 0
    return :low_stock if q <= LOW_STOCK_THRESHOLD

    :in_stock
  end

  def stock_badge_label(level, qty: nil)
    case level.to_sym
    when :out_of_stock
      "Rupture"
    when :low_stock
      q = qty.to_i
      q.between?(1, LOW_STOCK_THRESHOLD) ? "Plus que #{q}" : "Derniers disponibles"
    when :in_stock
      "En stock"
    else
      "En stock"
    end
  end

  def stock_badge_css_class(level)
    case level.to_sym
    when :out_of_stock then "badge-liquid-danger"
    when :low_stock then "badge-liquid-warning"
    when :in_stock then "badge-liquid-success"
    else "badge-liquid-success"
    end
  end

  private

  def attachment_ready?(attachment)
    return false unless attachment
    return attachment.attached? if attachment.respond_to?(:attached?)

    attachment.respond_to?(:blob) && attachment.blob.present?
  end
end
