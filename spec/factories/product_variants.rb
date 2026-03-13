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
      # Si la variante est active, attacher une image
      if variant.is_active?
        image_path = Rails.root.join('spec', 'fixtures', 'files', 'test-image.jpg')
        if File.exist?(image_path)
          variant.images.attach(io: File.open(image_path), filename: 'test-image.jpg')
        end
      end
    end

    # Créer automatiquement des option_values pour éviter les erreurs dans la vue
    after(:create) do |variant|
      # Créer un OptionType "size" s'il n'existe pas
      size_option_type = OptionType.find_or_create_by!(name: 'size')

      # Créer une OptionValue "Medium" s'il n'existe pas
      size_value = OptionValue.find_or_create_by!(
        option_type: size_option_type,
        value: 'Medium'
      )

      # Créer l'association variant_option_value (après création pour avoir l'ID)
      VariantOptionValue.find_or_create_by!(
        variant: variant,
        option_value: size_value
      )

      # Reload pour que l'association option_values soit accessible
      variant.reload
    end
  end
end
