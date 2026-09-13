# frozen_string_literal: true

require "rails_helper"

RSpec.describe NotificationDelivery, type: :model do
  describe "validations" do
    it "requires event_key, source reference, and status" do
      delivery = build(:notification_delivery, event_key: nil, source_type: nil, source_id: nil, status: nil)
      expect(delivery).not_to be_valid
      expect(delivery.errors[:event_key]).to be_present
      expect(delivery.errors[:source_type]).to be_present
      expect(delivery.errors[:source_id]).to be_present
      expect(delivery.errors[:status]).to be_present
    end
  end

  describe "idempotency unique index" do
    it "allows only one delivery per channel, event, and source" do
      channel = create(:notification_channel)
      order = create(:order)

      create(:notification_delivery, notification_channel: channel, event_key: "order.paid", source_type: "Order", source_id: order.id)

      duplicate = build(:notification_delivery, notification_channel: channel, event_key: "order.paid", source_type: "Order", source_id: order.id)
      expect { duplicate.save!(validate: false) }.to raise_error(ActiveRecord::RecordNotUnique)
    end

    it "allows same event for different sources" do
      channel = create(:notification_channel)
      order1 = create(:order)
      order2 = create(:order)

      expect {
        create(:notification_delivery, notification_channel: channel, event_key: "order.paid", source_type: "Order", source_id: order1.id)
        create(:notification_delivery, notification_channel: channel, event_key: "order.paid", source_type: "Order", source_id: order2.id)
      }.not_to raise_error
    end

    it "allows same source for different event keys" do
      channel = create(:notification_channel)
      order = create(:order)

      expect {
        create(:notification_delivery, notification_channel: channel, event_key: "order.paid", source_type: "Order", source_id: order.id)
        create(:notification_delivery, notification_channel: channel, event_key: "order.updated", source_type: "Order", source_id: order.id)
      }.not_to raise_error
    end
  end

  describe "audit trail" do
    it "creates an audit log on creation" do
      expect {
        create(:notification_delivery)
      }.to change { AuditLog.where(target_type: 'NotificationDelivery').count }.by(1)

      log = AuditLog.find_by!(target_type: 'NotificationDelivery', action: 'created')
      expect(log.actor_user_id).to be_nil
      expect(log.metadata).to include('event_key', 'status' => 'pending')
    end

    it "creates an audit log on update" do
      delivery = create(:notification_delivery)

      expect {
        delivery.update!(status: 'delivered')
      }.to change { AuditLog.where(target_type: 'NotificationDelivery').count }.by(1)

      log = AuditLog.find_by!(target_type: 'NotificationDelivery', action: 'updated')
      expect(log.metadata['changes']).to include('status')
    end

    it "creates an audit log on destruction" do
      delivery = create(:notification_delivery)

      expect {
        delivery.destroy
      }.to change { AuditLog.where(target_type: 'NotificationDelivery').count }.by(1)

      expect(AuditLog.exists?(target_type: 'NotificationDelivery', action: 'destroyed')).to be(true)
    end
  end
end
