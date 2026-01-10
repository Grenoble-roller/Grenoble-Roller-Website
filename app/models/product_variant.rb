class ProductVariant < ApplicationRecord
  belongs_to :product
  has_many :variant_option_values, foreign_key: :variant_id, dependent: :destroy
  has_many :option_values, through: :variant_option_values

  # Active Storage attachments - Images multiples
  has_many_attached :images

  # Relation avec inventaire
  has_one :inventory, dependent: :destroy

  # VALIDATIONS
  validates :sku, presence: true, uniqueness: true,
            format: { with: /\A[A-Z0-9-]+\z/, message: "format invalide" }
  validates :price_cents, numericality: { greater_than: 0 }
  validates :stock_qty, numericality: { greater_than_or_equal_to: 0 }
  validates :currency, length: { is: 3 }
  validate :image_present
  validate :has_required_option_values
  validate :image_required_if_active

  # NOUVEAU : Héritage prix/stock
  attr_accessor :inherit_price, :inherit_stock

  before_save :apply_inheritance
  after_create :create_inventory_record
  after_update :sync_inventory_stock, if: :saved_change_to_stock_qty?

  # SCOPES
  scope :active, -> { where(is_active: true) }
  scope :by_sku, ->(sku) { where(sku: sku) }
  scope :by_option, ->(option_value_id) {
    joins(:variant_option_values)
      .where(variant_option_values: { option_value_id: option_value_id })
  }

  def self.ransackable_attributes(_auth_object = nil)
    %w[id product_id sku price_cents currency stock_qty is_active created_at updated_at]
  end

  def self.ransackable_associations(_auth_object = nil)
    %w[product option_values]
  end

  private

  def has_required_option_values
    # Si le produit a plusieurs variantes, celle-ci doit avoir des options
    return unless product
    return if @skip_option_validation # Permettre de contourner la validation (ex: seed)
    return if variant_option_values.any? || product.product_variants.count <= 1
    errors.add(:base, "Les variantes doivent avoir des options de catégorisation")
  end

  def apply_inheritance
    self.price_cents = product.price_cents if inherit_price.present?
    self.stock_qty = 0 if inherit_stock.present?
  end

  def image_present
    # Permettre la création sans image si la variante est inactive
    return unless is_active?
    return if images.attached?
    # Permettre la création sans image si le produit parent a une image (héritage)
    return if product&.image&.attached?
    # Permettre la création sans image lors de la génération automatique (skip_validation)
    return if @skip_image_validation
    errors.add(:base, "Une image (upload fichier) est requise")
  end

  def image_required_if_active
    # Si la variante est active, elle doit avoir une image
    return unless is_active?
    return if images.attached?
    # Permettre si le produit parent a une image (héritage)
    return if product&.image&.attached?
    errors.add(:base, "Une image est requise pour activer la variante")
  end

  def create_inventory_record
    Inventory.create!(
      product_variant: self,
      stock_qty: stock_qty || 0,
      reserved_qty: 0
    )
  end

  def sync_inventory_stock
    # Synchroniser le stock_qty de l'inventaire avec celui de la variante
    # IMPORTANT: On synchronise inventory.stock_qty avec variant.stock_qty
    # La différence entre les deux représente l'ajustement de stock
    if inventory
      old_inv_stock = inventory.stock_qty
      new_inv_stock = stock_qty
      difference = new_inv_stock - old_inv_stock

      if difference != 0
        # Mettre à jour le stock de l'inventaire pour qu'il corresponde à celui de la variante
        inventory.update_column(:stock_qty, new_inv_stock)
        # Enregistrer le mouvement pour traçabilité
        inventory.movements.create!(
          quantity: difference,
          reason: "adjustment",
          reference: "variant_#{id}_update",
          before_qty: old_inv_stock
        )
      end
    else
      # Si l'inventaire n'existe pas, le créer avec le stock actuel de la variante
      create_inventory_record
    end
  end
end
