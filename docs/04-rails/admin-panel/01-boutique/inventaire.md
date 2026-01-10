# 🛒 BOUTIQUE - Inventaire

**Priorité** : 🔴 HAUTE | **Phase** : 1-2 | **Semaines** : 1-2

---

## 📋 Description

Système de tracking stock avancé : inventaires, mouvements, dashboard, ajustements.

**Objectif** : Séparer le stock de `product_variants` pour permettre réservation/libération et audit trail complet.

---

## 🗄️ Migrations

### **Migration 1 : Table Inventories**

**Fichier** : `db/migrate/YYYYMMDDHHMMSS_create_inventories.rb`

```ruby
class CreateInventories < ActiveRecord::Migration[8.1]
  def change
    create_table :inventories do |t|
      t.references :product_variant, null: false, foreign_key: true
      t.integer :stock_qty, default: 0, null: false
      t.integer :reserved_qty, default: 0, null: false
      t.timestamps
    end
    
    add_index :inventories, :product_variant_id, unique: true
  end
end
```

### **Migration 2 : Table InventoryMovements**

**Fichier** : `db/migrate/YYYYMMDDHHMMSS_create_inventory_movements.rb`

```ruby
class CreateInventoryMovements < ActiveRecord::Migration[8.1]
  def change
    create_table :inventory_movements do |t|
      t.references :inventory, null: false, foreign_key: true
      t.references :user, null: true, foreign_key: true
      t.integer :quantity, null: false
      t.string :reason, null: false
      t.string :reference
      t.integer :before_qty, null: false
      t.timestamps
    end
    
    add_index :inventory_movements, :inventory_id
    add_index :inventory_movements, :created_at
  end
end
```

---

## 🏗️ Modèles

### **Modèle Inventory**

**Fichier** : `app/models/inventory.rb`

```ruby
class Inventory < ApplicationRecord
  belongs_to :product_variant
  has_many :movements, class_name: 'InventoryMovement', dependent: :destroy
  
  validates :product_variant_id, presence: true, uniqueness: true
  validates :stock_qty, numericality: { greater_than_or_equal_to: 0 }
  validates :reserved_qty, numericality: { greater_than_or_equal_to: 0 }
  
  def available_qty
    stock_qty - reserved_qty
  end
  
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

### **Modèle InventoryMovement**

**Fichier** : `app/models/inventory_movement.rb`

```ruby
class InventoryMovement < ApplicationRecord
  belongs_to :inventory
  belongs_to :user, optional: true
  
  REASONS = %w[
    initial_stock purchase adjustment damage loss return
    reserved released order_fulfilled
  ].freeze
  
  validates :reason, inclusion: { in: REASONS }
  validates :quantity, presence: true
  
  scope :recent, -> { order(created_at: :desc) }
end
```

---

## 🔧 Service

### **Service InventoryService**

**Fichier** : `app/services/inventory_service.rb`

```ruby
class InventoryService
  def self.reserve_stock(variant, quantity, order_id)
    inventory = variant.inventory || create_inventory(variant)
    inventory.reserve_stock(quantity, order_id)
  end
  
  def self.release_stock(variant, quantity, order_id)
    return unless variant.inventory
    variant.inventory.release_stock(quantity, order_id)
  end
  
  def self.move_stock(variant, quantity, reason, reference = nil)
    inventory = variant.inventory || create_inventory(variant)
    inventory.move_stock(quantity, reason, reference, Current.user)
  end
  
  def self.available_stock(variant)
    return 0 unless variant.inventory
    variant.inventory.available_qty
  end
  
  private
  
  def self.create_inventory(variant)
    Inventory.create!(
      product_variant: variant,
      stock_qty: variant.stock_qty || 0,
      reserved_qty: 0
    )
  end
end
```

---

## 🎮 Controller

### **Controller InventoryController**

**Fichier** : `app/controllers/admin_panel/inventory_controller.rb`

```ruby
module AdminPanel
  class InventoryController < BaseController
    before_action :authorize_inventory
    
    def index
      @low_stock = ProductVariant
        .joins(:inventory)
        .where('(inventories.stock_qty - inventories.reserved_qty) <= ?', 10)
        .where(is_active: true)
        .order(Arel.sql('(inventories.stock_qty - inventories.reserved_qty) ASC'))
      
      @out_of_stock = ProductVariant
        .joins(:inventory)
        .where('(inventories.stock_qty - inventories.reserved_qty) <= 0')
        .where(is_active: true)
      
      @movements = InventoryMovement
        .recent
        .includes(:inventory, :user)
        .limit(50)
    end
    
    def transfers
      @movements = InventoryMovement
        .recent
        .includes(:inventory, :user, inventory: :product_variant)
      
      @pagy, @movements = pagy(@movements, items: 25)
    end
    
    def adjust_stock
      variant = ProductVariant.find(params[:variant_id])
      quantity = params[:quantity].to_i
      reason = params[:reason]
      
      InventoryService.move_stock(variant, quantity, reason, params[:reference])
      
      redirect_back notice: 'Stock ajusté avec succès'
    end
    
    private
    
    def authorize_inventory
      authorize [:admin_panel, Inventory]
    end
  end
end
```

---

## 🛣️ Routes

**Fichier** : `config/routes.rb`

```ruby
# Inventory routes
get 'inventory', to: 'inventory#index'
get 'inventory/transfers', to: 'inventory#transfers'
patch 'inventory/adjust_stock', to: 'inventory#adjust_stock'
```

---

## 🎨 Vues

### **Vue Index (Dashboard)**

**Fichier** : `app/views/admin_panel/inventory/index.html.erb`

```erb
<h1>Inventaire - Dashboard</h1>

<div class="row g-4 mb-4">
  <div class="col-md-4">
    <div class="card">
      <div class="card-body">
        <h5 class="card-title">⚠️ Stock Faible</h5>
        <h2 class="text-warning"><%= @low_stock.count %> produits</h2>
        <small class="text-muted">&lt; 10 unités</small>
      </div>
    </div>
  </div>
  
  <div class="col-md-4">
    <div class="card">
      <div class="card-body">
        <h5 class="card-title">🔴 Rupture</h5>
        <h2 class="text-danger"><%= @out_of_stock.count %> produits</h2>
        <small class="text-muted">0 unité disponible</small>
      </div>
    </div>
  </div>
</div>

<div class="card">
  <div class="card-header">
    <h5 class="mb-0">Mouvements Récents</h5>
  </div>
  <table class="table mb-0">
    <thead class="table-light">
      <tr>
        <th>Produit</th>
        <th>Raison</th>
        <th>Quantité</th>
        <th>Avant</th>
        <th>Date</th>
        <th>Par</th>
      </tr>
    </thead>
    <tbody>
      <% @movements.each do |movement| %>
        <tr>
          <td><%= movement.inventory.product_variant.sku %></td>
          <td><span class="badge bg-info"><%= movement.reason %></span></td>
          <td><%= number_with_precision(movement.quantity, precision: 0) %></td>
          <td><%= movement.before_qty %></td>
          <td><%= l(movement.created_at, format: :short) %></td>
          <td><%= movement.user&.name || 'Système' %></td>
        </tr>
      <% end %>
    </tbody>
  </table>
</div>
```

### **Vue Transfers**

**Fichier** : `app/views/admin_panel/inventory/transfers.html.erb`

- Liste paginée des mouvements
- Filtres par raison, date, produit
- Export CSV

---

## 🔐 Policy

### **Policy InventoryPolicy**

**Fichier** : `app/policies/admin_panel/inventory_policy.rb`

```ruby
module AdminPanel
  class InventoryPolicy < BasePolicy
    def index?
      admin_user?
    end
    
    def transfers?
      admin_user?
    end
    
    def adjust_stock?
      admin_user?
    end
  end
end
```

---

## ✅ Checklist Globale

### **Phase 1 (Semaine 1)** ✅
- [x] Migration inventories table
- [x] Migration inventory_movements table
- [x] Modèle Inventory
- [x] Modèle InventoryMovement
- [x] Service InventoryService

### **Phase 2 (Semaine 2)** ✅
- [x] Controller InventoryController
- [x] Policy InventoryPolicy
- [x] Routes inventory (3 routes)
- [x] Vue Inventory Index
- [x] Vue Inventory Transfers (route créée)
- [x] Corriger requêtes SQL : utiliser `(stock_qty - reserved_qty)` au lieu de `available_qty`
- [x] Utiliser `Arel.sql()` pour expressions SQL dans `order()`

---

**Retour** : [README Boutique](./README.md) | [INDEX principal](../INDEX.md)
