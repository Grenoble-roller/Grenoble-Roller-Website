# 🔧 SERVICES - Boutique

**Priorité** : 🔴 HAUTE | **Phase** : 1-2 | **Semaine** : 1-2

---

## 📋 Description

Services pour gérer l'inventaire, la génération de variantes et l'export de produits.

---

## ✅ Service 1 : InventoryService

**Fichier** : `app/services/inventory_service.rb`

**Code exact** :
```ruby
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
```

**Checklist** :
- [x] Créer fichier `app/services/inventory_service.rb`
- [x] Tester `reserve_stock` / `release_stock`
- [x] Tester `move_stock`
- [x] Tester `available_stock`
- [x] Exécuter `migrate_existing_stock` après migrations (si nécessaire)

---

## ✅ Service 2 : ProductVariantGenerator (EXISTANT - Vérifier)

**Fichier** : `app/services/product_variant_generator.rb`

**Code existant (à vérifier)** :
```ruby
class ProductVariantGenerator
  def self.generate(product, option_types)
    # Génère toutes les combinaisons de variantes
    # Exemple : Taille (S, M, L) × Couleur (Rouge, Bleu)
    # → 6 variantes
    
    combinations = option_types.map(&:option_values).reduce(&:product)
    
    combinations.each do |combo|
      ProductVariant.create!(
        product: product,
        sku: generate_sku(product, combo),
        option_values: combo,
        price_cents: product.price_cents,
        stock_qty: 0
      )
    end
  end
  
  private
  
  def self.generate_sku(product, option_values)
    base = product.slug.upcase
    options = option_values.map { |ov| ov.value[0..2].upcase }.join('-')
    "#{base}-#{options}"
  end
end
```

**Checklist** :
- [ ] Vérifier si service existe
- [ ] Adapter pour créer inventaire automatiquement
- [ ] Tester génération variantes

---

## ✅ Service 3 : ProductExporter (EXISTANT - Vérifier)

**Fichier** : `app/services/product_exporter.rb`

**Code existant (à vérifier)** :
```ruby
class ProductExporter
  def self.to_csv(products)
    require 'csv'
    
    CSV.generate(headers: true) do |csv|
      csv << ['ID', 'Nom', 'SKU', 'Prix', 'Stock', 'Catégorie', 'Statut']
      
      products.each do |product|
        product.product_variants.each do |variant|
          csv << [
            variant.id,
            product.name,
            variant.sku,
            variant.price_cents / 100.0,
            variant.inventory&.available_qty || 0,
            product.category&.name,
            variant.is_active? ? 'Actif' : 'Inactif'
          ]
        end
      end
    end
  end
end
```

**Checklist** :
- [ ] Vérifier si service existe
- [ ] Adapter pour utiliser `inventory.available_qty`
- [ ] Tester export CSV

---

## ✅ Checklist Globale

### **Phase 1 (Semaine 1)** ✅
- [x] Créer InventoryService
- [x] Tester toutes les méthodes
- [x] Exécuter migration stock existant (si nécessaire)

### **Phase 2 (Semaine 2)** ✅
- [x] Vérifier ProductVariantGenerator (existe, utilisé pour preview)
- [x] Vérifier ProductExporter (existe, utilisé pour export CSV)
- [x] Adapter pour inventaires (utilise `inventory.available_qty`)

---

**Retour** : [README Boutique](./README.md) | [INDEX principal](../INDEX.md)
