# frozen_string_literal: true

FactoryBot.define do
  factory :product_variant do
    association :product
    sku { "SKU-#{SecureRandom.hex(4).upcase}" }
    price_cents { 5000 }
    currency { 'EUR' }
    stock_qty { 10 }
    is_active { false }  # Inactif par défaut, nécessite une image pour activer

    after(:build) do |variant|
      # Contourner la validation d'options à la création ; on ajoute les option_values en after(:create)
      variant.instance_variable_set(:@skip_option_validation, true)
      # Si la variante est active, attacher une image (requise par image_required_if_active)
      if variant.is_active? && variant.images.blank?
        image_path = Rails.root.join('spec', 'fixtures', 'files', 'test-image.jpg')
        if File.exist?(image_path)
          variant.images.attach(io: File.open(image_path), filename: 'test-image.jpg')
        else
          variant.images.attach(io: StringIO.new("\x89PNG\r\n\x1A\n"), filename: 'test.png', content_type: 'image/png')
        end
      end
    end

    after(:create) do |variant|
      next if variant.variant_option_values.any?
      size_option_type = OptionType.find_or_create_by!(name: 'size')
      size_value = OptionValue.find_or_create_by!(
        option_type: size_option_type,
        value: 'Medium'
      )
      VariantOptionValue.find_or_create_by!(variant: variant, option_value: size_value)
    end
  end
end
