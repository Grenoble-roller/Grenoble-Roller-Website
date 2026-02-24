class Inventory < ApplicationRecord
  belongs_to :product_variant
  has_many :movements, class_name: "InventoryMovement", dependent: :destroy

  validates :product_variant_id, presence: true, uniqueness: true

  def self.ransackable_attributes(auth_object = nil)
    %w[created_at id product_variant_id reserved_qty stock_qty updated_at]
  end

  def self.ransackable_associations(auth_object = nil)
    %w[product_variant movements]
  end
  validates :stock_qty, numericality: { greater_than_or_equal_to: 0 }
  validates :reserved_qty, numericality: { greater_than_or_equal_to: 0 }

  # Quantité disponible = stock - réservé
  def available_qty
    stock_qty - reserved_qty
  end

  # Déplacer du stock (ajustement, achat, etc.)
  def move_stock(quantity, reason, reference = nil, user = nil)
    movements.create!(
      quantity: quantity,
      reason: reason,
      reference: reference,
      before_qty: stock_qty,
      user: user
    )
    update_column(:stock_qty, stock_qty + quantity)
  end

  # Réserver du stock (commande en cours)
  def reserve_stock(quantity, order_id, user = nil)
    increment!(:reserved_qty, quantity)
    movements.create!(
      quantity: 0,
      reason: "reserved",
      reference: order_id.to_s,
      before_qty: stock_qty,
      user: user || (defined?(Current) ? Current.user : nil)
    )
  end

  # Libérer du stock (commande annulée)
  def release_stock(quantity, order_id, user = nil)
    decrement!(:reserved_qty, quantity)
    movements.create!(
      quantity: 0,
      reason: "released",
      reference: order_id.to_s,
      before_qty: stock_qty,
      user: user || (defined?(Current) ? Current.user : nil)
    )
  end
end
