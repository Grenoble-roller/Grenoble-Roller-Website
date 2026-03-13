require 'rails_helper'

RSpec.describe 'AdminPanel::Dashboard', type: :request do
  include RequestAuthenticationHelper

  let(:admin_role) { Role.find_or_create_by!(code: 'ADMIN') { |r| r.name = 'Administrateur'; r.level = 60 } }
  let(:organizer_role) { Role.find_or_create_by!(code: 'ORGANIZER') { |r| r.name = 'Organisateur'; r.level = 40 } }
  let(:user_role) { Role.find_or_create_by!(code: 'USER') { |r| r.name = 'Utilisateur'; r.level = 10 } }

  describe 'GET /admin-panel' do
    context 'when user is admin (level 60)' do
      let(:admin_user) { create(:user, :admin) }

      before { sign_in admin_user }

      it 'returns success' do
        get admin_panel_root_path
        expect(response).to have_http_status(:success)
      end

      it 'displays dashboard' do
        get admin_panel_root_path
        expect(response.body).to include('Tableau de bord')
      end
    end

    context 'when user is superadmin (level 70)' do
      let(:superadmin_user) { create(:user, :superadmin) }

      before { sign_in superadmin_user }

      it 'returns success' do
        get admin_panel_root_path
        expect(response).to have_http_status(:success)
      end
    end

    context 'when user is organizer (level 40)' do
      let(:organizer_user) { create(:user, :organizer) }

      before { sign_in organizer_user }

      it 'redirects to root with alert' do
        get admin_panel_root_path
        expect(response).to redirect_to(root_path)
        expect(flash[:alert]).to include('Accès admin requis')
      end
    end

    context 'when user level is below 60' do
      let(:regular_user) { create(:user, role: user_role) }

      before { sign_in regular_user }

      it 'redirects to root' do
        get admin_panel_root_path
        expect(response).to redirect_to(root_path)
      end
    end

    context 'when user is not signed in' do
      it 'redirects to login' do
        get admin_panel_root_path
        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end
end
