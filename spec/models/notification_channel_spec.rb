# frozen_string_literal: true

require "rails_helper"

RSpec.describe NotificationChannel, type: :model do
  describe "associations" do
    it "destroys subscriptions when channel is destroyed" do
      channel = create(:notification_channel)
      subscription = create(:notification_subscription, notification_channel: channel)
      subscription_id = subscription.id

      channel.destroy

      expect(NotificationSubscription.find_by(id: subscription_id)).to be_nil
    end
  end

  describe "validations" do
    it "requires name" do
      channel = build(:notification_channel, name: nil)
      expect(channel).not_to be_valid
      expect(channel.errors[:name]).to be_present
    end

    it "requires webhook_url on create" do
      channel = build(:notification_channel, webhook_url: nil)
      expect(channel).not_to be_valid
      expect(channel.errors[:webhook_url]).to be_present
    end

    it "stays valid on update when webhook_url is omitted" do
      channel = create(:notification_channel)
      expect(channel.update(name: "Renamed")).to be(true)
    end

    context "webhook URL host validation (SSRF guard)" do
      it "accepts discord.com host" do
        channel = build(:notification_channel, webhook_url: "https://discord.com/api/webhooks/1/abc")
        expect(channel).to be_valid
      end

      it "accepts discordapp.com host" do
        channel = build(:notification_channel, webhook_url: "https://discordapp.com/api/webhooks/1/abc")
        expect(channel).to be_valid
      end

      it "rejects non-Discord hosts" do
        channel = build(:notification_channel, webhook_url: "https://evil.example.com/hook")
        expect(channel).not_to be_valid
        expect(channel.errors[:webhook_url]).to be_present
      end

      it "rejects internal hosts" do
        channel = build(:notification_channel, webhook_url: "http://127.0.0.1/webhook")
        expect(channel).not_to be_valid
      end
    end
  end

  describe "webhook_url encryption roundtrip" do
    it "stores ciphertext and decrypts on read" do
      url = DiscordNotificationHelpers::DISCORD_WEBHOOK_URL
      channel = create(:notification_channel, webhook_url: url)

      raw = NotificationChannel.connection.select_value(
        "SELECT webhook_url_ciphertext FROM notification_channels WHERE id = #{channel.id}"
      )
      expect(raw).to be_present
      expect(raw).not_to eq(url)

      expect(channel.reload.webhook_url).to eq(url)
    end

    it "masks webhook URL for display" do
      channel = create(:notification_channel)
      masked = channel.masked_webhook_url

      expect(masked).to include("discord")
      expect(masked).to include("***")
    end
  end

  describe "#sync_subscriptions!" do
    it "enables selected event keys and disables others" do
      channel = create(:notification_channel)

      channel.sync_subscriptions!(NotificationEventKeys::DEFAULT_ON)

      expect(channel.subscribed_event_keys).to match_array(NotificationEventKeys::DEFAULT_ON)
      expect(channel.notification_subscriptions.find_by(event_key: "payment.failed").enabled).to be(false)
    end

    it "is idempotent when syncing full registry twice" do
      channel = create(:notification_channel)
      channel.sync_subscriptions!(NotificationEventRegistry.event_keys)

      expect {
        channel.sync_subscriptions!(NotificationEventRegistry.event_keys.first(10))
      }.not_to raise_error

      expect(channel.notification_subscriptions.where(event_key: "initiation.material_returned").count).to eq(1)
    end
  end

  describe "#subscribed_event_keys" do
    it "returns enabled subscription event keys" do
      channel = create(:notification_channel)
      create(:notification_subscription, notification_channel: channel, event_key: "order.paid", enabled: true)
      create(:notification_subscription, notification_channel: channel, event_key: "payment.failed", enabled: false)

      expect(channel.subscribed_event_keys).to eq([ "order.paid" ])
    end
  end

  describe "audit trail" do
    it "creates an audit log on creation" do
      expect {
        create(:notification_channel, name: "Test Channel", enabled: true)
      }.to change(AuditLog, :count).by(1)

      log = AuditLog.last
      expect(log.action).to eq("created")
      expect(log.target_type).to eq("NotificationChannel")
      expect(log.actor_user_id).to be_nil
      expect(log.metadata).to include("name" => "Test Channel", "enabled" => true)
    end

    it "creates an audit log on update" do
      channel = create(:notification_channel, enabled: true)

      expect {
        channel.update!(enabled: false)
      }.to change(AuditLog, :count).by(1)

      log = AuditLog.last
      expect(log.action).to eq("updated")
      expect(log.target_type).to eq("NotificationChannel")
      expect(log.metadata["changes"]).to include("enabled" => [ true, false ])
    end

    it "creates an audit log on destruction" do
      channel = create(:notification_channel)

      expect {
        channel.destroy!
      }.to change(AuditLog, :count).by(1)

      log = AuditLog.last
      expect(log.action).to eq("destroyed")
      expect(log.target_type).to eq("NotificationChannel")
    end
  end
end
