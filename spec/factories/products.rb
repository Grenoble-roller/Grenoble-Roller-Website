# frozen_string_literal: true

FactoryBot.define do
  factory :product do
    association :category, factory: :product_category
    name { 'Roller Quad' }
    slug { "roller-quad-#{SecureRandom.hex(4)}" }
    description { 'Description du produit' }
    price_cents { 5000 }
    currency { 'EUR' }
    is_active { true }

    after(:build) do |product|
      # Attacher une image de test
      image_path = Rails.root.join('spec', 'fixtures', 'files', 'test-image.jpg')
      if File.exist?(image_path)
        product.image.attach(io: File.open(image_path), filename: 'test-image.jpg')
      end
    end

    trait :with_variant do
      after(:create) do |product|
        create(:product_variant, product: product, is_active: false)
        product.reload
      end
    end
  end
end
