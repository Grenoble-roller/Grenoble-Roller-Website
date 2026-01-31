# frozen_string_literal: true

class HomepageCarousel < ApplicationRecord
  # Active Storage attachment
  has_one_attached :image

  # Validations
  validates :title, presence: true
  validates :image, presence: true, if: -> { published? }

  # Scopes
  scope :published, -> { where(published: true) }
  # Visible sur la page d'accueil : publié + date de publication passée (ou non renseignée) + non expiré
  scope :active, -> {
    published.where(
      "(published_at IS NULL OR published_at <= ?) AND (expires_at IS NULL OR expires_at > ?)",
      Time.current,
      Time.current
    )
  }
  scope :ordered, -> { order(position: :asc, created_at: :desc) }
  # Slides programmés : non publiés mais avec une date de publication à venir (pour le job de publication auto)
  scope :scheduled_to_publish, -> { where(published: false).where("published_at IS NOT NULL AND published_at <= ?", Time.current) }

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
    published? &&
      (published_at.nil? || published_at <= Time.current) &&
      (expires_at.nil? || expires_at > Time.current)
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
