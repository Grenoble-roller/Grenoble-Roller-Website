# 🏗️ MODÈLES - Boutique

**Priorité** : 🔴 HAUTE | **Phase** : 1 | **Semaine** : 1

---

## 📋 Description

Modifications des modèles existants et création de nouveaux modèles pour l'inventaire.

---

## ✅ Modèle 1 : Inventory (NOUVEAU)

**Fichier** : `app/models/inventory.rb`

**Code exact** :
```ruby
class Inventory < ApplicationRecord
  belongs_to :product_variant
  has_many :movements, class_name: 'InventoryMovement', dependent: :destroy
  
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
  def reserve_stock(quantity, order_id)
    increment!(:reserved_qty, quantity)
    movements.create!(
      quantity: 0,
      reason: 'reserved',
      reference: order_id.to_s,
      before_qty: stock_qty,
      user: Current.user
    )
  end
  
  # Libérer du stock (commande annulée)
  def release_stock(quantity, order_id)
    decrement!(:reserved_qty, quantity)
    movements.create!(
      quantity: 0,
      reason: 'released',
      reference: order_id.to_s,
      before_qty: stock_qty,
      user: Current.user
    )
  end
end
```

**Checklist** :
- [x] Créer fichier `app/models/inventory.rb`
- [x] Tester méthodes `available_qty`, `move_stock`, `reserve_stock`, `release_stock`
- [x] Vérifier validations
- [x] Ajouter scopes Ransack pour recherche

---

## ✅ Modèle 2 : InventoryMovement (NOUVEAU)

**Fichier** : `app/models/inventory_movement.rb`

**Code exact** :
```ruby
class InventoryMovement < ApplicationRecord
  belongs_to :inventory
  belongs_to :user, optional: true
  
  REASONS = %w[
    initial_stock
    purchase
    adjustment
    damage
    loss
    return
    reserved
    released
    order_fulfilled
  ].freeze
  
  validates :reason, inclusion: { in: REASONS }
  validates :quantity, presence: true
  
  scope :recent, -> { order(created_at: :desc) }
  scope :by_reason, ->(reason) { where(reason: reason) }
  
  def self.ransackable_attributes(_auth_object = nil)
    %w[id inventory_id user_id quantity reason reference created_at]
  end
  
  def self.ransackable_associations(_auth_object = nil)
    %w[inventory user]
  end
end
```

**Checklist** :
- [x] Créer fichier `app/models/inventory_movement.rb`
- [x] Vérifier constantes REASONS
- [x] Tester scopes (`recent`, `by_reason`)
- [x] Ajouter scopes Ransack pour recherche

---

## ✅ Modèle 3 : ProductVariant (MODIFICATION)

**Fichier** : `app/models/product_variant.rb`

**Modifications à apporter** :

**AVANT** :
```ruby
has_one_attached :image
validate :image_or_image_url_present

private

def image_or_image_url_present
  return if image.attached? || image_url.present?
  errors.add(:base, 'Une image est requise (upload ou URL)')
end
```

**APRÈS** :
```ruby
# Images multiples via Active Storage
has_many_attached :images

# Relation avec inventaire
has_one :inventory, dependent: :destroy

# Callback pour créer inventaire automatiquement
after_create :create_inventory_record

# Validation : upload fichier obligatoire (plus d'URL)
validate :image_present

private

def image_present
  return if images.attached?
  errors.add(:base, 'Une image (upload fichier) est requise')
end

def create_inventory_record
  Inventory.create!(
    product_variant: self,
    stock_qty: stock_qty || 0,
    reserved_qty: 0
  )
end
```

**Checklist** :
- [x] Remplacer `has_one_attached :image` par `has_many_attached :images`
- [x] Supprimer validation `image_or_image_url_present`
- [x] Ajouter validation `image_present`
- [x] Ajouter relation `has_one :inventory`
- [x] Ajouter callback `after_create :create_inventory_record`
- [x] Tester création variant avec images multiples
- [x] Vérifier inventaire créé automatiquement
- [x] Ajouter scopes Ransack pour recherche

---

## ✅ Modèle 4 : Product (MODIFICATION)

**Fichier** : `app/models/product.rb`

**Modifications à apporter** :

**Ajouter scope** :
```ruby
scope :with_associations, -> { includes(:category, product_variants: [:inventory, :option_values]) }
```

**Code complet (si nécessaire)** :
```ruby
class Product < ApplicationRecord
  belongs_to :category, class_name: 'ProductCategory', optional: true
  has_many :product_variants, dependent: :destroy
  
  # Scope pour optimiser les requêtes
  scope :with_associations, -> { 
    includes(:category, product_variants: [:inventory, :option_values]) 
  }
  
  scope :active, -> { where(is_active: true) }
  scope :published, -> { active }
  
  # ... reste du code existant
end
```

**Checklist** :
- [x] Ajouter scope `with_associations` (incluant inventory et images)
- [x] Vérifier utilisation dans ProductsController
- [x] Ajouter scopes `in_stock`, `out_of_stock`, `by_stock_status`
- [x] Ajouter méthode `total_stock` et `in_stock?`

---

## ✅ Modèle 5 : ProductCategory (MODIFICATION OPTIONNELLE)

**Fichier** : `app/models/product_category.rb`

**Modifications optionnelles (si hiérarchie nécessaire)** :

```ruby
# Si migration parent_id effectuée
belongs_to :parent, class_name: 'ProductCategory', optional: true
has_many :children, class_name: 'ProductCategory', foreign_key: 'parent_id'

# Optionnel : utiliser acts_as_tree gem
# acts_as_tree order: 'name'
```

**Checklist** :
- [ ] Ajouter relations parent/children (si migration effectuée)
- [ ] Optionnel : Ajouter gem `acts_as_tree` si hiérarchie complexe

---

## 📊 Dépendances entre Modèles

```
Product
  └── ProductVariant
       ├── Inventory (has_one)
       │    └── InventoryMovement (has_many)
       └── VariantOptionValue
            └── OptionValue
                 └── OptionType
```

---

## ✅ Checklist Globale

### **Phase 1 (Semaine 1)** ✅
- [x] Créer modèle Inventory
- [x] Créer modèle InventoryMovement
- [x] Modifier ProductVariant (images + inventory)
- [x] Modifier Product (scope with_associations + méthodes stock)
- [ ] Optionnel : Modifier ProductCategory (parent_id) - Si hiérarchie nécessaire

---

**Retour** : [README Boutique](./README.md) | [INDEX principal](../INDEX.md)
