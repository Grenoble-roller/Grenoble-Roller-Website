# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'AdminPanel::Partners', type: :request do
  include RequestAuthenticationHelper

  let(:admin_role) { Role.find_or_create_by!(code: 'ADMIN') { |r| r.name = 'Administrateur'; r.level = 60 } }
  let(:organizer_role) { Role.find_or_create_by!(code: 'ORGANIZER') { |r| r.name = 'Organisateur'; r.level = 40 } }

  describe 'GET /admin-panel/partners' do
    context 'when user is admin (level 60)' do
      let(:admin_user) { create(:user, :admin) }

      before do
        login_user(admin_user)
      end

      it 'returns success' do
        get admin_panel_partners_path
        expect(response).to have_http_status(:success)
      end

      it 'displays partners' do
        create_list(:partner, 3)
        get admin_panel_partners_path
        expect(response.body).to include('Partenaires')
      end

      it 'filters by active scope' do
        partner1 = create(:partner, is_active: true)
        partner2 = create(:partner, is_active: false)

        get admin_panel_partners_path, params: { scope: 'active' }

        expect(response).to have_http_status(:success)
        expect(@controller.instance_variable_get(:@partners)).to include(partner1)
        expect(@controller.instance_variable_get(:@partners)).not_to include(partner2)
      end
    end

    context 'when user is organizer (level 40)' do
      let(:organizer_user) { create(:user, :organizer) }

      before do
        login_user(organizer_user)
      end

      it 'redirects to root with alert' do
        get admin_panel_partners_path
        expect(response).to redirect_to(root_path)
        expect(flash[:alert]).to include('Accès admin requis')
      end
    end

    context 'when user is not signed in' do
      it 'redirects to login' do
        get admin_panel_partners_path
        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end

  describe 'GET /admin-panel/partners/:id' do
    context 'when user is admin (level 60)' do
      let(:admin_user) { create(:user, :admin) }
      let(:partner) { create(:partner) }

      before do
        login_user(admin_user)
      end

      it 'returns success' do
        get admin_panel_partner_path(partner)
        expect(response).to have_http_status(:success)
      end

      it 'displays partner details' do
        get admin_panel_partner_path(partner)
        expect(response.body).to include(partner.name)
      end
    end
  end

  describe 'GET /admin-panel/partners/new' do
    context 'when user is admin (level 60)' do
      let(:admin_user) { create(:user, :admin) }

      before do
        login_user(admin_user)
      end

      it 'returns success' do
        get new_admin_panel_partner_path
        expect(response).to have_http_status(:success)
      end
    end
  end

  describe 'POST /admin-panel/partners' do
    context 'when user is admin (level 60)' do
      let(:admin_user) { create(:user, :admin) }

      before do
        login_user(admin_user)
      end

      it 'creates a new partner' do
        params = {
          partner: {
            name: 'Nouveau Partenaire',
            url: 'https://example.com',
            logo_url: 'https://example.com/logo.png',
            description: 'Description du partenaire',
            is_active: true
          }
        }

        expect {
          post admin_panel_partners_path, params: params
        }.to change(Partner, :count).by(1)
      end

      it 'redirects to partner show' do
        params = {
          partner: {
            name: 'Nouveau Partenaire',
            url: 'https://example.com',
            is_active: true
          }
        }

        post admin_panel_partners_path, params: params
        expect(response).to redirect_to(admin_panel_partner_path(Partner.last))
      end
    end
  end

  describe 'GET /admin-panel/partners/:id/edit' do
    context 'when user is admin (level 60)' do
      let(:admin_user) { create(:user, :admin) }
      let(:partner) { create(:partner) }

      before do
        login_user(admin_user)
      end

      it 'returns success' do
        get edit_admin_panel_partner_path(partner)
        expect(response).to have_http_status(:success)
      end
    end
  end

  describe 'PATCH /admin-panel/partners/:id' do
    context 'when user is admin (level 60)' do
      let(:admin_user) { create(:user, :admin) }
      let(:partner) { create(:partner) }

      before do
        login_user(admin_user)
      end

      it 'updates the partner' do
        patch admin_panel_partner_path(partner), params: {
          partner: { name: 'Nom modifié' }
        }

        expect(partner.reload.name).to eq('Nom modifié')
      end
    end
  end

  describe 'DELETE /admin-panel/partners/:id' do
    context 'when user is admin (level 60)' do
      let(:admin_user) { create(:user, :admin) }
      let!(:partner) { create(:partner) }

      before do
        login_user(admin_user)
      end

      it 'deletes the partner' do
        expect {
          delete admin_panel_partner_path(partner)
        }.to change(Partner, :count).by(-1)
      end

      it 'redirects to partners index' do
        delete admin_panel_partner_path(partner)
        expect(response).to redirect_to(admin_panel_partners_path)
      end
    end
  end
end
