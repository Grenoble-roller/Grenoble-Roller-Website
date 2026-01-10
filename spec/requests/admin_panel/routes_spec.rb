# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'AdminPanel::Routes', type: :request do
  let(:admin_role) { Role.find_or_create_by!(code: 'ADMIN') { |r| r.name = 'Administrateur'; r.level = 60 } }
  let(:organizer_role) { Role.find_or_create_by!(code: 'ORGANIZER') { |r| r.name = 'Organisateur'; r.level = 40 } }
  let(:user_role) { Role.find_or_create_by!(code: 'USER') { |r| r.name = 'Utilisateur'; r.level = 10 } }

  describe 'GET /admin-panel/routes' do
    context 'when user is admin (level 60)' do
      let(:admin_user) { create(:user, :admin) }

      before { login_user(admin_user) }

      it 'returns success' do
        get admin_panel_routes_path
        expect(response).to have_http_status(:success)
      end

      it 'displays routes' do
        create_list(:route, 3)
        get admin_panel_routes_path
        expect(response.body).to include('Routes')
      end
    end

    context 'when user is organizer (level 40)' do
      let(:organizer_user) { create(:user, :organizer) }

      before { login_user(organizer_user) }

      it 'redirects to root with alert' do
        get admin_panel_routes_path
        expect(response).to redirect_to(root_path)
        expect(flash[:alert]).to include('Accès admin requis')
      end
    end

    context 'when user level is below 60' do
      let(:regular_user) { create(:user) }

      before { login_user(regular_user) }

      it 'redirects to root' do
        get admin_panel_routes_path
        expect(response).to redirect_to(root_path)
      end
    end

    context 'when user is not signed in' do
      it 'redirects to login' do
        get admin_panel_routes_path
        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end

  describe 'GET /admin-panel/routes/:id' do
    let(:route) { create(:route) }

    context 'when user is admin (level 60)' do
      let(:admin_user) { create(:user, :admin) }

      before { login_user(admin_user) }

      it 'returns success' do
        get admin_panel_route_path(route)
        expect(response).to have_http_status(:success)
      end

      it 'displays route details' do
        get admin_panel_route_path(route)
        expect(response.body).to include(route.name)
      end
    end

    context 'when user is organizer (level 40)' do
      let(:organizer_user) { create(:user, :organizer) }

      before { login_user(organizer_user) }

      it 'redirects to root with alert' do
        get admin_panel_route_path(route)
        expect(response).to redirect_to(root_path)
      end
    end
  end

  describe 'GET /admin-panel/routes/new' do
    context 'when user is admin (level 60)' do
      let(:admin_user) { create(:user, :admin) }

      before { login_user(admin_user) }

      it 'returns success' do
        get new_admin_panel_route_path
        expect(response).to have_http_status(:success)
      end
    end
  end

  describe 'POST /admin-panel/routes' do
    context 'when user is admin (level 60)' do
      let(:admin_user) { create(:user, :admin) }

      before { login_user(admin_user) }

      context 'with valid params' do
        let(:valid_params) do
          {
            route: {
              name: "Route Test #{Time.now.to_i}",
              difficulty: 'medium',
              distance_km: 15.5,
              elevation_m: 200,
              description: 'Description de test'
            }
          }
        end

        it 'creates a new route' do
          expect {
            post admin_panel_routes_path, params: valid_params
          }.to change(Route, :count).by(1)
        end

        it 'redirects to the route show page' do
          post admin_panel_routes_path, params: valid_params
          expect(response).to redirect_to(admin_panel_route_path(Route.last))
        end
      end

      context 'with invalid params' do
        let(:invalid_params) do
          {
            route: {
              name: '', # Nom requis
              difficulty: 'invalid'
            }
          }
        end

        it 'does not create a route' do
          expect {
            post admin_panel_routes_path, params: invalid_params
          }.not_to change(Route, :count)
        end

        it 'renders new template' do
          post admin_panel_routes_path, params: invalid_params
          expect(response).to have_http_status(:unprocessable_entity)
        end
      end
    end
  end

  describe 'GET /admin-panel/routes/:id/edit' do
    let(:route) { create(:route) }

    context 'when user is admin (level 60)' do
      let(:admin_user) { create(:user, :admin) }

      before { login_user(admin_user) }

      it 'returns success' do
        get edit_admin_panel_route_path(route)
        expect(response).to have_http_status(:success)
      end
    end
  end

  describe 'PATCH /admin-panel/routes/:id' do
    let(:route) { create(:route) }

    context 'when user is admin (level 60)' do
      let(:admin_user) { create(:user, :admin) }

      before { login_user(admin_user) }

      context 'with valid params' do
        let(:update_params) do
          {
            route: {
              name: "Route Modifiée #{Time.now.to_i}",
              difficulty: 'hard'
            }
          }
        end

        it 'updates the route' do
          patch admin_panel_route_path(route), params: update_params
          route.reload
          expect(route.name).to include('Route Modifiée')
          expect(route.difficulty).to eq('hard')
        end

        it 'redirects to the route show page' do
          patch admin_panel_route_path(route), params: update_params
          expect(response).to redirect_to(admin_panel_route_path(route))
        end
      end

      context 'with invalid params' do
        let(:invalid_params) do
          {
            route: {
              name: '' # Nom requis
            }
          }
        end

        it 'does not update the route' do
          original_name = route.name
          patch admin_panel_route_path(route), params: invalid_params
          route.reload
          expect(route.name).to eq(original_name)
        end

        it 'renders edit template' do
          patch admin_panel_route_path(route), params: invalid_params
          expect(response).to have_http_status(:unprocessable_entity)
        end
      end
    end
  end

  describe 'DELETE /admin-panel/routes/:id' do
    let!(:route) { create(:route) }

    context 'when user is admin (level 60)' do
      let(:admin_user) { create(:user, :admin) }

      before { login_user(admin_user) }

      it 'deletes the route' do
        expect {
          delete admin_panel_route_path(route)
        }.to change(Route, :count).by(-1)
      end

      it 'redirects to routes index' do
        delete admin_panel_route_path(route)
        expect(response).to redirect_to(admin_panel_routes_path)
      end
    end
  end
end
