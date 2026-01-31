# frozen_string_literal: true

class HomepageCarousel < ApplicationRecord
  # Active Storage attachment
  has_one_attached :image

  # Validations
  validates :title, presence: true
  validates :image, presence: true, if: -> { published? }

  # Scopes
  scope :published, -> { where(published: true) }
  # Visible sur la page d'accueil :
  # - Publié coché : visible tout de suite jusqu'à expires_at (publication forcée)
  # - Publié non coché : visible uniquement entre published_at et expires_at (dates seules)
  scope :active, -> {
    now = Time.current
    where(
      "(published = true AND (expires_at IS NULL OR expires_at > ?)) OR " \
      "(published = false AND published_at IS NOT NULL AND published_at <= ? AND (expires_at IS NULL OR expires_at > ?))",
      now, now, now
    )
  }
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
    now = Time.current
    if published?
      expires_at.nil? || expires_at > now
    else
      published_at.present? && published_at <= now && (expires_at.nil? || expires_at > now)
    end
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
