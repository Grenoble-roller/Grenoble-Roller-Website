class Inventory < ApplicationRecord
  belongs_to :product_variant
  has_many :movements, class_name: "InventoryMovement", dependent: :destroy

  validates :product_variant_id, presence: true, uniqueness: true
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
