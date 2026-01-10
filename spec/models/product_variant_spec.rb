require 'rails_helper'

RSpec.describe ProductVariant, type: :model do
  let!(:category) { ProductCategory.create!(name: 'Accessoires', slug: "accessoires-#{SecureRandom.hex(3)}") }
  let!(:product) do
    # Créer le produit sans image d'abord, puis attacher l'image
    p = Product.new(category: category, name: 'T-shirt', slug: "tshirt-#{SecureRandom.hex(3)}", price_cents: 1900, currency: 'EUR', stock_qty: 10, is_active: true)
    image_path = Rails.root.join('spec', 'fixtures', 'files', 'test-image.jpg')
    if File.exist?(image_path)
      p.image.attach(io: File.open(image_path), filename: 'test-image.jpg')
    end
    p.save!
    p
  end

  def build_variant(attrs = {})
    defaults = {
      product: product,
      sku: 'SKU-001',
      price_cents: 1900,
      currency: 'EUR',
      stock_qty: 5,
      is_active: false  # Inactif par défaut, nécessite une image pour activer
    }
    variant = ProductVariant.new(defaults.merge(attrs))
    # Si actif, attacher une image
    if variant.is_active?
      image_path = Rails.root.join('spec', 'fixtures', 'files', 'test-image.jpg')
      variant.images.attach(io: File.open(image_path), filename: 'test-image.jpg') if File.exist?(image_path)
    end
    variant
  end

  it 'is valid with valid attributes (inactive variant)' do
    variant = build_variant
    expect(variant).to be_valid
    expect(variant.is_active).to be false
  end

  it 'requires image to be active (unless product has image)' do
    # Créer un produit sans image pour ce test
    product_no_image = Product.new(category: category, name: 'T-shirt 2', slug: "tshirt2-#{SecureRandom.hex(3)}", price_cents: 1900, currency: 'EUR', stock_qty: 10, is_active: false)
    product_no_image.save!(validate: false)  # Sauvegarder sans validation pour éviter l'erreur d'image

    variant = ProductVariant.new(product: product_no_image, sku: 'SKU-002', price_cents: 1900, currency: 'EUR', stock_qty: 5, is_active: true)
    expect(variant).to be_invalid
    expect(variant.errors[:base]).to include("Une image est requise pour activer la variante")
  end

  it 'is valid when active with image' do
    variant = build_variant(is_active: true)
    image_path = Rails.root.join('spec', 'fixtures', 'files', 'test-image.jpg')
    variant.images.attach(io: File.open(image_path), filename: 'test-image.jpg') if File.exist?(image_path)
    expect(variant).to be_valid
  end

  it 'requires sku and price_cents (currency defaults to EUR)' do
    v = ProductVariant.new
    expect(v).to be_invalid
    expect(v.errors[:sku]).to be_present
    expect(v.errors[:price_cents]).to be_present
    expect(v.currency).to eq('EUR')
  end

  it 'enforces sku uniqueness' do
    build_variant.save!
    dup = build_variant(sku: 'SKU-001')
    expect(dup).to be_invalid
    expect(dup.errors[:sku]).to be_present
  end

  it 'has many variant_option_values and option_values through join table' do
    v = build_variant
    v.save!
    ot = OptionType.create!(name: 'Taille', presentation: 'Taille')
    ov = OptionValue.create!(option_type: ot, value: 'M', presentation: 'M')
    VariantOptionValue.create!(variant: v, option_value: ov)
    expect(v.variant_option_values.count).to eq(1)
    expect(v.option_values.first.value).to eq('M')
  end

  it 'destroys join rows when variant is destroyed' do
    v = build_variant
    v.save!
    ot = OptionType.create!(name: 'Couleur', presentation: 'Couleur')
    ov = OptionValue.create!(option_type: ot, value: 'Bleu', presentation: 'Bleu')
    VariantOptionValue.create!(variant: v, option_value: ov)
    expect {
      v.destroy
    }.to change { VariantOptionValue.count }.by(-1)
  end
end
