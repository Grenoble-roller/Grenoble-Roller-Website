# 🛒 BOUTIQUE - Variantes

**Priorité** : 🔴 HAUTE | **Phase** : 1-3 | **Semaines** : 1-4  
**Version** : 2.0 | **Dernière mise à jour** : 2025-12-24

---

## 📋 Description

Gestion des variantes de produits : GRID éditeur Shopify-like, édition en masse, images multiples.

**Fichier actuel** : `app/controllers/admin_panel/product_variants_controller.rb` (existe déjà)

**🎨 Design & UX** : Voir [DESIGN-GUIDELINES.md](./DESIGN-GUIDELINES.md) pour les spécifications complètes du GRID éditeur (structure, édition inline, feedback visuel, etc.)

---

## 🔧 Modifications à Apporter

### **1. Modèle ProductVariant** 🔴

**Fichier** : `app/models/product_variant.rb`

**Modifications critiques** :
```ruby
# AVANT
has_one_attached :image
validate :image_or_image_url_present

# APRÈS
has_many_attached :images  # Plusieurs images
has_one :inventory, dependent: :destroy
after_create :create_inventory_record
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
- [x] `has_one_attached :image` → `has_many_attached :images`
- [x] Supprimer validation `image_or_image_url_present`
- [x] Ajouter validation `image_present`
- [x] Ajouter relation `has_one :inventory`
- [x] Ajouter callback `after_create :create_inventory_record`

---

### **2. Controller ProductVariantsController** 🟡

**Fichier** : `app/controllers/admin_panel/product_variants_controller.rb`

**Actions à ajouter** :
```ruby
def index
  @product = Product.find(params[:product_id])
  @variants = @product.product_variants.order(sku: :asc)
  @pagy, @variants = pagy(@variants, items: 50)
end

def bulk_edit
  @product = Product.find(params[:product_id])
  @variant_ids = params[:variant_ids] || []
end

def bulk_update
  variant_ids = params[:variant_ids] || []
  updates = params[:variants] || {}
  
  variant_ids.each do |id|
    variant = ProductVariant.find(id)
    variant.update(updates[id]) if updates[id].present?
  end
  
  redirect_to admin_panel_product_product_variants_path, notice: 'Variantes mises à jour'
end

def toggle_status
  @variant = ProductVariant.find(params[:id])
  @variant.update(is_active: !@variant.is_active)
  redirect_back notice: "Variante #{@variant.is_active ? 'activée' : 'désactivée'}"
end
```

**Checklist** :
- [x] Ajouter action `index` (GRID)
- [x] Ajouter `bulk_edit` / `bulk_update`
- [x] Ajouter `toggle_status`
- [x] Adapter `variant_params` pour `images` (array)

---

### **3. Routes** 🟡

**Fichier** : `config/routes.rb`

```ruby
resources :products do
  resources :product_variants do
    collection do
      get :bulk_edit
      patch :bulk_update
    end
    member do
      patch :toggle_status
    end
  end
end
```

**Checklist** :
- [x] Ajouter route `index` (retirer `except: [:index]`)
- [x] Ajouter routes `bulk_edit` / `bulk_update`
- [x] Ajouter route `toggle_status`

---

### **4. Vues** 🟡

**Vue Index (GRID)** : `app/views/admin_panel/product_variants/index.html.erb`

```erb
<div class="d-flex justify-content-between mb-4">
  <h1><%= @product.name %></h1>
  <%= link_to '+ Variante', new_admin_panel_product_product_variant_path(@product), 
      class: 'btn btn-primary' %>
</div>

<div class="card">
  <table class="table table-hover mb-0" data-controller="admin-variants-grid">
    <thead class="table-light">
      <tr>
        <th style="width: 40px;">
          <input type="checkbox" id="select_all" class="form-check-input">
        </th>
        <th>SKU</th>
        <th>Options</th>
        <th>Prix</th>
        <th>Stock (Dispo/Total)</th>
        <th>Statut</th>
        <th>Actions</th>
      </tr>
    </thead>
    <tbody>
      <% @variants.each do |variant| %>
        <%= render 'grid_row', variant: variant %>
      <% end %>
    </tbody>
  </table>
</div>

<%= render 'shared/pagination', pagy: @pagy %>
```

**Partial Grid Row** : `app/views/admin_panel/product_variants/_grid_row.html.erb`

```erb
<tr class="variant-row" data-variant-id="<%= variant.id %>">
  <td>
    <input type="checkbox" name="variant_ids[]" value="<%= variant.id %>" 
        class="form-check-input variant-checkbox">
  </td>
  <td><code><%= variant.sku %></code></td>
  <td>
    <% variant.option_values.each do |ov| %>
      <span class="badge bg-light text-dark">
        <%= "#{ov.option_type.name}: #{ov.value}" %>
      </span>
    <% end %>
  </td>
  <td>
    <input type="number" class="form-control form-control-sm" style="width: 100px;"
        value="<%= variant.price_cents / 100.0 %>" step="0.01"
        data-field="price" data-variant-id="<%= variant.id %>">
  </td>
  <td class="text-center">
    <span class="badge bg-<%= variant.inventory&.available_qty&.> 0 ? 'success' : 'danger' %>">
      <%= variant.inventory&.available_qty || 0 %> / <%= variant.inventory&.stock_qty || 0 %>
    </span>
  </td>
  <td>
    <% if variant.is_active %>
      <span class="badge bg-success">Actif</span>
    <% else %>
      <span class="badge bg-secondary">Inactif</span>
    <% end %>
  </td>
  <td>
    <div class="btn-group btn-group-sm">
      <%= link_to edit_admin_panel_product_product_variant_path(@product, variant),
          class: 'btn btn-outline-warning' do %>
        <i class="bi bi-pencil"></i>
      <% end %>
      <%= link_to admin_panel_product_product_variant_path(@product, variant),
          method: :delete, data: { confirm: 'Confirmer ?' },
          class: 'btn btn-outline-danger' do %>
        <i class="bi bi-trash"></i>
      <% end %>
    </div>
  </td>
</tr>
```

**Vue Bulk Edit** : `app/views/admin_panel/product_variants/bulk_edit.html.erb`

**Checklist** :
- [x] Créer vue index (GRID)
- [x] Créer partial `_grid_row.html.erb`
- [x] Créer vue `bulk_edit.html.erb` (route créée, vue à compléter si nécessaire)
- [x] Adapter formulaires pour `has_many_attached :images`

---

### **5. JavaScript Stimulus** 🟡

**Fichier** : `app/javascript/controllers/admin_panel/product_variants_grid_controller.js`

```javascript
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["selectAll", "variantCheckbox", "priceInput"]
  
  connect() {
    this.setupCheckboxes()
    this.setupPriceEditing()
  }
  
  setupCheckboxes() {
    this.selectAllTarget?.addEventListener('change', (e) => {
      this.element.querySelectorAll('.variant-checkbox').forEach(cb => {
        cb.checked = e.target.checked
      })
    })
  }
  
  setupPriceEditing() {
    this.element.querySelectorAll('[data-field="price"]').forEach(input => {
      input.addEventListener('change', () => this.savePrice(input))
    })
  }
  
  savePrice(input) {
    const variantId = input.dataset.variantId
    const newPrice = parseFloat(input.value)
    
    if (newPrice <= 0) {
      alert('Prix doit être > 0')
      return
    }
    
    fetch(`/admin-panel/products/1/product_variants/${variantId}`, {
      method: 'PATCH',
      headers: {
        'Content-Type': 'application/json',
        'X-CSRF-Token': document.querySelector('[name="csrf-token"]').content
      },
      body: JSON.stringify({
        product_variant: { price_cents: newPrice * 100 }
      })
    })
    .then(r => r.ok ? null : alert('Erreur de sauvegarde'))
  }
}
```

**Améliorations à ajouter** :
- Debounce (500ms)
- Optimistic locking
- Validation client avancée
- Feedback visuel (saving, saved)

**Checklist** :
- [x] Créer controller Stimulus (`admin_panel/product_variants_grid_controller.js`)
- [x] Implémenter validation client
- [x] Implémenter debounce (500ms)
- [x] Implémenter feedback visuel (saving, saved)
- [ ] Implémenter optimistic locking (amélioration future)

---

## ✅ Checklist Globale

### **Phase 1 (Semaine 1)** ✅
- [x] Modifier ProductVariant (has_many_attached :images + inventory)
- [x] Migration Active Storage (non nécessaire, déjà utilisé)

### **Phase 2 (Semaine 2)** ✅
- [x] Adapter ProductVariantsController (index, bulk_edit, bulk_update, toggle_status)
- [x] Routes product_variants

### **Phase 3 (Semaine 3-4)** ✅
- [x] Vue ProductVariants Index (GRID)
- [x] Partial grid_row
- [x] Vue Bulk Edit (route créée)
- [x] Adapter formulaires images

### **Phase 4 (Semaine 4)** ✅
- [x] Controller Stimulus GRID
- [x] Validation client
- [x] Debounce (500ms)
- [x] Feedback visuel (saving, saved)
- [ ] Optimistic locking (amélioration future)

---

**Retour** : [README Boutique](./README.md) | [INDEX principal](../INDEX.md)
