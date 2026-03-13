# frozen_string_literal: true

class HomepageCarousel < ApplicationRecord
  # Active Storage attachment
  has_one_attached :image

  # Validations
  validates :title, presence: true
  validates :image, presence: true, if: -> { published? }

  # Scopes
  scope :published, -> { where(published: true) }
  scope :active, -> { published.where("expires_at IS NULL OR expires_at > ?", Time.current) }
  scope :ordered, -> { order(position: :asc, created_at: :desc) }

  # Ransack pour recherche/filtres
  def self.ransackable_attributes(_auth_object = nil)
    %w[id title subtitle link_url position published published_at expires_at created_at updated_at]
  end

  def self.ransackable_associations(_auth_object = nil)
    []
  end

  # Callbacks
  before_save :set_published_at, if: -> { published? && published_at.nil? }
  before_create :set_default_position

  def active?
    published? && (expires_at.nil? || expires_at > Time.current)
  end

  def expired?
    expires_at.present? && expires_at <= Time.current
  end

  private

  def set_published_at
    self.published_at = Time.current
  end

  def set_default_position
    self.position ||= (self.class.maximum(:position) || 0) + 1
  end
end
