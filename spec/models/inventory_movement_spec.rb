# frozen_string_literal: true

require 'rails_helper'

RSpec.describe InventoryMovement, type: :model do
  let(:product) { create(:product) }
  let(:variant) { create(:product_variant, product: product) }
  let(:inventory) { variant.inventory }
  let(:user) { create(:user) }
  let(:movement) { build(:inventory_movement, inventory: inventory, user: user) }

  describe 'validations' do
    it 'is valid with valid attributes' do
      expect(movement).to be_valid
    end

    it 'requires quantity' do
      movement.quantity = nil
      expect(movement).to be_invalid
      expect(movement.errors[:quantity]).to be_present
    end

    it 'requires reason' do
      movement.reason = nil
      expect(movement).to be_invalid
      expect(movement.errors[:reason]).to be_present
    end

    it 'validates reason inclusion' do
      movement.reason = 'invalid_reason'
      expect(movement).to be_invalid
      expect(movement.errors[:reason]).to be_present
    end

    it 'accepts valid reasons' do
      InventoryMovement::REASONS.each do |reason|
        movement.reason = reason
        expect(movement).to be_valid, "Reason #{reason} should be valid"
      end
    end
  end

  describe 'associations' do
    it 'belongs to inventory' do
      expect(movement.inventory).to eq(inventory)
    end

    it 'belongs to user (optional)' do
      movement.user = nil
      expect(movement).to be_valid
    end

    it 'can have a user' do
      movement.user = user
      expect(movement.user).to eq(user)
    end
  end

  describe 'scopes' do
    let!(:old_movement) { create(:inventory_movement, inventory: inventory, created_at: 2.days.ago) }
    let!(:recent_movement) { create(:inventory_movement, inventory: inventory, created_at: 1.hour.ago) }

    it 'orders by recent first' do
      movements = InventoryMovement.recent
      expect(movements.first).to eq(recent_movement)
      expect(movements.last).to eq(old_movement)
    end

    it 'filters by reason' do
      adjustment = create(:inventory_movement, inventory: inventory, reason: 'adjustment')
      purchase = create(:inventory_movement, inventory: inventory, reason: 'purchase')

      adjustments = InventoryMovement.by_reason('adjustment')
      expect(adjustments).to include(adjustment)
      expect(adjustments).not_to include(purchase)
    end
  end

  describe 'ransackable attributes' do
    it 'includes expected attributes' do
      expect(InventoryMovement.ransackable_attributes).to include('id', 'inventory_id', 'user_id', 'quantity', 'reason', 'reference', 'created_at')
    end
  end

  describe 'ransackable associations' do
    it 'includes expected associations' do
      expect(InventoryMovement.ransackable_associations).to include('inventory', 'user')
    end
  end
end
