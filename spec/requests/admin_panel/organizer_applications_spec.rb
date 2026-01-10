# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'AdminPanel::OrganizerApplications', type: :request do
  let(:admin_role) { Role.find_or_create_by!(code: 'ADMIN') { |r| r.name = 'Administrateur'; r.level = 60 } }
  let(:organizer_role) { Role.find_or_create_by!(code: 'ORGANIZER') { |r| r.name = 'Organisateur'; r.level = 40 } }
  let(:user_role) { Role.find_or_create_by!(code: 'USER') { |r| r.name = 'Utilisateur'; r.level = 10 } }

  describe 'GET /admin-panel/organizer_applications' do
    context 'when user is admin (level 60)' do
      let(:admin_user) { create(:user, :admin) }

      before { login_user(admin_user) }

      it 'returns success' do
        get admin_panel_organizer_applications_path
        expect(response).to have_http_status(:success)
      end

      it 'displays organizer applications' do
        create_list(:organizer_application, 3)
        get admin_panel_organizer_applications_path
        expect(response.body).to include('Candidatures Organisateur')
      end
    end

    context 'when user is organizer (level 40)' do
      let(:organizer_user) { create(:user, :organizer) }

      before { login_user(organizer_user) }

      it 'redirects to root with alert' do
        get admin_panel_organizer_applications_path
        expect(response).to redirect_to(root_path)
        expect(flash[:alert]).to include('Accès admin requis')
      end
    end

    context 'when user level is below 60' do
      let(:regular_user) { create(:user) }

      before { login_user(regular_user) }

      it 'redirects to root' do
        get admin_panel_organizer_applications_path
        expect(response).to redirect_to(root_path)
      end
    end

    context 'when user is not signed in' do
      it 'redirects to login' do
        get admin_panel_organizer_applications_path
        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end

  describe 'GET /admin-panel/organizer_applications/:id' do
    let(:organizer_application) { create(:organizer_application) }

    context 'when user is admin (level 60)' do
      let(:admin_user) { create(:user, :admin) }

      before { login_user(admin_user) }

      it 'returns success' do
        get admin_panel_organizer_application_path(organizer_application)
        expect(response).to have_http_status(:success)
      end

      it 'displays organizer application details' do
        get admin_panel_organizer_application_path(organizer_application)
        expect(response.body).to include('Candidature Organisateur')
      end
    end

    context 'when user is organizer (level 40)' do
      let(:organizer_user) { create(:user, :organizer) }

      before { login_user(organizer_user) }

      it 'redirects to root with alert' do
        get admin_panel_organizer_application_path(organizer_application)
        expect(response).to redirect_to(root_path)
      end
    end
  end

  describe 'PATCH /admin-panel/organizer_applications/:id/approve' do
    let(:organizer_application) { create(:organizer_application, status: 'pending') }

    context 'when user is admin (level 60)' do
      let(:admin_user) { create(:user, :admin) }

      before { login_user(admin_user) }

      it 'approves the application' do
        patch approve_admin_panel_organizer_application_path(organizer_application)
        organizer_application.reload
        expect(organizer_application.status).to eq('approved')
        expect(organizer_application.reviewed_by).to eq(admin_user)
        expect(organizer_application.reviewed_at).to be_present
      end

      it 'redirects to the application show page' do
        patch approve_admin_panel_organizer_application_path(organizer_application)
        expect(response).to redirect_to(admin_panel_organizer_application_path(organizer_application))
      end
    end

    context 'when user is organizer (level 40)' do
      let(:organizer_user) { create(:user, :organizer) }

      before { login_user(organizer_user) }

      it 'redirects to root with alert' do
        patch approve_admin_panel_organizer_application_path(organizer_application)
        expect(response).to redirect_to(root_path)
      end
    end
  end

  describe 'PATCH /admin-panel/organizer_applications/:id/reject' do
    let(:organizer_application) { create(:organizer_application, status: 'pending') }

    context 'when user is admin (level 60)' do
      let(:admin_user) { create(:user, :admin) }

      before { login_user(admin_user) }

      it 'rejects the application' do
        patch reject_admin_panel_organizer_application_path(organizer_application)
        organizer_application.reload
        expect(organizer_application.status).to eq('rejected')
        expect(organizer_application.reviewed_by).to eq(admin_user)
        expect(organizer_application.reviewed_at).to be_present
      end

      it 'redirects to the application show page' do
        patch reject_admin_panel_organizer_application_path(organizer_application)
        expect(response).to redirect_to(admin_panel_organizer_application_path(organizer_application))
      end
    end

    context 'when user is organizer (level 40)' do
      let(:organizer_user) { create(:user, :organizer) }

      before { login_user(organizer_user) }

      it 'redirects to root with alert' do
        patch reject_admin_panel_organizer_application_path(organizer_application)
        expect(response).to redirect_to(root_path)
      end
    end
  end

  describe 'DELETE /admin-panel/organizer_applications/:id' do
    let!(:organizer_application) { create(:organizer_application) }

    context 'when user is admin (level 60)' do
      let(:admin_user) { create(:user, :admin) }

      before { login_user(admin_user) }

      it 'deletes the organizer application' do
        expect {
          delete admin_panel_organizer_application_path(organizer_application)
        }.to change(OrganizerApplication, :count).by(-1)
      end

      it 'redirects to organizer applications index' do
        delete admin_panel_organizer_application_path(organizer_application)
        expect(response).to redirect_to(admin_panel_organizer_applications_path)
      end
    end
  end
end
