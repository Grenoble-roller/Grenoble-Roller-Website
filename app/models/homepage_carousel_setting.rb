# frozen_string_literal: true

class HomepageCarouselSetting < ApplicationRecord
  INTERVAL_SECONDS_RANGE = (2..30).freeze
  SINGLETON_ID = 1
  DEFAULT_HERO_IMAGE_PATH = "/img/Roller-Luminous2.png"
  HERO_IMAGE_CONTENT_TYPES = %w[image/jpeg image/png image/webp].freeze

  has_one_attached :hero_image

  validates :interval_seconds,
            presence: true,
            numericality: { only_integer: true, in: INTERVAL_SECONDS_RANGE }
  validate :hero_image_must_be_supported, if: -> { hero_image.attached? }

  def self.current
    find_or_create_by!(id: SINGLETON_ID) do |setting|
      setting.autoplay_enabled = true
      setting.interval_seconds = 6
    end
  end

  def interval_ms
    interval_seconds * 1000
  end

  def custom_hero_image?
    hero_image.attached?
  end

  def hero_image_banner_variant
    return unless custom_hero_image?

    hero_image.variant(
      resize_to_limit: [ 1280, 720 ],
      format: :webp,
      saver: { quality: 80 }
    )
  end

  private

  def hero_image_must_be_supported
    return unless hero_image.blob

    unless HERO_IMAGE_CONTENT_TYPES.include?(hero_image.blob.content_type)
      errors.add(:hero_image, "doit être au format JPEG, PNG ou WebP")
    end
  end
end
