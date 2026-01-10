# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'AdminPanel::ContactMessages', type: :request do
  include RequestAuthenticationHelper

  let(:admin_role) { Role.find_or_create_by!(code: 'ADMIN') { |r| r.name = 'Administrateur'; r.level = 60 } }
  let(:organizer_role) { Role.find_or_create_by!(code: 'ORGANIZER') { |r| r.name = 'Organisateur'; r.level = 40 } }

  describe 'GET /admin-panel/contact-messages' do
    context 'when user is admin (level 60)' do
      let(:admin_user) { create(:user, :admin) }

      before do
        login_user(admin_user)
      end

      it 'returns success' do
        get admin_panel_contact_messages_path
        expect(response).to have_http_status(:success)
      end

      it 'displays contact messages' do
        create_list(:contact_message, 3)
        get admin_panel_contact_messages_path
        expect(response.body).to include('Messages de contact')
      end

      it 'filters by name' do
        message1 = create(:contact_message, name: 'John Doe')
        message2 = create(:contact_message, name: 'Jane Smith')

        get admin_panel_contact_messages_path, params: { q: { name_cont: 'John' } }

        expect(response).to have_http_status(:success)
        expect(@controller.instance_variable_get(:@contact_messages)).to include(message1)
        expect(@controller.instance_variable_get(:@contact_messages)).not_to include(message2)
      end
    end

    context 'when user is organizer (level 40)' do
      let(:organizer_user) { create(:user, :organizer) }

      before do
        login_user(organizer_user)
      end

      it 'redirects to root with alert' do
        get admin_panel_contact_messages_path
        expect(response).to redirect_to(root_path)
        expect(flash[:alert]).to include('Accès admin requis')
      end
    end

    context 'when user is not signed in' do
      it 'redirects to login' do
        get admin_panel_contact_messages_path
        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end

  describe 'GET /admin-panel/contact-messages/:id' do
    context 'when user is admin (level 60)' do
      let(:admin_user) { create(:user, :admin) }
      let(:contact_message) { create(:contact_message) }

      before do
        login_user(admin_user)
      end

      it 'returns success' do
        get admin_panel_contact_message_path(contact_message)
        expect(response).to have_http_status(:success)
      end

      it 'displays contact message details' do
        get admin_panel_contact_message_path(contact_message)
        expect(response.body).to include("Message ##{contact_message.id}")
        expect(response.body).to include(contact_message.name)
        expect(response.body).to include(contact_message.email)
      end
    end

    context 'when user is organizer (level 40)' do
      let(:organizer_user) { create(:user, :organizer) }
      let(:contact_message) { create(:contact_message) }

      before do
        login_user(organizer_user)
      end

      it 'redirects to root with alert' do
        get admin_panel_contact_message_path(contact_message)
        expect(response).to redirect_to(root_path)
        expect(flash[:alert]).to include('Accès admin requis')
      end
    end

    context 'when user is not signed in' do
      let(:contact_message) { create(:contact_message) }

      it 'redirects to login' do
        get admin_panel_contact_message_path(contact_message)
        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end

  describe 'DELETE /admin-panel/contact-messages/:id' do
    context 'when user is admin (level 60)' do
      let(:admin_user) { create(:user, :admin) }
      let!(:contact_message) { create(:contact_message) }

      before do
        login_user(admin_user)
      end

      it 'deletes the contact message' do
        expect {
          delete admin_panel_contact_message_path(contact_message)
        }.to change(ContactMessage, :count).by(-1)
      end

      it 'redirects to contact messages index' do
        delete admin_panel_contact_message_path(contact_message)
        expect(response).to redirect_to(admin_panel_contact_messages_path)
      end

      it 'shows success message' do
        delete admin_panel_contact_message_path(contact_message)
        expect(flash[:notice]).to include('supprimé avec succès')
      end
    end

    context 'when user is organizer (level 40)' do
      let(:organizer_user) { create(:user, :organizer) }
      let!(:contact_message) { create(:contact_message) }

      before do
        login_user(organizer_user)
      end

      it 'redirects to root with alert' do
        delete admin_panel_contact_message_path(contact_message)
        expect(response).to redirect_to(root_path)
        expect(flash[:alert]).to include('Accès admin requis')
      end

      it 'does not delete the contact message' do
        expect {
          delete admin_panel_contact_message_path(contact_message)
        }.not_to change(ContactMessage, :count)
      end
    end

    context 'when user is not signed in' do
      let!(:contact_message) { create(:contact_message) }

      it 'redirects to login' do
        delete admin_panel_contact_message_path(contact_message)
        expect(response).to redirect_to(new_user_session_path)
      end

      it 'does not delete the contact message' do
        expect {
          delete admin_panel_contact_message_path(contact_message)
        }.not_to change(ContactMessage, :count)
      end
    end
  end
end
