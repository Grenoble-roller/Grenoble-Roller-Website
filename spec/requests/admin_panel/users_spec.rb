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

      it 'shows only assignable roles in the role select (no Super_Admin option)' do
        get edit_admin_panel_user_path(target_user)
        role_select = response.body[/select[^>]+name="user\[role_id\]"[^>]*>.*?<\/select>/m]
        expect(role_select).to be_present
        expect(role_select).not_to include('Super Administrateur')
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

    context 'when admin tries to edit a super admin' do
      let(:admin_user) { create(:user, :admin) }
      let(:superadmin_target) { create(:user, :superadmin) }

      before do
        create(:role_superadmin)
        login_user(admin_user)
      end

      it 'redirects with not authorized' do
        get edit_admin_panel_user_path(superadmin_target)
        expect(response).to redirect_to(admin_panel_root_path)
        expect(flash[:alert]).to include('autorisé')
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
        expect(response).to have_http_status(:unprocessable_content)
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
      it 'rejects and returns unprocessable_content' do
        patch admin_panel_user_path(target_user), params: {
          user: { role_id: superadmin_role.id }
        }
        expect(response).to have_http_status(:unprocessable_content)
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
      it 'rejects self-elevation with unprocessable_content' do
        patch admin_panel_user_path(admin_user), params: {
          user: { role_id: superadmin_role.id }
        }
        expect(response).to have_http_status(:unprocessable_content)
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

    context 'when admin tries to demote a super admin' do
      let(:superadmin_target) { create(:user, :superadmin) }
      let(:admin_role_record) do
        Role.find_or_create_by!(code: 'ADMIN') { |r| r.name = 'Administrateur'; r.level = 60 }
      end

      it 'rejects the update' do
        patch admin_panel_user_path(superadmin_target), params: {
          user: { role_id: admin_role_record.id }
        }
        expect(response).to redirect_to(admin_panel_root_path)
        expect(flash[:alert]).to include('autorisé')
      end

      it 'does not change the super admin role' do
        previous_role_id = superadmin_target.role_id
        patch admin_panel_user_path(superadmin_target), params: {
          user: { role_id: admin_role_record.id, first_name: 'Hacked' }
        }
        superadmin_target.reload
        expect(superadmin_target.role_id).to eq(previous_role_id)
        expect(superadmin_target.first_name).not_to eq('Hacked')
      end
    end
  end

  describe 'GET /admin-panel/users/:id (super admin target)' do
    let(:admin_user) { create(:user, :admin) }
    let(:superadmin_target) { create(:user, :superadmin) }

    before { login_user(admin_user) }

    it 'allows viewing the profile' do
      get admin_panel_user_path(superadmin_target)
      expect(response).to have_http_status(:success)
    end

    it 'does not show edit or delete actions' do
      get admin_panel_user_path(superadmin_target)
      expect(response.body).not_to include(edit_admin_panel_user_path(superadmin_target))
      expect(response.body).to include('Modification réservée aux super administrateurs')
    end
  end

  describe 'PATCH /admin-panel/users/:id (super admin self-edit)' do
    let(:superadmin_user) { create(:user, :superadmin) }
    let(:admin_role_record) do
      Role.find_or_create_by!(code: 'ADMIN') { |r| r.name = 'Administrateur'; r.level = 60 }
    end

    before { login_user(superadmin_user) }

    it 'rejects self-demotion from super admin' do
      patch admin_panel_user_path(superadmin_user), params: {
        user: { role_id: admin_role_record.id }
      }
      expect(response).to have_http_status(:unprocessable_content)
      expect(response.body).to include('retirer votre propre rôle super administrateur')
    end

    it 'keeps super admin role after rejected self-demotion' do
      previous_role_id = superadmin_user.role_id
      patch admin_panel_user_path(superadmin_user), params: {
        user: { role_id: admin_role_record.id, first_name: 'StillSuper' }
      }
      superadmin_user.reload
      expect(superadmin_user.role_id).to eq(previous_role_id)
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

    context 'when target is super admin' do
      let!(:superadmin_target) { create(:user, :superadmin) }

      it 'does not delete the user' do
        expect {
          delete admin_panel_user_path(superadmin_target)
        }.not_to change(User, :count)
      end

      it 'redirects with not authorized' do
        delete admin_panel_user_path(superadmin_target)
        expect(response).to redirect_to(admin_panel_root_path)
        expect(flash[:alert]).to include('autorisé')
      end
    end
  end
end
