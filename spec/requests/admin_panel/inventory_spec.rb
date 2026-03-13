# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'AdminPanel::InventoryController', type: :request do
  let(:admin_role) { Role.find_or_create_by!(code: 'ADMIN') { |r| r.name = 'Administrateur'; r.level = 60 } }
  let(:admin_user) { create(:user, role: admin_role) }
  let(:organizer_role) { Role.find_or_create_by!(code: 'ORGANIZER') { |r| r.name = 'Organisateur'; r.level = 40 } }
  let(:organizer_user) { create(:user, role: organizer_role) }

  describe 'GET /admin-panel/inventory' do
    context 'when user is admin' do
      before { sign_in admin_user }

      it 'returns success' do
        get admin_panel_inventory_path
        expect(response).to have_http_status(:success)
      end

      it 'assigns @low_stock' do
        variant = create(:product_variant)
        inventory = create(:inventory, product_variant: variant, stock_qty: 5, reserved_qty: 0)

        get admin_panel_inventory_path
        expect(assigns(:low_stock)).to be_present
      end

      it 'assigns @out_of_stock' do
        variant = create(:product_variant)
        inventory = create(:inventory, product_variant: variant, stock_qty: 0, reserved_qty: 0)

        get admin_panel_inventory_path
        expect(assigns(:out_of_stock)).to be_present
      end

      it 'assigns @movements' do
        variant = create(:product_variant)
        inventory = create(:inventory, product_variant: variant)
        create(:inventory_movement, inventory: inventory)

        get admin_panel_inventory_path
        expect(assigns(:movements)).to be_present
      end
    end

    context 'when user is organizer (level 40)' do
      before { sign_in organizer_user }

      it 'redirects or denies access' do
        get admin_panel_inventory_path
        expect(response).to have_http_status(:redirect)
      end
    end

    context 'when user is not signed in' do
      it 'redirects to login' do
        get admin_panel_inventory_path
        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end

  describe 'GET /admin-panel/inventory/transfers' do
    context 'when user is admin' do
      before { sign_in admin_user }

      it 'returns success' do
        get admin_panel_inventory_transfers_path
        expect(response).to have_http_status(:success)
      end

      it 'assigns @movements with pagination' do
        variant = create(:product_variant)
        inventory = create(:inventory, product_variant: variant)
        create_list(:inventory_movement, 5, inventory: inventory)

        get admin_panel_inventory_transfers_path
        expect(assigns(:movements)).to be_present
        expect(assigns(:pagy)).to be_present
      end

      it 'filters movements by reason' do
        variant = create(:product_variant)
        inventory = create(:inventory, product_variant: variant)
        create(:inventory_movement, inventory: inventory, reason: 'adjustment')
        create(:inventory_movement, inventory: inventory, reason: 'purchase')

        get admin_panel_inventory_transfers_path, params: { q: { reason_cont: 'adjustment' } }
        movements = assigns(:movements)
        expect(movements.all? { |m| m.reason == 'adjustment' }).to be(true)
      end
    end

    context 'when user is organizer (level 40)' do
      before { sign_in organizer_user }

      it 'redirects or denies access' do
        get admin_panel_inventory_transfers_path
        expect(response).to have_http_status(:redirect)
      end
    end
  end

  describe 'PATCH /admin-panel/inventory/adjust_stock' do
    let(:product) { create(:product) }
    let(:variant) { create(:product_variant, product: product) }
    let!(:inventory) { create(:inventory, product_variant: variant, stock_qty: 10) }

    context 'when user is admin' do
      before { sign_in admin_user }

      it 'adjusts stock successfully' do
        expect {
          patch '/admin-panel/inventory/adjust_stock', params: {
            variant_id: variant.id,
            quantity: 5,
            reason: 'adjustment',
            reference: 'REF-123'
          }
        }.to change { inventory.reload.stock_qty }.by(5)
          .and change(InventoryMovement, :count).by(1)

        expect(response).to redirect_to(admin_panel_inventory_path)
        expect(flash[:notice]).to be_present
      end

      it 'handles negative quantities' do
        expect {
          patch '/admin-panel/inventory/adjust_stock', params: {
            variant_id: variant.id,
            quantity: -3,
            reason: 'loss',
            reference: 'REF-456'
          }
        }.to change { inventory.reload.stock_qty }.by(-3)
      end

      it 'rejects zero quantity' do
        patch '/admin-panel/inventory/adjust_stock', params: {
          variant_id: variant.id,
          quantity: 0,
          reason: 'adjustment'
        }

        expect(response).to redirect_to(admin_panel_inventory_path)
        expect(flash[:alert]).to be_present
      end
    end

    context 'when user is organizer (level 40)' do
      before { sign_in organizer_user }

      it 'redirects or denies access' do
        patch '/admin-panel/inventory/adjust_stock', params: {
          variant_id: variant.id,
          quantity: 5,
          reason: 'adjustment'
        }
        expect(response).to have_http_status(:redirect)
      end
    end
  end
end
