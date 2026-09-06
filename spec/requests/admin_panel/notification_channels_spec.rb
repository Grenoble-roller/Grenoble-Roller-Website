# frozen_string_literal: true

require "rails_helper"

RSpec.describe "AdminPanel::NotificationChannels", type: :request do
  include RequestAuthenticationHelper

  let(:valid_webhook_url) { DiscordNotificationHelpers::DISCORD_WEBHOOK_URL }
  let(:valid_params) do
    {
      notification_channel: {
        name: "Discord Ops",
        webhook_url: valid_webhook_url,
        enabled: true
      },
      event_keys: NotificationEventKeys::DEFAULT_ON
    }
  end

  describe "GET /admin-panel/notification-channels" do
    context "when user is superadmin (level 70)" do
      let(:superadmin_user) { create(:user, :superadmin) }

      before { login_user(superadmin_user) }

      it "returns success" do
        get admin_panel_notification_channels_path
        expect(response).to have_http_status(:success)
      end

      it "lists existing channels" do
        channel = create(:notification_channel, name: "Alertes boutique")
        get admin_panel_notification_channels_path
        expect(response.body).to include(channel.name)
      end
    end

    context "when user is admin (level 60)" do
      let(:admin_user) { create(:user, :admin) }

      before { login_user(admin_user) }

      it "redirects with alert reserved to superadmins" do
        get admin_panel_notification_channels_path
        expect(response).to redirect_to(admin_panel_initiations_path)
        expect(flash[:alert]).to include("super-administrateurs")
      end
    end

    context "when user is not signed in" do
      it "redirects to login" do
        get admin_panel_notification_channels_path
        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end

  describe "POST /admin-panel/notification-channels" do
    context "when user is superadmin" do
      let(:superadmin_user) { create(:user, :superadmin) }

      before { login_user(superadmin_user) }

      it "creates a channel with default subscriptions" do
        expect_any_instance_of(NotificationChannel).to receive(:sync_subscriptions!).with(
          match_array(NotificationEventKeys::DEFAULT_ON)
        ) do |channel, _keys|
          channel.notification_subscriptions.create!(event_key: "order.paid", enabled: true)
        end

        expect {
          post admin_panel_notification_channels_path, params: valid_params
        }.to change(NotificationChannel, :count).by(1)

        channel = NotificationChannel.last
        expect(channel.name).to eq("Discord Ops")
        expect(response).to redirect_to(edit_admin_panel_notification_channel_path(channel))
      end

      it "rejects invalid webhook host" do
        params = valid_params.deep_dup
        params[:notification_channel][:webhook_url] = "https://evil.example.com/hook"

        expect {
          post admin_panel_notification_channels_path, params: params
        }.not_to change(NotificationChannel, :count)

        expect(response).to have_http_status(:unprocessable_content)
      end
    end

    context "when user is admin (level 60)" do
      let(:admin_user) { create(:user, :admin) }

      before { login_user(admin_user) }

      it "does not create channel" do
        expect {
          post admin_panel_notification_channels_path, params: valid_params
        }.not_to change(NotificationChannel, :count)

        expect(response).to redirect_to(admin_panel_initiations_path)
      end
    end
  end

  describe "PATCH /admin-panel/notification-channels/:id" do
    context "when user is superadmin" do
      let(:superadmin_user) { create(:user, :superadmin) }
      let!(:channel) { create(:notification_channel, name: "Old name") }

      before { login_user(superadmin_user) }

      it "updates channel without changing webhook when URL blank" do
        original_ciphertext = channel.webhook_url_ciphertext

        patch admin_panel_notification_channel_path(channel), params: {
          notification_channel: { name: "New name", webhook_url: "" },
          event_keys: []
        }

        channel.reload
        expect(channel.name).to eq("New name")
        expect(channel.webhook_url_ciphertext).to eq(original_ciphertext)
        expect(response).to redirect_to(edit_admin_panel_notification_channel_path(channel))
      end
    end
  end

  describe "DELETE /admin-panel/notification-channels/:id" do
    context "when user is superadmin" do
      let(:superadmin_user) { create(:user, :superadmin) }
      let!(:channel) { create(:notification_channel) }

      before { login_user(superadmin_user) }

      it "destroys the channel" do
        expect {
          delete admin_panel_notification_channel_path(channel)
        }.to change(NotificationChannel, :count).by(-1)

        expect(response).to redirect_to(admin_panel_notification_channels_path)
      end
    end
  end

  describe "POST /admin-panel/notification-channels/:id/test" do
    context "when user is superadmin" do
      let(:superadmin_user) { create(:user, :superadmin) }
      let!(:channel) { create(:notification_channel) }

      before do
        login_user(superadmin_user)
        allow(DiscordWebhookClient).to receive(:post!).and_return(instance_double(Net::HTTPSuccess, code: "204"))
      end

      it "sends test notification and updates last_tested_at" do
        post test_admin_panel_notification_channel_path(channel)

        expect(DiscordWebhookClient).to have_received(:post!)
        expect(channel.reload.last_test_status).to eq("success")
        expect(channel.last_tested_at).to be_present
        expect(response).to redirect_to(edit_admin_panel_notification_channel_path(channel))
        expect(flash[:notice]).to be_present
      end

      it "shows error flash when Discord returns failure" do
        allow(DiscordWebhookClient).to receive(:post!).and_raise(
          DiscordWebhookClient::DeliveryError.new("Invalid webhook", http_code: 400, response_body: "Invalid webhook")
        )

        post test_admin_panel_notification_channel_path(channel)

        expect(channel.reload.last_test_status).to eq("error")
        expect(flash[:alert]).to be_present
      end
    end

    context "when user is admin (level 60)" do
      let(:admin_user) { create(:user, :admin) }
      let!(:channel) { create(:notification_channel) }

      before { login_user(admin_user) }

      it "redirects with superadmin alert" do
        post test_admin_panel_notification_channel_path(channel)
        expect(response).to redirect_to(admin_panel_initiations_path)
      end
    end
  end
end
