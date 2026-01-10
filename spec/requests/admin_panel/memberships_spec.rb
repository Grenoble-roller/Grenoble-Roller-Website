require 'rails_helper'

RSpec.describe 'AdminPanel::Memberships', type: :request do
  include RequestAuthenticationHelper

  let(:admin_role) { Role.find_or_create_by!(code: 'ADMIN') { |r| r.name = 'Administrateur'; r.level = 60 } }
  let(:organizer_role) { Role.find_or_create_by!(code: 'ORGANIZER') { |r| r.name = 'Organisateur'; r.level = 40 } }
  let(:user_role) { Role.find_or_create_by!(code: 'USER') { |r| r.name = 'Utilisateur'; r.level = 10 } }

  let(:target_user) { create(:user) }
  let(:target_membership) { create(:membership, user: target_user) }

  describe 'GET /admin-panel/memberships' do
    context 'when user is admin (level 60)' do
      let(:admin_user) { create(:user, :admin) }

      before { login_user(admin_user) }

      it 'returns success' do
        get admin_panel_memberships_path
        expect(response).to have_http_status(:success)
      end

      it 'displays memberships' do
        create_list(:membership, 3)
        get admin_panel_memberships_path
        expect(response.body).to include('Adhésions')
      end
    end

    context 'when user is organizer (level 40)' do
      let(:organizer_user) { create(:user, :organizer) }

      before { login_user(organizer_user) }

      it 'redirects to root with alert' do
        get admin_panel_memberships_path
        expect(response).to redirect_to(root_path)
        expect(flash[:alert]).to include('Accès admin requis')
      end
    end

    context 'when user is not signed in' do
      it 'redirects to login' do
        get admin_panel_memberships_path
        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end

  describe 'GET /admin-panel/memberships/:id' do
    context 'when user is admin (level 60)' do
      let(:admin_user) { create(:user, :admin) }

      before { login_user(admin_user) }

      it 'returns success' do
        get admin_panel_membership_path(target_membership)
        expect(response).to have_http_status(:success)
      end
    end
  end

  describe 'GET /admin-panel/memberships/new' do
    context 'when user is admin (level 60)' do
      let(:admin_user) { create(:user, :admin) }

      before { login_user(admin_user) }

      it 'returns success' do
        get new_admin_panel_membership_path
        expect(response).to have_http_status(:success)
      end
    end
  end

  describe 'POST /admin-panel/memberships' do
    let(:admin_user) { create(:user, :admin) }
    let(:membership_user) { create(:user) }

    before { sign_in admin_user }

    context 'with valid params' do
      let(:valid_params) do
        {
          membership: {
            user_id: membership_user.id,
            category: 'standard',
            status: 'pending',
            start_date: Date.current,
            end_date: 1.year.from_now,
            amount_cents: 1000,
            currency: 'EUR',
            season: '2024-2025'
          }
        }
      end

      it 'creates a new membership' do
        expect {
          post admin_panel_memberships_path, params: valid_params
        }.to change(Membership, :count).by(1)
      end

      it 'redirects to the membership show page' do
        post admin_panel_memberships_path, params: valid_params
        expect(response).to redirect_to(admin_panel_membership_path(Membership.last))
      end
    end
  end

  describe 'PATCH /admin-panel/memberships/:id' do
    let(:admin_user) { create(:user, :admin) }

    before { sign_in admin_user }

    context 'with valid params' do
      let(:update_params) do
        {
          membership: {
            status: 'active'
          }
        }
      end

      it 'updates the membership' do
        patch admin_panel_membership_path(target_membership), params: update_params
        target_membership.reload
        expect(target_membership.status).to eq('active')
      end

      it 'redirects to the membership show page' do
        patch admin_panel_membership_path(target_membership), params: update_params
        expect(response).to redirect_to(admin_panel_membership_path(target_membership))
      end
    end
  end

  describe 'PATCH /admin-panel/memberships/:id/activate' do
    let(:admin_user) { create(:user, :admin) }
    let(:pending_membership) { create(:membership, user: target_user, status: 'pending') }

    before { sign_in admin_user }

    context 'when membership is pending' do
      it 'activates the membership' do
        patch activate_admin_panel_membership_path(pending_membership)
        pending_membership.reload
        expect(pending_membership.status).to eq('active')
      end

      it 'redirects to the membership show page' do
        patch activate_admin_panel_membership_path(pending_membership)
        expect(response).to redirect_to(admin_panel_membership_path(pending_membership))
      end
    end

    context 'when membership is not pending' do
      let(:active_membership) { create(:membership, user: target_user, status: 'active') }

      it 'does not change the status' do
        expect {
          patch activate_admin_panel_membership_path(active_membership)
        }.not_to change { active_membership.reload.status }
      end
    end
  end

  describe 'DELETE /admin-panel/memberships/:id' do
    let(:admin_user) { create(:user, :admin) }
    let!(:membership_to_delete) { create(:membership) }

    before { sign_in admin_user }

    it 'deletes the membership' do
      expect {
        delete admin_panel_membership_path(membership_to_delete)
      }.to change(Membership, :count).by(-1)
    end

    it 'redirects to memberships index' do
      delete admin_panel_membership_path(membership_to_delete)
      expect(response).to redirect_to(admin_panel_memberships_path)
    end
  end
end
