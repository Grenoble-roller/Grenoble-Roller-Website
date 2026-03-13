require 'rails_helper'

RSpec.describe RollerStock, type: :model do
  describe 'validations' do
    it 'validates presence of size' do
      stock = build(:roller_stock, size: nil)
      expect(stock).not_to be_valid
      expect(stock.errors[:size]).to be_present
    end

    it 'validates uniqueness of size' do
      create(:roller_stock, size: '38')
      duplicate = build(:roller_stock, size: '38')
      expect(duplicate).not_to be_valid
      expect(duplicate.errors[:size]).to be_present
    end

    it 'validates size is in SIZES' do
      stock = build(:roller_stock, size: '99')
      expect(stock).not_to be_valid
      expect(stock.errors[:size]).to be_present
    end

    it 'validates presence and numericality of quantity' do
      stock = build(:roller_stock, quantity: nil)
      expect(stock).not_to be_valid
      expect(stock.errors[:quantity]).to be_present

      stock = build(:roller_stock, quantity: -1)
      expect(stock).not_to be_valid
      expect(stock.errors[:quantity]).to be_present
    end

    it 'validates is_active is boolean' do
      stock = build(:roller_stock, is_active: nil)
      expect(stock).not_to be_valid
      expect(stock.errors[:is_active]).to be_present
    end
  end

  describe 'scopes' do
    describe '.active' do
      it 'returns only active records' do
        active = create(:roller_stock, is_active: true, size: '38')
        create(:roller_stock, is_active: false, size: '39')
        expect(described_class.active).to contain_exactly(active)
      end
    end

    describe '.available' do
      it 'returns active with quantity > 0' do
        avail = create(:roller_stock, is_active: true, quantity: 2, size: '38')
        create(:roller_stock, is_active: true, quantity: 0, size: '39')
        create(:roller_stock, is_active: false, quantity: 1, size: '40')
        expect(described_class.available).to contain_exactly(avail)
      end
    end
  end

  describe '#available?' do
    it 'returns true when active and quantity > 0' do
      stock = build(:roller_stock, is_active: true, quantity: 1)
      expect(stock.available?).to be true
    end

    it 'returns false when inactive' do
      stock = build(:roller_stock, is_active: false, quantity: 1)
      expect(stock.available?).to be false
    end

    it 'returns false when quantity is 0' do
      stock = build(:roller_stock, is_active: true, quantity: 0)
      expect(stock.available?).to be false
    end
  end

  describe '#out_of_stock?' do
    it 'returns true when quantity <= 0' do
      expect(build(:roller_stock, quantity: 0).out_of_stock?).to be true
      expect(build(:roller_stock, quantity: 1).out_of_stock?).to be false
    end
  end

  describe '#size_with_stock' do
    it 'returns size with singular "disponible" when quantity is 1' do
      stock = build(:roller_stock, size: '38', quantity: 1)
      expect(stock.size_with_stock).to eq('38 (1 disponible)')
    end

    it 'returns size with plural "disponibles" when quantity > 1' do
      stock = build(:roller_stock, size: '38', quantity: 3)
      expect(stock.size_with_stock).to eq('38 (3 disponibles)')
    end
  end
end
