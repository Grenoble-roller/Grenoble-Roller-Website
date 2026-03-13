class InventoryService
  # Réserver du stock pour une commande
  def self.reserve_stock(variant, quantity, order_id)
    inventory = variant.inventory || create_inventory(variant)
    inventory.reserve_stock(quantity, order_id)
  end

  # Libérer du stock réservé (commande annulée)
  def self.release_stock(variant, quantity, order_id)
    return unless variant.inventory
    variant.inventory.release_stock(quantity, order_id)
  end

  # Déplacer du stock (ajustement, achat, etc.)
  def self.move_stock(variant, quantity, reason, reference = nil)
    inventory = variant.inventory || create_inventory(variant)
    inventory.move_stock(quantity, reason, reference, Current.user)
  end

  # Obtenir stock disponible
  def self.available_stock(variant)
    return 0 unless variant.inventory
    variant.inventory.available_qty
  end

  # Créer inventaire si inexistant
  def self.create_inventory(variant)
    Inventory.create!(
      product_variant: variant,
      stock_qty: variant.stock_qty || 0,
      reserved_qty: 0
    )
  end

  # Migrer stock existant vers inventaires
  def self.migrate_existing_stock
    ProductVariant.find_each do |variant|
      next if variant.inventory.present?

      create_inventory(variant)
      Rails.logger.info "✅ Inventaire créé pour variant #{variant.id}"
    end
  end
end
