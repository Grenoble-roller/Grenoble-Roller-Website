# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Inventory, type: :model do
  let(:product) { create(:product) }
  let(:variant) { create(:product_variant, product: product) }
  let(:inventory) { variant.inventory || create(:inventory, product_variant: variant) }

  describe 'validations' do
    it 'is valid with valid attributes' do
      expect(inventory).to be_valid
    end

    it 'requires product_variant_id' do
      inventory.product_variant_id = nil
      expect(inventory).to be_invalid
      expect(inventory.errors[:product_variant_id]).to be_present
    end

    it 'requires stock_qty to be >= 0' do
      inventory.stock_qty = -1
      expect(inventory).to be_invalid
      expect(inventory.errors[:stock_qty]).to be_present
    end

    it 'requires reserved_qty to be >= 0' do
      inventory.reserved_qty = -1
      expect(inventory).to be_invalid
      expect(inventory.errors[:reserved_qty]).to be_present
    end

    it 'requires unique product_variant_id' do
      # L'inventaire est créé automatiquement par le callback after_create de ProductVariant
      # Donc on utilise celui qui existe déjà
      existing_inventory = variant.inventory
      expect(existing_inventory).to be_present
      duplicate = build(:inventory, product_variant: variant)
      expect(duplicate).to be_invalid
      expect(duplicate.errors[:product_variant_id]).to be_present
    end
  end

  describe '#available_qty' do
    it 'calculates available quantity correctly' do
      inventory.stock_qty = 20
      inventory.reserved_qty = 5
      expect(inventory.available_qty).to eq(15)
    end

    it 'returns 0 when stock_qty equals reserved_qty' do
      inventory.stock_qty = 10
      inventory.reserved_qty = 10
      expect(inventory.available_qty).to eq(0)
    end

    it 'handles negative available_qty gracefully' do
      inventory.stock_qty = 5
      inventory.reserved_qty = 10
      expect(inventory.available_qty).to eq(-5)
    end
  end

  describe '#move_stock' do
    let(:user) { create(:user) }

    it 'creates an inventory movement' do
      expect {
        inventory.move_stock(5, 'adjustment', 'REF-123', user)
      }.to change(InventoryMovement, :count).by(1)
    end

    it 'updates stock_qty correctly' do
      initial_stock = inventory.stock_qty
      inventory.move_stock(5, 'adjustment', 'REF-123', user)
      expect(inventory.reload.stock_qty).to eq(initial_stock + 5)
    end

    it 'records before_qty in movement' do
      before_qty = inventory.stock_qty
      inventory.move_stock(5, 'adjustment', 'REF-123', user)
      movement = inventory.movements.last
      expect(movement.before_qty).to eq(before_qty)
    end

    it 'handles negative quantities (outgoing stock)' do
      initial_stock = inventory.stock_qty
      inventory.move_stock(-3, 'loss', 'REF-456', user)
      expect(inventory.reload.stock_qty).to eq(initial_stock - 3)
    end
  end

  describe '#reserve_stock' do
    let(:user) { create(:user) }

    it 'increments reserved_qty' do
      initial_reserved = inventory.reserved_qty
      inventory.reserve_stock(5, 123, user)
      expect(inventory.reload.reserved_qty).to eq(initial_reserved + 5)
    end

    it 'creates a movement with reason "reserved"' do
      expect {
        inventory.reserve_stock(5, 123, user)
      }.to change(InventoryMovement, :count).by(1)

      movement = inventory.movements.last
      expect(movement.reason).to eq('reserved')
      expect(movement.reference).to eq('123')
    end
  end

  describe '#release_stock' do
    let(:user) { create(:user) }

    before do
      inventory.update(reserved_qty: 10)
    end

    it 'decrements reserved_qty' do
      initial_reserved = inventory.reserved_qty
      inventory.release_stock(5, 123, user)
      expect(inventory.reload.reserved_qty).to eq(initial_reserved - 5)
    end

    it 'creates a movement with reason "released"' do
      expect {
        inventory.release_stock(5, 123, user)
      }.to change(InventoryMovement, :count).by(1)

      movement = inventory.movements.last
      expect(movement.reason).to eq('released')
      expect(movement.reference).to eq('123')
    end
  end

  describe 'associations' do
    it 'belongs to product_variant' do
      expect(inventory.product_variant).to eq(variant)
    end

    it 'has many movements' do
      create(:inventory_movement, inventory: inventory)
      create(:inventory_movement, inventory: inventory)
      expect(inventory.movements.count).to eq(2)
    end

    it 'destroys movements when destroyed' do
      movement = create(:inventory_movement, inventory: inventory)
      inventory.destroy
      expect(InventoryMovement.find_by(id: movement.id)).to be_nil
    end
  end
end
