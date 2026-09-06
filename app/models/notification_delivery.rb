# frozen_string_literal: true

class NotificationDelivery < ApplicationRecord
  include Auditable

  STATUSES = %w[pending delivered failed].freeze

  belongs_to :notification_channel

  validates :event_key, presence: true
  validates :source_type, presence: true
  validates :source_id, presence: true
  validates :status, inclusion: { in: STATUSES }

  scope :delivered, -> { where(status: "delivered") }

  private

  def audit_attributes
    {
      notification_channel_id: notification_channel_id,
      event_key: event_key,
      source_type: source_type,
      source_id: source_id,
      status: status
    }
  end
end
