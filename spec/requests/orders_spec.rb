require 'rails_helper'

RSpec.describe 'Orders', type: :request do
  include RequestAuthenticationHelper

  let(:role) { ensure_role(code: 'USER', name: 'Utilisateur', level: 10) }
  let(:user) do
    user = build(:user, role: role)
    user.skip_confirmation!
    user.save!
    user
  end
  let(:category) { create(:product_category) }
  let(:product) { create(:product, category: category) }
  let(:variant) do
    v = create(:product_variant, product: product, stock_qty: 10, is_active: true)
    # S'assurer que l'inventaire existe et a du stock
    inv = v.inventory || Inventory.create!(product_variant: v, stock_qty: 10, reserved_qty: 0)
    inv.update!(stock_qty: 10, reserved_qty: 0)
    v.reload
    v
  end

  describe 'GET /orders/new' do
    it 'requires authentication' do
      get new_order_path
      expect(response).to redirect_to(new_user_session_path)
    end

    it 'redirects authenticated users to unified checkout' do
      login_user(user)
      get new_order_path
      expect(response).to redirect_to(new_checkout_path)
    end
  end

  describe 'POST /orders' do
    it 'requires authentication' do
      post orders_path
      expect(response).to redirect_to(new_user_session_path)
    end

    it 'redirects authenticated users to unified checkout' do
      login_user(user)
      post orders_path
      expect(response).to redirect_to(new_checkout_path)
    end
  end

  describe 'POST /orders/:order_id/payments' do
    let(:order) { create(:order, user: user, status: 'pending') }

    it 'requires authentication' do
      post order_payments_path(order)
      expect(response).to redirect_to(new_user_session_path)
    end

    it 'redirects to HelloAsso for pending order' do
      login_user(user)
      # Mock HelloAssoService pour éviter les appels réels
      allow(HelloassoService).to receive(:create_checkout_intent).and_return({
        success: true,
        body: {
          "id" => "checkout_123",
          "redirectUrl" => "https://helloasso.com/checkout"
        }
      })

      post order_payments_path(order)
      expect(response).to have_http_status(:redirect)
    end

    it 'blocks legacy checkout-intent when an open unified checkout exists' do
      login_user(user)
      create(:checkout, user: user, status: :pending, metadata: { 'order_id' => order.id.to_s })

      expect(HelloassoService).not_to receive(:create_checkout_intent)

      post order_payments_path(order)

      expect(response).to redirect_to(new_checkout_path)
      expect(flash[:alert]).to match(/panier unifié/i)
    end
  end

  describe 'GET /orders/:order_id/payments/status' do
    let(:order) { create(:order, user: user) }

    it 'requires authentication' do
      get status_order_payments_path(order)
      expect(response).to redirect_to(new_user_session_path)
    end

    it 'returns payment status as JSON' do
      login_user(user)
      get status_order_payments_path(order)
      expect(response).to have_http_status(:success)
      expect(response.content_type).to include('application/json')
      json = JSON.parse(response.body)
      expect(json).to have_key('status')
    end
  end

  describe 'GET /orders/:id' do
    let(:order) { create(:order, user: user) }

    it 'requires authentication' do
      get order_path(order)
      expect(response).to redirect_to(new_user_session_path)
    end

    it 'allows user to view their own order' do
      login_user(user)
      get order_path(order)
      expect(response).to have_http_status(:success)
      expect(response.body).to include(order.id.to_s)
    end

    it 'prevents user from viewing another user\'s order' do
      other_user = create(:user, role: role, confirmed_at: Time.current)
      other_order = create(:order, user: other_user)
      login_user(user)

      # Le contrôleur doit retourner 404 si la commande n'appartient pas à l'utilisateur
      # Utiliser hashid pour accéder à la commande
      get order_path(other_order.hashid)

      # Rails intercepte RecordNotFound et retourne 404
      expect(response).to have_http_status(:not_found)
    end

    it 'loads order with payment and order_items' do
      variant = create(:product_variant, product: product, stock_qty: 10)
      order = create(:order, user: user)
      create(:order_item, order: order, variant: variant, quantity: 2)
      login_user(user)

      get order_path(order)
      expect(response).to have_http_status(:success)
      # Vérifier que les associations sont chargées (pas de N+1)
      expect(assigns(:order).association(:payment).loaded?).to be true
      expect(assigns(:order).association(:order_items).loaded?).to be true
    end
  end

  describe 'PATCH /orders/:id/cancel' do
    let(:order) { create(:order, user: user, status: 'pending') }

    it 'requires authentication' do
      patch cancel_order_path(order)
      expect(response).to redirect_to(new_user_session_path)
    end

    context 'when authenticated' do
      before { login_user(user) }

      it 'cancels a pending order and redirects with notice' do
        patch cancel_order_path(order)
        expect(response).to redirect_to(order_path(order))
        expect(flash[:notice]).to include('annulée')
        expect(order.reload.status).to eq('cancelled')
      end

      it 'prevents cancelling another user order' do
        other_user = create(:user, role: role, confirmed_at: Time.current)
        other_order = create(:order, user: other_user, status: 'pending')
        patch cancel_order_path(other_order)
        expect(response).to have_http_status(:not_found)
      end
    end
  end

  describe 'POST /orders/:id/check_payment' do
    let(:order) { create(:order, user: user) }

    it 'requires authentication' do
      post check_payment_order_path(order)
      expect(response).to redirect_to(new_user_session_path)
    end

    context 'when authenticated' do
      before { login_user(user) }

      it 'redirects to order page' do
        post check_payment_order_path(order)
        expect(response).to redirect_to(order_path(order))
      end
    end
  end
end
