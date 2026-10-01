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

      it 'shows Discord settings button and modal' do
        get admin_panel_contact_messages_path
        expect(response.body).to include('contactDiscordSettingsModal')
        expect(response.body).to include('Notifications Discord')
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

  describe 'PATCH /admin-panel/contact-messages/update_discord_settings' do
    let(:webhook_url) { DiscordNotificationHelpers::DISCORD_WEBHOOK_URL }

    context 'when user is admin (level 60)' do
      let(:admin_user) { create(:user, :admin) }

      before { login_user(admin_user) }

      it 'creates a dedicated contact messages notification channel' do
        expect {
          patch update_discord_settings_admin_panel_contact_messages_path, params: {
            notification_channel: {
              webhook_url: webhook_url,
              enabled: '1'
            }
          }
        }.to change(NotificationChannel, :count).by(1)

        channel = NotificationChannel.find_by!(purpose: NotificationChannel::CONTACT_MESSAGES_PURPOSE)
        expect(channel.enabled).to be(true)
        expect(channel.webhook_configured?).to be(true)
        expect(channel.subscribed_event_keys).to eq([ NotificationChannel::CONTACT_MESSAGES_EVENT_KEY ])
        expect(response).to redirect_to(admin_panel_contact_messages_path)
        expect(flash[:notice]).to include('activées')
      end

      it 'updates an existing contact messages channel without replacing the webhook when blank' do
        channel = create(
          :notification_channel,
          purpose: NotificationChannel::CONTACT_MESSAGES_PURPOSE,
          name: NotificationChannel::CONTACT_MESSAGES_NAME,
          enabled: false,
          webhook_url: webhook_url
        )
        channel.ensure_contact_messages_subscription!

        patch update_discord_settings_admin_panel_contact_messages_path, params: {
          notification_channel: {
            webhook_url: '',
            enabled: '1'
          }
        }

        expect(channel.reload.enabled).to be(true)
        expect(channel.webhook_configured?).to be(true)
        expect(flash[:notice]).to include('activées')
      end
    end

    context 'when user is organizer (level 40)' do
      let(:organizer_user) { create(:user, :organizer) }

      before { login_user(organizer_user) }

      it 'rejects access' do
        patch update_discord_settings_admin_panel_contact_messages_path, params: {
          notification_channel: { webhook_url: webhook_url, enabled: '1' }
        }
        expect(response).to redirect_to(root_path)
        expect(NotificationChannel.where(purpose: NotificationChannel::CONTACT_MESSAGES_PURPOSE)).to be_empty
      end
    end
  end

  describe 'POST /admin-panel/contact-messages/test_discord' do
    let(:webhook_url) { DiscordNotificationHelpers::DISCORD_WEBHOOK_URL }

    context 'when user is admin and channel is configured' do
      let(:admin_user) { create(:user, :admin) }
      let!(:channel) do
        create(
          :notification_channel,
          purpose: NotificationChannel::CONTACT_MESSAGES_PURPOSE,
          name: NotificationChannel::CONTACT_MESSAGES_NAME,
          webhook_url: webhook_url,
          enabled: true
        ).tap(&:ensure_contact_messages_subscription!)
      end

      before { login_user(admin_user) }

      it 'posts a test payload to Discord' do
        expect(DiscordWebhookClient).to receive(:post!).with(webhook_url, hash_including(:embeds))

        post test_discord_admin_panel_contact_messages_path

        expect(response).to redirect_to(admin_panel_contact_messages_path)
        expect(flash[:notice]).to include('test')
        expect(channel.reload.last_test_status).to eq('success')
      end
    end

    context 'when user is admin and submits a webhook URL without saving' do
      let(:admin_user) { create(:user, :admin) }

      before { login_user(admin_user) }

      it 'posts a test payload using the submitted URL' do
        expect(DiscordWebhookClient).to receive(:post!).with(webhook_url, hash_including(:embeds))

        post test_discord_admin_panel_contact_messages_path, params: {
          notification_channel: { webhook_url: webhook_url }
        }

        expect(response).to redirect_to(admin_panel_contact_messages_path)
        expect(flash[:notice]).to include('test')
        expect(NotificationChannel.where(purpose: NotificationChannel::CONTACT_MESSAGES_PURPOSE)).to be_empty
      end
    end
  end
end
