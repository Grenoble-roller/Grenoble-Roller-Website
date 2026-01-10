require 'rails_helper'

RSpec.describe Product, type: :model do
  let!(:category) { ProductCategory.create!(name: 'Accessoires', slug: "accessoires-#{SecureRandom.hex(3)}") }

  def build_product(attrs = {})
    defaults = {
      category: category,
      name: 'Casquette',
      slug: 'casquette',
      price_cents: 2500,
      currency: 'EUR',
      stock_qty: 10,
      is_active: true
    }
    product = Product.new(defaults.merge(attrs))
    attach_test_image(product, :image)
    product
  end

  it 'is valid with valid attributes' do
    expect(build_product).to be_valid
  end

  it 'requires presence of key attributes (except currency default)' do
    p = Product.new
    expect(p).to be_invalid
    expect(p.errors[:name]).to be_present
    expect(p.errors[:slug]).to be_present
    expect(p.errors[:price_cents]).to be_present
    expect(p.errors[:base]).to be_present # image_or_image_url_present ajoute l'erreur sur :base
    expect(p.currency).to eq('EUR')
  end

  it 'enforces slug uniqueness' do
    build_product.save!
    dup = build_product(name: 'Autre')
    expect(dup).to be_invalid
    expect(dup.errors[:slug]).to be_present
  end

  it 'destroys variants when product is destroyed' do
    product = build_product
    product.save!
    variant = create_variant_with_image(product, sku: 'SKU-001', price_cents: 2500, currency: 'EUR', stock_qty: 5, is_active: true)
    expect {
      product.destroy
    }.to change { ProductVariant.count }.by(-1)
    expect(ProductVariant.where(id: variant.id)).to be_empty
  end
end
