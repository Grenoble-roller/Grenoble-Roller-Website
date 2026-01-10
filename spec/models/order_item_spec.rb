require 'rails_helper'

RSpec.describe OrderItem, type: :model do
  let!(:role) { ensure_role(code: 'USER_ORDER_ITEM', name: 'Utilisateur Order', level: 20) }
  let!(:user) { create_user(role: role, email: 'order-item@example.com') }
  let!(:order) { Order.create!(user: user, status: 'pending', total_cents: 1000, currency: 'EUR') }
  let!(:category) { ProductCategory.create!(name: 'Cat', slug: "cat-#{SecureRandom.hex(3)}") }
  let!(:product) { create_product_with_image(category: category, name: 'Prod', slug: "prod-#{SecureRandom.hex(3)}", price_cents: 1000, currency: 'EUR', stock_qty: 10, is_active: true) }
  let!(:variant) do
    create_variant_with_image(product,
      sku: "SKU-#{SecureRandom.hex(2).upcase}",
      price_cents: 1000,
      currency: 'EUR',
      stock_qty: 5,
      is_active: true
    )
  end

  it 'belongs to order and variant' do
    item = OrderItem.new(order: order, variant_id: variant.id, quantity: 2, unit_price_cents: 1000)
    expect(item).to be_valid
    item.save!
    expect(item.order).to eq(order)
    expect(item.variant_id).to eq(variant.id)
  end
end
