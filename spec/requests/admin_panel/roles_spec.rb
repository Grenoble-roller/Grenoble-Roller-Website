require 'rails_helper'

RSpec.describe 'AdminPanel::Roles', type: :request do
  include RequestAuthenticationHelper

  let(:admin_role) { Role.find_or_create_by!(code: 'ADMIN') { |r| r.name = 'Administrateur'; r.level = 60 } }
  let(:superadmin_role) { Role.find_or_create_by!(code: 'SUPERADMIN') { |r| r.name = 'Super Administrateur'; r.level = 70 } }
  let(:organizer_role) { Role.find_or_create_by!(code: 'ORGANIZER') { |r| r.name = 'Organisateur'; r.level = 40 } }
  let(:user_role) { Role.find_or_create_by!(code: 'USER') { |r| r.name = 'Utilisateur'; r.level = 10 } }

  describe 'GET /admin-panel/roles' do
    context 'when user is superadmin (level 70)' do
      let(:superadmin_user) { create(:user, role: superadmin_role) }

      before { login_user(superadmin_user) }

      it 'returns success' do
        get admin_panel_roles_path
        expect(response).to have_http_status(:success)
      end

      it 'displays roles' do
        create_list(:role, 3)
        get admin_panel_roles_path
        expect(response.body).to include('Rôles')
      end
    end

    context 'when user is admin (level 60)' do
      let(:admin_user) { create(:user, role: admin_role) }

      before { login_user(admin_user) }

      it 'redirects to initiations with alert' do
        get admin_panel_roles_path
        expect(response).to redirect_to(admin_panel_initiations_path)
        expect(flash[:alert]).to include('Accès réservé aux super-administrateurs')
      end
    end

    context 'when user is organizer (level 40)' do
      let(:organizer_user) { create(:user, role: organizer_role) }

      before { login_user(organizer_user) }

      it 'redirects to root with alert' do
        get admin_panel_roles_path
        expect(response).to redirect_to(root_path)
        expect(flash[:alert]).to include('Accès admin requis')
      end
    end

    context 'when user is not signed in' do
      it 'redirects to login' do
        get admin_panel_roles_path
        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end

  describe 'GET /admin-panel/roles/:id' do
    let(:target_role) { create(:role) }

    context 'when user is superadmin (level 70)' do
      let(:superadmin_user) { create(:user, role: superadmin_role) }

      before { login_user(superadmin_user) }

      it 'returns success' do
        get admin_panel_role_path(target_role)
        expect(response).to have_http_status(:success)
      end
    end

    context 'when user is admin (level 60)' do
      let(:admin_user) { create(:user, role: admin_role) }

      before { login_user(admin_user) }

      it 'redirects to initiations with alert' do
        get admin_panel_role_path(target_role)
        expect(response).to redirect_to(admin_panel_initiations_path)
        expect(flash[:alert]).to include('Accès réservé aux super-administrateurs')
      end
    end
  end

  describe 'GET /admin-panel/roles/new' do
    context 'when user is superadmin (level 70)' do
      let(:superadmin_user) { create(:user, role: superadmin_role) }

      before { login_user(superadmin_user) }

      it 'returns success' do
        get new_admin_panel_role_path
        expect(response).to have_http_status(:success)
      end
    end

    context 'when user is admin (level 60)' do
      let(:admin_user) { create(:user, role: admin_role) }

      before { login_user(admin_user) }

      it 'redirects to initiations with alert' do
        get new_admin_panel_role_path
        expect(response).to redirect_to(admin_panel_initiations_path)
        expect(flash[:alert]).to include('Accès réservé aux super-administrateurs')
      end
    end
  end

  describe 'POST /admin-panel/roles' do
    let(:superadmin_user) { create(:user, role: superadmin_role) }

    before { login_user(superadmin_user) }

    context 'with valid params' do
      let(:valid_params) do
        {
          role: {
            name: 'Test Role',
            code: 'TEST_ROLE',
            level: 50,
            description: 'Test description'
          }
        }
      end

      it 'creates a new role' do
        expect {
          post admin_panel_roles_path, params: valid_params
        }.to change(Role, :count).by(1)
      end

      it 'redirects to the role show page' do
        post admin_panel_roles_path, params: valid_params
        expect(response).to redirect_to(admin_panel_role_path(Role.last))
      end
    end

    context 'with invalid params' do
      let(:invalid_params) do
        {
          role: {
            name: '',
            code: '',
            level: nil
          }
        }
      end

      it 'does not create a role' do
        expect {
          post admin_panel_roles_path, params: invalid_params
        }.not_to change(Role, :count)
      end
    end
  end

  describe 'PATCH /admin-panel/roles/:id' do
    let(:superadmin_user) { create(:user, role: superadmin_role) }
    let(:target_role) { create(:role) }

    before { login_user(superadmin_user) }

    context 'with valid params' do
      let(:update_params) do
        {
          role: {
            name: 'Updated Role Name'
          }
        }
      end

      it 'updates the role' do
        patch admin_panel_role_path(target_role), params: update_params
        target_role.reload
        expect(target_role.name).to eq('Updated Role Name')
      end

      it 'redirects to the role show page' do
        patch admin_panel_role_path(target_role), params: update_params
        expect(response).to redirect_to(admin_panel_role_path(target_role))
      end
    end
  end

  describe 'DELETE /admin-panel/roles/:id' do
    let(:superadmin_user) { create(:user, role: superadmin_role) }
    let!(:role_to_delete) { create(:role) }

    before { login_user(superadmin_user) }

    it 'deletes the role' do
      expect {
        delete admin_panel_role_path(role_to_delete)
      }.to change(Role, :count).by(-1)
    end

    it 'redirects to roles index' do
      delete admin_panel_role_path(role_to_delete)
      expect(response).to redirect_to(admin_panel_roles_path)
    end
  end
end
