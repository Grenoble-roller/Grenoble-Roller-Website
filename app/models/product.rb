class Product < ApplicationRecord
  include Hashid::Rails

  belongs_to :category, class_name: "ProductCategory"
  has_many :product_variants, dependent: :destroy

  # Active Storage attachments
  has_one_attached :image

  # VALIDATIONS
  validates :name, :slug, :price_cents, :currency, presence: true
  validate :image_present
  validates :name, length: { maximum: 140 }
  validates :slug, length: { maximum: 160 }, uniqueness: true
  validates :currency, length: { is: 3 }
  validate :has_at_least_one_active_variant

  # SCOPES
  scope :active, -> { where(is_active: true) }
  scope :inactive, -> { where(is_active: false) }
  scope :by_category, ->(id) { where(category_id: id) }
  scope :by_status, ->(status) { where(is_active: status == "active") }
  scope :search_by_name, ->(term) { where("name ILIKE ?", "%#{term}%") }

  scope :in_stock, -> {
    joins(:product_variants)
      .where(product_variants: { is_active: true })
      .group("products.id")
      .having("SUM(product_variants.stock_qty) > 0")
  }

  scope :out_of_stock, -> {
    left_joins(:product_variants)
      .group("products.id")
      .having("SUM(product_variants.stock_qty) IS NULL OR SUM(product_variants.stock_qty) = 0")
  }

  scope :by_stock_status, ->(status) {
    status == "in_stock" ? in_stock : out_of_stock
  }

  # NOUVEAU : Eager loading + pagination support
  scope :with_associations, -> {
    includes(:category, :image_attachment, product_variants: [ :variant_option_values, :option_values ])
  }

  # CALLBACKS
  before_save :generate_slug, if: :name_changed?

  # METHODS
  def total_stock
    product_variants.where(is_active: true).sum(:stock_qty)
  end

  def in_stock?
    total_stock > 0
  end

  def price
    price_cents / 100.0
  end

  # NOUVEAU : Héritage image pour variantes
  def image_for_variant(variant)
    variant.image.attached? ? variant.image : self.image
  end

  # NOUVEAU : Agrégat stock par option
  def stock_by_option(option_type)
    product_variants
      .joins(variant_option_values: :option_value)
      .where(option_values: { option_type_id: option_type.id })
      .group("option_values.presentation")
      .sum(:stock_qty)
  end

  def self.ransackable_attributes(_auth_object = nil)
    %w[id category_id name slug description price_cents currency stock_qty is_active image_url created_at updated_at]
  end

  def self.ransackable_associations(_auth_object = nil)
    %w[category product_variants]
  end

  private

  def generate_slug
    self.slug = name.parameterize if slug.blank?
  end

  def image_present
    return if image.attached?
    errors.add(:base, "Une image est requise")
  end

  def has_at_least_one_active_variant
    # Ne pas valider lors de la création si des variantes seront générées automatiquement
    # La validation s'applique seulement pour les produits déjà persistés
    return unless persisted?
    # Ne pas valider lors d'un save_draft (auto-save) ou lors de la génération de variantes manquantes
    return if @skip_variant_validation || @save_draft || @generate_missing
    # Si le produit a déjà des variantes (même inactives), on peut permettre la génération de nouvelles
    # La validation ne s'applique que si le produit n'a aucune variante du tout
    return if product_variants.exists?(is_active: true)
    # Si le produit a des variantes mais qu'elles sont toutes inactives, on permet quand même
    # (l'utilisateur pourra les réactiver ou en créer de nouvelles)
    return if product_variants.any?
    errors.add(:base, "Au moins une variante active requise")
  end
end
