# 🎮 CONTROLLERS - Boutique

**Priorité** : 🔴 HAUTE | **Phase** : 2-3 | **Semaine** : 2-3

---

## 📋 Description

Modifications et ajouts aux controllers existants pour gérer produits, variantes et inventaire.

---

## ✅ Controller 1 : ProductsController (MODIFICATIONS)

**Fichier** : `app/controllers/admin_panel/products_controller.rb`

**Modifications à apporter** :

### **1. Ajouter actions publish/unpublish**

**Code à ajouter** :
```ruby
# POST /admin-panel/products/:id/publish
def publish
  @product = Product.find(params[:id])
  authorize [:admin_panel, @product]
  
  if @product.update(is_active: true)
    flash[:notice] = 'Produit publié avec succès'
  else
    flash[:alert] = "Erreur : #{@product.errors.full_messages.join(', ')}"
  end
  
  redirect_to admin_panel_product_path(@product)
end

# POST /admin-panel/products/:id/unpublish
def unpublish
  @product = Product.find(params[:id])
  authorize [:admin_panel, @product]
  
  if @product.update(is_active: false)
    flash[:notice] = 'Produit dépublié avec succès'
  else
    flash[:alert] = "Erreur : #{@product.errors.full_messages.join(', ')}"
  end
  
  redirect_to admin_panel_product_path(@product)
end
```

### **2. Vérifier scope with_associations**

**Code existant (ligne 16)** :
```ruby
@products = @q.result.with_associations
```

**À modifier pour inclure inventory** :
```ruby
# Dans app/models/product.rb, modifier scope :
scope :with_associations, -> {
  includes(
    :category,
    :image_attachment,
    product_variants: [
      :inventory,
      :variant_option_values,
      :option_values,
      images_attachments: :blob
    ]
  )
}
```

**Checklist** :
- [x] Ajouter actions `publish` / `unpublish`
- [x] Modifier scope `with_associations` pour inclure `inventory`
- [x] Tester publication/dépublication

---

## ✅ Controller 2 : ProductVariantsController (MODIFICATIONS)

**Fichier** : `app/controllers/admin_panel/product_variants_controller.rb`

**Modifications à apporter** :

### **1. Ajouter action index (GRID)**

**Code à ajouter** :
```ruby
# GET /admin-panel/products/:product_id/product_variants
def index
  @variants = @product.product_variants
    .includes(:inventory, :option_values)
    .order(sku: :asc)
  
  @pagy, @variants = pagy(@variants, items: 50)
end
```

### **2. Ajouter actions bulk_edit / bulk_update**

**Code à ajouter** :
```ruby
# GET /admin-panel/products/:product_id/product_variants/bulk_edit
def bulk_edit
  @variant_ids = params[:variant_ids] || []
  @variants = @product.product_variants.where(id: @variant_ids)
  
  if @variants.empty?
    redirect_to admin_panel_product_product_variants_path(@product),
                alert: 'Aucune variante sélectionnée'
  end
end

# PATCH /admin-panel/products/:product_id/product_variants/bulk_update
def bulk_update
  variant_ids = params[:variant_ids] || []
  updates = params[:variants] || {}
  
  updated_count = 0
  variant_ids.each do |id|
    variant = @product.product_variants.find_by(id: id)
    next unless variant
    
    if updates[id.to_s].present?
      variant.update(updates[id.to_s].permit(:price_cents, :stock_qty, :is_active))
      updated_count += 1
    end
  end
  
  flash[:notice] = "#{updated_count} variante(s) mise(s) à jour"
  redirect_to admin_panel_product_product_variants_path(@product)
end
```

### **3. Ajouter action toggle_status**

**Code à ajouter** :
```ruby
# PATCH /admin-panel/products/:product_id/product_variants/:id/toggle_status
def toggle_status
  @variant.update(is_active: !@variant.is_active)
  
  respond_to do |format|
    format.html do
      redirect_back(
        fallback_location: admin_panel_product_product_variants_path(@product),
        notice: "Variante #{@variant.is_active ? 'activée' : 'désactivée'}"
      )
    end
    format.json { render json: { is_active: @variant.is_active } }
  end
end
```

### **4. Modifier variant_params pour images multiples**

**Code à modifier** :
```ruby
def variant_params
  params.require(:product_variant).permit(
    :sku,
    :price_cents,
    :currency,
    :stock_qty,
    :is_active,
    images: []  # CHANGÉ : images (array) au lieu de image
  )
end
```

**Checklist** :
- [x] Ajouter action `index` (GRID)
- [x] Ajouter actions `bulk_edit` / `bulk_update`
- [x] Ajouter action `toggle_status`
- [x] Modifier `variant_params` pour `images: []`
- [x] Tester toutes les actions

---

## ✅ Controller 3 : InventoryController (NOUVEAU)

**Fichier** : `app/controllers/admin_panel/inventory_controller.rb`

**Code exact complet** :
```ruby
module AdminPanel
  class InventoryController < BaseController
    # Pagy 43 : La méthode pagy() est disponible directement via ApplicationController, plus besoin d'inclure Pagy::Backend
    
    before_action :authorize_inventory
    
    # GET /admin-panel/inventory
    def index
      # Stock faible (<= 10)
      @low_stock = ProductVariant
        .joins(:inventory)
        .where('inventories.available_qty <= ?', 10)
        .where(is_active: true)
        .order('inventories.available_qty ASC')
        .includes(:product, :inventory)
      
      # Rupture de stock (0)
      @out_of_stock = ProductVariant
        .joins(:inventory)
        .where('inventories.available_qty <= 0')
        .where(is_active: true)
        .includes(:product, :inventory)
      
      # Mouvements récents
      @movements = InventoryMovement
        .recent
        .includes(:inventory, :user, inventory: :product_variant)
        .limit(50)
    end
    
    # GET /admin-panel/inventory/transfers
    def transfers
      @q = InventoryMovement.ransack(params[:q])
      @movements = @q.result
        .recent
        .includes(:inventory, :user, inventory: :product_variant)
      
      @pagy, @movements = pagy(@movements, items: 25)
    end
    
    # PATCH /admin-panel/inventory/adjust_stock
    def adjust_stock
      variant = ProductVariant.find(params[:variant_id])
      quantity = params[:quantity].to_i
      reason = params[:reason]
      reference = params[:reference]
      
      if quantity == 0
        flash[:alert] = 'Quantité invalide'
        redirect_back(fallback_location: admin_panel_inventory_path)
        return
      end
      
      InventoryService.move_stock(variant, quantity, reason, reference)
      
      flash[:notice] = 'Stock ajusté avec succès'
      redirect_back(fallback_location: admin_panel_inventory_path)
    end
    
    private
    
    def authorize_inventory
      authorize [:admin_panel, Inventory]
    end
  end
end
```

**Checklist** :
- [x] Créer fichier `app/controllers/admin_panel/inventory_controller.rb`
- [x] Tester action `index`
- [x] Tester action `transfers`
- [x] Tester action `adjust_stock`
- [x] Corriger requêtes SQL pour utiliser `(stock_qty - reserved_qty)` au lieu de `available_qty`
- [x] Utiliser `Arel.sql()` pour les expressions SQL dans `order()`

---

## ✅ Checklist Globale

### **Phase 2 (Semaine 2)** ✅
- [x] Modifier ProductsController (publish/unpublish)
- [x] Modifier ProductVariantsController (index, bulk_edit, bulk_update, toggle_status)
- [x] Créer InventoryController

### **Phase 3 (Semaine 3)** ✅
- [x] Tester tous les controllers
- [x] Vérifier autorisations Pundit
- [x] Vérifier pagination
- [x] Corriger erreurs SQL (available_qty, Arel.sql)

---

**Retour** : [README Boutique](./README.md) | [INDEX principal](../INDEX.md)
