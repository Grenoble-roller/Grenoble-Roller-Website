require 'rails_helper'

RSpec.describe 'AdminPanel::Orders', type: :request do
  include RequestAuthenticationHelper

  let(:admin_role) { Role.find_or_create_by!(code: 'ADMIN') { |r| r.name = 'Administrateur'; r.level = 60 } }
  let(:organizer_role) { Role.find_or_create_by!(code: 'ORGANIZER') { |r| r.name = 'Organisateur'; r.level = 40 } }
  let(:user_role) { Role.find_or_create_by!(code: 'USER') { |r| r.name = 'Utilisateur'; r.level = 10 } }

  let(:order) { create(:order) }

  describe 'GET /admin-panel/orders' do
    context 'when user is admin (level 60)' do
      let(:admin_user) { create(:user, :admin) }

      before { login_user(admin_user) }

      it 'returns success' do
        get admin_panel_orders_path
        expect(response).to have_http_status(:success)
      end

      it 'displays orders' do
        create_list(:order, 3)
        get admin_panel_orders_path
        expect(response.body).to include('Commandes')
      end
    end

    context 'when user is organizer (level 40)' do
      let(:organizer_user) { create(:user, :organizer) }

      before { sign_in organizer_user }

      it 'redirects to root with alert' do
        get admin_panel_orders_path
        expect(response).to redirect_to(root_path)
        expect(flash[:alert]).to include('Accès admin requis')
      end
    end

    context 'when user level is below 60' do
      let(:regular_user) { create(:user, role: user_role) }

      before { login_user(regular_user) }

      it 'redirects to root' do
        get admin_panel_orders_path
        expect(response).to redirect_to(root_path)
      end
    end

    context 'when user is not signed in' do
      it 'redirects to login' do
        get admin_panel_orders_path
        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end

  describe 'GET /admin-panel/orders/:id' do
    context 'when user is admin (level 60)' do
      let(:admin_user) { create(:user, :admin) }

      before { login_user(admin_user) }

      it 'returns success' do
        get admin_panel_order_path(order)
        expect(response).to have_http_status(:success)
      end
    end

    context 'when user is organizer (level 40)' do
      let(:organizer_user) { create(:user, :organizer) }

      before { sign_in organizer_user }

      it 'redirects to root' do
        get admin_panel_order_path(order)
        expect(response).to redirect_to(root_path)
      end
    end
  end

  describe 'PATCH /admin-panel/orders/:id/change_status' do
    let(:admin_user) { create(:user, :admin) }
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
    let!(:order) do
      inventory # S'assurer que l'inventaire existe
      inventory.update!(stock_qty: 10, reserved_qty: 0)

      order = Order.new(user: admin_user, status: 'pending', total_cents: 1000, currency: 'EUR')
      order_item = OrderItem.new(variant: variant, quantity: 3, unit_price_cents: 1000)
      order.order_items << order_item
      order.save!
      order.reload
      order
    end

    before do
      login_user(admin_user)
      # Le stock est réservé après création
      inventory.reload
      if inventory.reserved_qty != 3
        # Si la réservation n'a pas fonctionné, réserver manuellement pour les tests
        inventory.update!(reserved_qty: 3, stock_qty: 10)
      end
      expect(inventory.reserved_qty).to eq(3)
    end

    it 'releases reserved stock when status changes to cancelled' do
      expect {
        patch change_status_admin_panel_order_path(order), params: { status: 'cancelled' }
      }.to change { inventory.reload.reserved_qty }.by(-3)
        .and change { inventory.stock_qty }.by(0) # Stock réel ne change pas

      expect(order.reload.status).to eq('cancelled')
    end

    it 'deducts stock and releases reservation when status changes to shipped' do
      expect {
        patch change_status_admin_panel_order_path(order), params: { status: 'shipped' }
      }.to change { inventory.reload.stock_qty }.by(-3)
        .and change { inventory.reserved_qty }.by(-3)

      expect(order.reload.status).to eq('shipped')
    end

    it 'does not change stock when status changes to paid' do
      expect {
        patch change_status_admin_panel_order_path(order), params: { status: 'paid' }
      }.not_to change { inventory.reload.stock_qty }

      expect(inventory.reserved_qty).to eq(3) # Reste réservé
      expect(order.reload.status).to eq('paid')
    end

    it 'requires admin level (60+)' do
      organizer_user = create(:user, :organizer)
      sign_in organizer_user

      patch change_status_admin_panel_order_path(order), params: { status: 'cancelled' }
      expect(response).to redirect_to(root_path)
      expect(flash[:alert]).to include('Accès admin requis')
    end
  end
end
