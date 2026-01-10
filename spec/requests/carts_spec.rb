# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Carts', type: :request do
  let(:category) { create(:product_category) }
  let(:product) { create(:product, category: category) }
  let(:variant) do
    v = create(:product_variant, product: product, stock_qty: 10, price_cents: 2000, is_active: true)
    # S'assurer que l'inventaire existe et a du stock
    inv = v.inventory || Inventory.create!(product_variant: v, stock_qty: 10, reserved_qty: 0)
    inv.update!(stock_qty: 10, reserved_qty: 0)
    v.reload
    v
  end

  describe 'GET /cart' do
    it 'allows public access without authentication' do
      get cart_path
      expect(response).to have_http_status(:success)
    end

    it 'displays empty cart correctly' do
      get cart_path
      expect(response).to have_http_status(:success)
      # Vérifier que le panier est vide (total = 0)
      expect(assigns(:total_cents)).to eq(0)
      expect(assigns(:cart_items)).to be_empty
    end

    it 'displays cart items when cart has items' do
      # S'assurer que le variant a un inventaire avec du stock
      variant.inventory || Inventory.create!(product_variant: variant, stock_qty: 10, reserved_qty: 0)
      post add_item_cart_path, params: { variant_id: variant.id, quantity: 2 }
      # Vérifier que le panier n'est pas vide
      expect(session[:cart]).to be_present

      get cart_path

      expect(response).to have_http_status(:success)
      expect(assigns(:cart_items)).to be_present
      # Vérifier que le produit est dans les cart_items
      cart_item = assigns(:cart_items).find { |ci| ci[:variant].id == variant.id }
      expect(cart_item).to be_present
      expect(cart_item[:variant].product.name).to eq(product.name)
    end

    it 'calculates total correctly' do
      variant2 = create(:product_variant, product: product, stock_qty: 10, price_cents: 3000, is_active: true)
      # S'assurer que les variants ont des inventaires
      variant.inventory || Inventory.create!(product_variant: variant, stock_qty: 10, reserved_qty: 0)
      variant2.inventory || Inventory.create!(product_variant: variant2, stock_qty: 10, reserved_qty: 0)

      post add_item_cart_path, params: { variant_id: variant.id, quantity: 2 }
      post add_item_cart_path, params: { variant_id: variant2.id, quantity: 1 }

      get cart_path

      expect(response).to have_http_status(:success)
      # Total attendu : (2000 * 2) + (3000 * 1) = 7000 cents = 70.00 EUR
      expect(assigns(:total_cents)).to eq(7000)
    end

    it 'displays cart items with correct quantities' do
      # S'assurer que le variant a un inventaire avec du stock
      variant.inventory || Inventory.create!(product_variant: variant, stock_qty: 10, reserved_qty: 0)
      post add_item_cart_path, params: { variant_id: variant.id, quantity: 3 }
      # Vérifier que le panier n'est pas vide
      expect(session[:cart]).to be_present

      get cart_path

      expect(response).to have_http_status(:success)
      cart_item = assigns(:cart_items).find { |ci| ci[:variant].id == variant.id }
      expect(cart_item).to be_present
      expect(cart_item[:quantity]).to eq(3)
      expect(cart_item[:subtotal_cents]).to eq(6000) # 2000 * 3
    end
  end

  describe 'POST /cart/add_item - Stock management with Inventories' do
    let(:category) { create(:product_category) }
    let(:product) { create(:product, category: category) }
    let(:variant) do
      v = create(:product_variant, product: product, stock_qty: 10, is_active: true)
      # S'assurer que l'inventaire existe et a les bonnes valeurs
      inv = v.inventory || Inventory.create!(product_variant: v, stock_qty: 10, reserved_qty: 0)
      inv.update!(stock_qty: 10, reserved_qty: 0)
      v.reload
      v
    end
    let(:inventory) { variant.inventory }

    before do
      inventory # Créer l'inventaire
    end

    it 'uses available_qty (stock_qty - reserved_qty) to check stock' do
      # Réserver 5 unités
      inventory.update!(reserved_qty: 5)
      # available_qty = 10 - 5 = 5

      # Essayer d'ajouter 6 unités (plus que disponible)
      post add_item_cart_path, params: { variant_id: variant.id, quantity: 6 }

      expect(response).to redirect_to(shop_path)
      expect(flash[:alert]).to include('Stock insuffisant')
    end

    it 'allows adding items up to available_qty' do
      # Réserver 5 unités
      inventory.update!(reserved_qty: 5)
      # available_qty = 10 - 5 = 5

      # Ajouter 5 unités (exactement disponible)
      post add_item_cart_path, params: { variant_id: variant.id, quantity: 5 }

      expect(response).to redirect_to(shop_path)
      expect(flash[:notice]).to be_present
    end

    it 'caps quantity to available_qty when adding more' do
      # Réserver 7 unités
      inventory.update!(reserved_qty: 7)
      # available_qty = 10 - 7 = 3

      # Essayer d'ajouter 5 unités, mais seulement 3 disponibles
      post add_item_cart_path, params: { variant_id: variant.id, quantity: 5 }

      expect(response).to redirect_to(shop_path)
      expect(flash[:alert]).to include('Stock insuffisant')
    end

    it 'falls back to stock_qty if inventory does not exist' do
      # Pas d'inventaire créé
      variant_without_inventory = create(:product_variant, product: product, stock_qty: 5, is_active: true)

      post add_item_cart_path, params: { variant_id: variant_without_inventory.id, quantity: 3 }

      expect(response).to redirect_to(shop_path)
      expect(flash[:notice]).to be_present
    end
  end

  describe 'PATCH /cart/update_item - Stock management with Inventories' do
    let(:category) { create(:product_category) }
    let(:product) { create(:product, category: category) }
    let(:variant) do
      v = create(:product_variant, product: product, stock_qty: 10, is_active: true)
      # S'assurer que l'inventaire existe et a les bonnes valeurs
      inv = v.inventory || Inventory.create!(product_variant: v, stock_qty: 10, reserved_qty: 0)
      inv.update!(stock_qty: 10, reserved_qty: 0)
      v.reload
      v
    end
    let(:inventory) { variant.inventory }

    before do
      inventory # Créer l'inventaire
      # Ajouter un item au panier
      post add_item_cart_path, params: { variant_id: variant.id, quantity: 2 }
    end

    it 'uses available_qty to cap quantity' do
      # Réserver 7 unités
      inventory.update!(reserved_qty: 7)
      # available_qty = 10 - 7 = 3

      # Essayer de mettre à jour à 5 unités, mais seulement 3 disponibles
      patch update_item_cart_path, params: { variant_id: variant.id, quantity: 5 }

      expect(response).to redirect_to(cart_path)
      expect(flash[:alert]).to include('Quantité ajustée au stock disponible (3)')
    end

    it 'allows updating to available_qty' do
      # Réserver 5 unités
      inventory.update!(reserved_qty: 5)
      # available_qty = 10 - 5 = 5

      patch update_item_cart_path, params: { variant_id: variant.id, quantity: 5 }

      expect(response).to redirect_to(cart_path)
      expect(flash[:notice]).to include('Panier mis à jour')
    end
  end
end
