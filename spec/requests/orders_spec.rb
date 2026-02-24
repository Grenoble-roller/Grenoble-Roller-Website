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

    context 'with cart items' do
      before do
        login_user(user)
        # S'assurer que le variant a un inventaire avec du stock
        variant.inventory || Inventory.create!(product_variant: variant, stock_qty: 10, reserved_qty: 0)
        # Simuler un panier avec des items
        post add_item_cart_path, params: { variant_id: variant.id, quantity: 1 }
        # Vérifier que le panier n'est pas vide après l'ajout
        expect(session[:cart]).to be_present
        expect(session[:cart][variant.id.to_s]).to eq(1)
      end

      it 'allows authenticated confirmed user to access checkout' do
        get new_order_path
        expect(response).to have_http_status(:ok)
      end

      it 'allows unconfirmed users to view checkout (but blocks on create)' do
        logout_user
        unconfirmed_user = create(:user, :unconfirmed, role: role)
        login_user(unconfirmed_user)

        # S'assurer que le variant a un inventaire avec du stock
        variant.inventory || Inventory.create!(product_variant: variant, stock_qty: 10, reserved_qty: 0)
        # Ajouter au panier pour l'utilisateur non confirmé
        post add_item_cart_path, params: { variant_id: variant.id, quantity: 1 }
        # Vérifier que le panier n'est pas vide
        expect(session[:cart]).to be_present

        # GET /orders/new n'a pas de blocage email (seulement POST /orders)
        get new_order_path
        expect(response).to have_http_status(:ok)
      end
    end
  end

  describe 'POST /orders' do
    before do
      login_user(user)
      # S'assurer que le variant a un inventaire avec du stock
      variant.inventory || Inventory.create!(product_variant: variant, stock_qty: 10, reserved_qty: 0)
      # Simuler un panier avec des items
      post add_item_cart_path, params: { variant_id: variant.id, quantity: 1 }
      # Vérifier que le panier n'est pas vide
      expect(session[:cart]).to be_present
    end

    it 'requires authentication' do
      logout_user
      post orders_path
      expect(response).to redirect_to(new_user_session_path)
    end

    it 'allows confirmed user to create an order' do
      # Mock HelloAsso pour éviter les appels réels
      allow(HelloassoService).to receive(:create_checkout_intent).and_return({
        success: true,
        body: {
          "id" => "checkout_123",
          "redirectUrl" => "https://helloasso.com/checkout"
        }
      })

      expect {
        post orders_path
      }.to change(Order, :count).by(1)

      expect(response).to have_http_status(:redirect)
      expect(Order.last.user).to eq(user)
    end

    it 'blocks unconfirmed users from creating an order' do
      logout_user
      # Créer un utilisateur non confirmé sans utiliser skip_confirmation!
      unconfirmed_user = create(:user, :unconfirmed, role: role)
      # S'assurer que confirmed_at est nil et recharger
      unconfirmed_user.update_column(:confirmed_at, nil)
      unconfirmed_user.reload
      # Vérifier que confirmed? retourne false
      expect(unconfirmed_user.confirmed?).to be false
      expect(unconfirmed_user.confirmed_at).to be_nil

      # Se connecter SANS confirmer l'utilisateur (confirm_user: false)
      login_user(unconfirmed_user, confirm_user: false)

      # Vérifier que l'utilisateur dans la DB a toujours confirmed_at à nil
      db_user = User.find(unconfirmed_user.id)
      expect(db_user.confirmed_at).to be_nil

      # S'assurer que le variant a un inventaire avec du stock
      variant.inventory || Inventory.create!(product_variant: variant, stock_qty: 10, reserved_qty: 0)
      # Ajouter au panier pour l'utilisateur non confirmé
      post add_item_cart_path, params: { variant_id: variant.id, quantity: 1 }
      # Vérifier que le panier n'est pas vide
      expect(session[:cart]).to be_present

      # OrdersController override ensure_email_confirmed pour bloquer même en test
      expect {
        post orders_path
      }.not_to change(Order, :count)

      # Vérifier que l'utilisateur est redirigé avec un message d'erreur
      expect(response).to redirect_to(root_path)
      expect(flash[:alert]).to include('confirmer votre adresse email')
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

  describe 'POST /orders - Stock reservation' do
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
      login_user(user)
      inventory # S'assurer que l'inventaire existe
      inventory.update!(stock_qty: 10, reserved_qty: 0)
      # Simuler un panier avec des items
      post add_item_cart_path, params: { variant_id: variant.id, quantity: 3 }
      # Vérifier que le panier n'est pas vide
      expect(session[:cart]).to be_present
      expect(session[:cart][variant.id.to_s]).to eq(3)
    end

    it 'reserves stock when order is created' do
      # Mock HelloAsso pour éviter les appels réels
      allow(HelloassoService).to receive(:create_checkout_intent).and_return({
        success: true,
        body: {
          "id" => "checkout_123",
          "redirectUrl" => "https://helloasso.com/checkout"
        }
      })

      expect {
        post orders_path
      }.to change { inventory.reload.reserved_qty }.by(3)
        .and change { inventory.stock_qty }.by(0) # Stock réel ne change pas
    end

    it 'checks available stock before creating order' do
      # Réserver tout le stock disponible (available_qty = 10 - 10 = 0)
      inventory.update!(stock_qty: 10, reserved_qty: 10)

      # Mock HelloAsso pour éviter les appels réels (ne sera pas appelé car la commande ne sera pas créée)
      allow(HelloassoService).to receive(:create_checkout_intent).and_return({
        success: true,
        body: {
          "id" => "checkout_123",
          "redirectUrl" => "https://helloasso.com/checkout"
        }
      })

      expect {
        post orders_path
      }.not_to change { Order.count }

      expect(response).to redirect_to(cart_path)
      expect(flash[:alert]).to include('Stock insuffisant')
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
