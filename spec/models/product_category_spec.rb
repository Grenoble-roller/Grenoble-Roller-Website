require 'rails_helper'

RSpec.describe ProductCategory, type: :model do
  it 'is valid with valid attributes' do
    category = ProductCategory.new(name: 'Vêtements', slug: 'vetements')
    expect(category).to be_valid
  end

  it 'requires name and slug' do
    category = ProductCategory.new
    expect(category).to be_invalid
    expect(category.errors[:name]).to be_present
    expect(category.errors[:slug]).to be_present
  end

  it 'enforces slug uniqueness' do
    ProductCategory.create!(name: 'Cat1', slug: 'unique-cat')
    dup = ProductCategory.new(name: 'Cat2', slug: 'unique-cat')
    expect(dup).to be_invalid
    expect(dup.errors[:slug]).to be_present
  end

  it 'restricts destroy when products exist' do
    category = ProductCategory.create!(name: 'Cat', slug: "cat-#{SecureRandom.hex(3)}")
    product = create_product_with_image(category: category, name: 'T-shirt', slug: "tshirt-#{SecureRandom.hex(3)}", price_cents: 1500, currency: 'EUR', stock_qty: 0, is_active: true)
    expect {
      category.destroy
    }.to raise_error(ActiveRecord::DeleteRestrictionError)
    expect(Product.exists?(product.id)).to be true
  end
end
