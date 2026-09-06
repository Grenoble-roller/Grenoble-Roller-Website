# frozen_string_literal: true

class NotificationChannel < ApplicationRecord
  include Auditable

  ALLOWED_WEBHOOK_HOSTS = %w[discord.com discordapp.com www.discord.com].freeze

  has_many :notification_subscriptions, dependent: :destroy
  has_many :notification_deliveries, dependent: :destroy

  validates :name, presence: true
  validate :webhook_url_presence_on_create
  validate :webhook_url_host_allowed, if: -> { webhook_url.present? }

  attr_accessor :webhook_url

  before_validation :persist_webhook_url, if: -> { @webhook_url.present? }

  def webhook_url
    @webhook_url || decrypt_webhook_url
  end

  def webhook_url=(value)
    @webhook_url = value.presence
  end

  def masked_webhook_url
    url = webhook_url
    return nil if url.blank?

    uri = URI.parse(url)
    host = uri.host.to_s
    path = uri.path.to_s
    masked_path = path.length > 8 ? "#{path[0, 4]}***#{path[-4, 4]}" : "***"
    "#{uri.scheme}://#{host}#{masked_path}"
  rescue URI::InvalidURIError
    "https://discord…***"
  end

  def webhook_configured?
    webhook_url_ciphertext.present?
  end

  def enabled_subscriptions_count
    notification_subscriptions.where(enabled: true).count
  end

  def subscribed_event_keys
    notification_subscriptions.where(enabled: true).pluck(:event_key)
  end

  def sync_subscriptions!(event_keys)
    selected_keys = Array(event_keys).map(&:to_s).uniq

    NotificationEventRegistry.all.each do |event|
      next if event.key == "test.ping"

      subscription = NotificationSubscription.find_or_initialize_by(
        notification_channel_id: id,
        event_key: event.key
      )
      subscription.enabled = selected_keys.include?(event.key)
      subscription.save!
    end

    notification_subscriptions.reset
  end

  private

  def audit_attributes
    {
      name: name,
      enabled: enabled
    }
  end

  def webhook_url_presence_on_create
    return unless new_record?

    errors.add(:webhook_url, "can't be blank") unless webhook_url.present?
  end

  def webhook_url_host_allowed
    uri = URI.parse(webhook_url)
    return if ALLOWED_WEBHOOK_HOSTS.include?(uri.host.to_s)

    errors.add(:webhook_url, "must be a Discord webhook URL (discord.com or discordapp.com)")
  rescue URI::InvalidURIError
    errors.add(:webhook_url, "is not a valid URL")
  end

  def persist_webhook_url
    self.webhook_url_ciphertext = encrypt_webhook_url(@webhook_url)
  end

  def encrypt_webhook_url(value)
    if ar_encryption_available?
      encrypt_with_active_record(value)
    else
      message_encryptor.encrypt_and_sign(value)
    end
  end

  def decrypt_webhook_url
    return nil if webhook_url_ciphertext.blank?

    if ar_encryption_available?
      decrypt_with_active_record(webhook_url_ciphertext)
    else
      message_encryptor.decrypt_and_verify(webhook_url_ciphertext)
    end
  rescue ActiveSupport::MessageEncryptor::InvalidMessage
    nil
  end

  def ar_encryption_available?
    self.class.respond_to?(:encryption_enabled?) && self.class.encryption_enabled?
  end

  def encrypt_with_active_record(value)
    cipher = ActiveRecord::Encryption.encrypt(value)
    cipher.is_a?(String) ? cipher : cipher.to_s
  end

  def decrypt_with_active_record(ciphertext)
    ActiveRecord::Encryption.decrypt(ciphertext)
  end

  def message_encryptor
    key = ActiveSupport::KeyGenerator.new(Rails.application.secret_key_base)
                                     .generate_key("notification-channel-webhook-url", 32)
    ActiveSupport::MessageEncryptor.new(key)
  end
end
