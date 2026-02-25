# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'AdminPanel::Payments', type: :request do
  include RequestAuthenticationHelper

  let(:admin_role) { Role.find_or_create_by!(code: 'ADMIN') { |r| r.name = 'Administrateur'; r.level = 60 } }
  let(:organizer_role) { Role.find_or_create_by!(code: 'ORGANIZER') { |r| r.name = 'Organisateur'; r.level = 40 } }

  describe 'GET /admin-panel/payments' do
    context 'when user is admin (level 60)' do
      let(:admin_user) { create(:user, :admin) }

      before do
        login_user(admin_user)
      end

      it 'returns success' do
        get admin_panel_payments_path
        expect(response).to have_http_status(:success)
      end

      it 'displays payments' do
        create_list(:payment, 3)
        get admin_panel_payments_path
        expect(response.body).to include('Paiements')
      end

      it 'filters by provider' do
        payment1 = create(:payment, provider: 'helloasso')
        payment2 = create(:payment, provider: 'stripe')

        get admin_panel_payments_path, params: { q: { provider_eq: 'helloasso' } }

        expect(response).to have_http_status(:success)
        # Vérifier que le filtre est appliqué (les IDs peuvent ne pas être dans le body si pagination)
        expect(@controller.instance_variable_get(:@payments)).to include(payment1)
        expect(@controller.instance_variable_get(:@payments)).not_to include(payment2)
      end

      it 'filters by status' do
        payment1 = create(:payment, status: 'completed')
        payment2 = create(:payment, status: 'pending')

        get admin_panel_payments_path, params: { q: { status_eq: 'completed' } }

        expect(response).to have_http_status(:success)
        # Vérifier que le filtre est appliqué
        expect(@controller.instance_variable_get(:@payments)).to include(payment1)
        expect(@controller.instance_variable_get(:@payments)).not_to include(payment2)
      end
    end

    context 'when user is organizer (level 40)' do
      let(:organizer_user) { create(:user, :organizer) }

      before do
        login_user(organizer_user)
      end

      it 'redirects to root with alert' do
        get admin_panel_payments_path
        expect(response).to redirect_to(root_path)
        expect(flash[:alert]).to include('Accès admin requis')
      end
    end

    context 'when user is not signed in' do
      it 'redirects to login' do
        get admin_panel_payments_path
        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end

  describe 'GET /admin-panel/payments/:id' do
    context 'when user is admin (level 60)' do
      let(:admin_user) { create(:user, :admin) }
      let(:payment) { create(:payment) }

      before do
        login_user(admin_user)
      end

      it 'returns success' do
        get admin_panel_payment_path(payment)
        expect(response).to have_http_status(:success)
      end

      it 'displays payment details' do
        get admin_panel_payment_path(payment)
        expect(response.body).to include("Paiement ##{payment.id}")
        expect(response.body).to include(payment.provider)
      end

      it 'displays associated orders' do
        order = create(:order, payment: payment)
        get admin_panel_payment_path(payment)
        expect(response.body).to include("##{order.id}")
      end

      it 'displays associated memberships' do
        membership = create(:membership, payment: payment)
        get admin_panel_payment_path(payment)
        expect(response.body).to include("##{membership.id}")
      end

      it 'displays associated attendances' do
        attendance = create(:attendance, payment: payment)
        get admin_panel_payment_path(payment)
        expect(response.body).to include("##{attendance.id}")
      end
    end

    context 'when user is organizer (level 40)' do
      let(:organizer_user) { create(:user, :organizer) }
      let(:payment) { create(:payment) }

      before do
        login_user(organizer_user)
      end

      it 'redirects to root with alert' do
        get admin_panel_payment_path(payment)
        expect(response).to redirect_to(root_path)
        expect(flash[:alert]).to include('Accès admin requis')
      end
    end

    context 'when user is not signed in' do
      let(:payment) { create(:payment) }

      it 'redirects to login' do
        get admin_panel_payment_path(payment)
        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end

  describe 'DELETE /admin-panel/payments/:id' do
    context 'when user is superadmin (level 70)' do
      let(:superadmin_role) { Role.find_or_create_by!(code: 'SUPERADMIN') { |r| r.name = 'Super Administrateur'; r.level = 70 } }
      let(:superadmin_user) { create(:user, role: superadmin_role) }
      let!(:payment) { create(:payment) }

      before do
        login_user(superadmin_user)
      end

      it 'deletes the payment' do
        expect {
          delete admin_panel_payment_path(payment)
        }.to change(Payment, :count).by(-1)
      end

      it 'redirects to payments index' do
        delete admin_panel_payment_path(payment)
        expect(response).to redirect_to(admin_panel_payments_path)
      end

      it 'shows success message' do
        delete admin_panel_payment_path(payment)
        expect(flash[:notice]).to include('supprimé avec succès')
      end
    end

    context 'when user is admin (level 60)' do
      let(:admin_user) { create(:user, :admin) }
      let!(:payment) { create(:payment) }

      before do
        login_user(admin_user)
      end

      it 'redirects to admin panel root with alert' do
        delete admin_panel_payment_path(payment)
        expect(response).to redirect_to(admin_panel_root_path)
        expect(flash[:alert]).to include('pas autorisé')
      end

      it 'does not delete the payment' do
        expect {
          delete admin_panel_payment_path(payment)
        }.not_to change(Payment, :count)
      end
    end

    context 'when user is organizer (level 40)' do
      let(:organizer_user) { create(:user, :organizer) }
      let!(:payment) { create(:payment) }

      before do
        login_user(organizer_user)
      end

      it 'redirects to root with alert' do
        delete admin_panel_payment_path(payment)
        expect(response).to redirect_to(root_path)
        expect(flash[:alert]).to include('Accès admin requis')
      end

      it 'does not delete the payment' do
        expect {
          delete admin_panel_payment_path(payment)
        }.not_to change(Payment, :count)
      end
    end

    context 'when user is not signed in' do
      let!(:payment) { create(:payment) }

      it 'redirects to login' do
        delete admin_panel_payment_path(payment)
        expect(response).to redirect_to(new_user_session_path)
      end

      it 'does not delete the payment' do
        expect {
          delete admin_panel_payment_path(payment)
        }.not_to change(Payment, :count)
      end
    end
  end
end
