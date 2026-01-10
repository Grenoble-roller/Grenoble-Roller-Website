# frozen_string_literal: true

module ProductTestHelper
  def attach_test_image(record, attachment_name = :image)
    image_path = Rails.root.join('spec', 'fixtures', 'files', 'test-image.jpg')
    if File.exist?(image_path)
      record.public_send(attachment_name).attach(
        io: File.open(image_path),
        filename: 'test-image.jpg'
      )
    end
  end

  def create_product_with_image(attrs = {})
    product = Product.new(attrs)
    attach_test_image(product, :image)
    product.save!
    product
  end

  def create_variant_with_image(product, attrs = {})
    # Générer un SKU valide si non fourni
    attrs[:sku] ||= "SKU-#{SecureRandom.hex(4).upcase}"
    variant = ProductVariant.new(attrs.merge(product: product))
    attach_test_image(variant, :images)
    variant.save!
    variant
  end
end

RSpec.configure do |config|
  config.include ProductTestHelper
end
