require 'rails_helper'

RSpec.describe 'AdminPanel::Users', type: :request do
  # ✅ Devise::Test::IntegrationHelpers est inclus automatiquement via rails_helper.rb
  # Pas besoin d'inclure RequestAuthenticationHelper si on utilise sign_in directement

  describe 'GET /admin-panel/users' do
    context 'when user is admin (level 60)' do
      let(:admin_user) { create(:user, :admin) }

      before { login_user(admin_user) }

      it 'returns success' do
        get admin_panel_users_path
        expect(response).to have_http_status(:success)
      end

      it 'displays users' do
        create_list(:user, 3)
        get admin_panel_users_path
        expect(response.body).to include('Utilisateurs')
      end
    end

    context 'when user is organizer (level 40)' do
      let(:organizer_user) { create(:user, :organizer) }

      before { login_user(organizer_user) }

      it 'redirects to root with alert' do
        get admin_panel_users_path
        expect(response).to redirect_to(root_path)
        expect(flash[:alert]).to include('Accès admin requis')
      end
    end

    context 'when user level is below 60' do
      let(:regular_user) { create(:user) } # Utilise le rôle USER par défaut de la factory

      before { login_user(regular_user) }

      it 'redirects to root' do
        get admin_panel_users_path
        expect(response).to redirect_to(root_path)
      end
    end

    context 'when user is not signed in' do
      it 'redirects to login' do
        get admin_panel_users_path
        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end

  describe 'GET /admin-panel/users/:id' do
    let(:target_user) { create(:user) }

    context 'when user is admin (level 60)' do
      let(:admin_user) { create(:user, :admin) }

      before { login_user(admin_user) }

      it 'returns success' do
        get admin_panel_user_path(target_user)
        expect(response).to have_http_status(:success)
      end
    end

    context 'when user is organizer (level 40)' do
      let(:organizer_user) { create(:user, :organizer) }

      before { login_user(organizer_user) }

      it 'redirects to root' do
        get admin_panel_user_path(target_user)
        expect(response).to redirect_to(root_path)
      end
    end
  end

  describe 'GET /admin-panel/users/new' do
    context 'when user is admin (level 60)' do
      let(:admin_user) { create(:user, :admin) }

      before do
        create(:role_user)
        create(:role_admin)
        create(:role_superadmin)
        login_user(admin_user)
      end

      it 'returns success' do
        get new_admin_panel_user_path
        expect(response).to have_http_status(:success)
      end

      it 'shows only assignable roles (no Super_Admin in select)' do
        get new_admin_panel_user_path
        expect(response.body).not_to include('Super Administrateur')
      end
    end
  end

  describe 'GET /admin-panel/users/:id/edit' do
    context 'when admin edits another user' do
      let(:admin_user) { create(:user, :admin) }
      let(:target_user) { create(:user) }

      before do
        create(:role_user)
        create(:role_admin)
        create(:role_superadmin)
        login_user(admin_user)
      end

      it 'returns success' do
        get edit_admin_panel_user_path(target_user)
        expect(response).to have_http_status(:success)
      end

      it 'shows only assignable roles (no Super_Admin)' do
        get edit_admin_panel_user_path(target_user)
        expect(response.body).not_to include('Super Administrateur')
      end
    end

    context 'when superadmin edits a user' do
      let(:superadmin_user) { create(:user, :superadmin) }
      let(:target_user) { create(:user) }

      before do
        create(:role_user)
        create(:role_admin)
        create(:role_superadmin)
        login_user(superadmin_user)
      end

      it 'shows Super_Admin in role options' do
        get edit_admin_panel_user_path(target_user)
        expect(response.body).to include('Super Administrateur')
      end
    end
  end

  describe 'POST /admin-panel/users' do
    let(:admin_user) { create(:user, :admin) }

    before { login_user(admin_user) }

    context 'with valid params' do
      it 'creates a new user' do
        # ✅ Utiliser find_or_create_by! pour les rôles standards (codes fixes)
        user_role = Role.find_or_create_by!(code: 'USER') { |r| r.name = 'Utilisateur'; r.level = 10 }

        params = {
          user: {
            email: "newuser_#{SecureRandom.hex(4)}@example.com",
            password: 'password12345',
            password_confirmation: 'password12345',
            first_name: 'John',
            last_name: 'Doe',
            skill_level: 'intermediate',
            phone: '0612345678',
            role_id: user_role.id
          }
        }

        expect {
          post admin_panel_users_path, params: params
        }.to change(User, :count).by(1)
      end

      it 'redirects to the user show page' do
        # ✅ Utiliser find_or_create_by! pour les rôles standards (codes fixes)
        user_role = Role.find_or_create_by!(code: 'USER') { |r| r.name = 'Utilisateur'; r.level = 10 }

        params = {
          user: {
            email: "newuser_#{SecureRandom.hex(4)}@example.com",
            password: 'password12345',
            password_confirmation: 'password12345',
            first_name: 'John',
            last_name: 'Doe',
            skill_level: 'intermediate',
            phone: '0612345678',
            role_id: user_role.id
          }
        }

        post admin_panel_users_path, params: params
        expect(response).to redirect_to(admin_panel_user_path(User.last))
      end
    end

    context 'with invalid params' do
      it 'does not create a user' do
        # ✅ Utiliser find_or_create_by! pour les rôles standards (codes fixes)
        user_role = Role.find_or_create_by!(code: 'USER') { |r| r.name = 'Utilisateur'; r.level = 10 }

        params = {
          user: {
            email: '',
            password: 'password12345',
            password_confirmation: 'password12345',
            role_id: user_role.id
          }
        }

        expect {
          post admin_panel_users_path, params: params
        }.not_to change(User, :count)
      end

      it 'renders new template' do
        # ✅ Utiliser find_or_create_by! pour les rôles standards (codes fixes)
        user_role = Role.find_or_create_by!(code: 'USER') { |r| r.name = 'Utilisateur'; r.level = 10 }

        params = {
          user: {
            email: '',
            password: 'password12345',
            password_confirmation: 'password12345',
            role_id: user_role.id
          }
        }

        post admin_panel_users_path, params: params
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end
  end

  describe 'PATCH /admin-panel/users/:id' do
    let(:admin_user) { create(:user, :admin) }
    let(:target_user) { create(:user) }
    let(:superadmin_role) { create(:role_superadmin) }

    before { login_user(admin_user) }

    context 'with valid params' do
      it 'updates the user' do
        patch admin_panel_user_path(target_user), params: {
          user: { first_name: 'Updated Name' }
        }
        target_user.reload
        expect(target_user.first_name).to eq('Updated Name')
      end

      it 'redirects to the user show page' do
        patch admin_panel_user_path(target_user), params: {
          user: { first_name: 'Updated Name' }
        }
        expect(response).to redirect_to(admin_panel_user_path(target_user))
      end
    end

    context 'when admin tries to assign Super_Admin to another user' do
      it 'rejects and returns unprocessable_entity' do
        patch admin_panel_user_path(target_user), params: {
          user: { role_id: superadmin_role.id }
        }
        expect(response).to have_http_status(:unprocessable_entity)
      end

      it 'adds error on role_id' do
        patch admin_panel_user_path(target_user), params: {
          user: { role_id: superadmin_role.id }
        }
        target_user.reload
        expect(target_user.role_id).not_to eq(superadmin_role.id)
      end
    end

    context 'when admin edits their own profile and tries to set role to Super_Admin' do
      it 'rejects self-elevation with unprocessable_entity' do
        patch admin_panel_user_path(admin_user), params: {
          user: { role_id: superadmin_role.id }
        }
        expect(response).to have_http_status(:unprocessable_entity)
      end

      it 'keeps current role and displays error message' do
        previous_role_id = admin_user.role_id
        patch admin_panel_user_path(admin_user), params: {
          user: { role_id: superadmin_role.id }
        }
        admin_user.reload
        expect(admin_user.role_id).to eq(previous_role_id)
        expect(response.body).to include('Vous ne pouvez pas vous attribuer')
      end
    end
  end

  describe 'DELETE /admin-panel/users/:id' do
    let(:admin_user) { create(:user, :admin) }
    let!(:user_to_delete) { create(:user) }

    before { login_user(admin_user) }

    it 'deletes the user' do
      expect {
        delete admin_panel_user_path(user_to_delete)
      }.to change(User, :count).by(-1)
    end

    it 'redirects to users index' do
      delete admin_panel_user_path(user_to_delete)
      expect(response).to redirect_to(admin_panel_users_path)
    end
  end
end
