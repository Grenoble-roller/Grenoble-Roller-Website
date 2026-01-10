# 🎨 VUES - Boutique

**Priorité** : 🔴 HAUTE | **Phase** : 3 | **Semaine** : 3-4  
**Version** : 2.0 | **Dernière mise à jour** : 2025-12-24

---

## 📋 Description

Vues ERB pour produits, variantes (GRID) et inventaire.

**🎨 Design & UX** : Voir [DESIGN-GUIDELINES.md](./DESIGN-GUIDELINES.md) pour toutes les spécifications de design, structure des formulaires, composants, responsive, accessibilité, etc.

---

## ✅ Vue 1 : ProductVariants Index (GRID) - NOUVEAU

**Fichier** : `app/views/admin_panel/product_variants/index.html.erb`

**Code exact** :
```erb
<div class="d-flex justify-content-between align-items-center mb-4">
  <div>
    <h1><%= @product.name %></h1>
    <p class="text-muted mb-0">Gestion des variantes</p>
  </div>
  <%= link_to '+ Variante', new_admin_panel_product_product_variant_path(@product),
      class: 'btn btn-primary' %>
</div>

<div class="card">
  <div class="card-header d-flex justify-content-between align-items-center">
    <h5 class="mb-0">Variantes (<%= @variants.count %>)</h5>
    <div class="btn-group">
      <%= link_to 'Édition en masse', bulk_edit_admin_panel_product_product_variants_path(@product, variant_ids: []),
          class: 'btn btn-sm btn-outline-secondary',
          id: 'bulk-edit-btn',
          disabled: true %>
    </div>
  </div>
  
  <div class="table-responsive">
    <table class="table table-hover mb-0" 
           data-controller="admin-panel--product-variants-grid"
           data-admin-panel--product-variants-grid-product-id-value="<%= @product.id %>">
      <thead class="table-light">
        <tr>
          <th style="width: 40px;">
            <input type="checkbox" 
                   id="select_all" 
                   class="form-check-input"
                   data-admin-panel--product-variants-grid-target="selectAll">
          </th>
          <th>SKU</th>
          <th>Options</th>
          <th>Prix (€)</th>
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
</div>

<%= render 'shared/pagination', pagy: @pagy if @pagy %>
```

---

## ✅ Vue 2 : Partial Grid Row - NOUVEAU

**Fichier** : `app/views/admin_panel/product_variants/_grid_row.html.erb`

**Code exact** :
```erb
<tr class="variant-row" 
    data-variant-id="<%= variant.id %>"
    data-admin-panel--product-variants-grid-target="row">
  <td>
    <input type="checkbox" 
           name="variant_ids[]" 
           value="<%= variant.id %>" 
           class="form-check-input variant-checkbox"
           data-admin-panel--product-variants-grid-target="checkbox"
           data-action="change->admin-panel--product-variants-grid#updateBulkEditButton">
  </td>
  <td>
    <code><%= variant.sku %></code>
  </td>
  <td>
    <% variant.option_values.each do |ov| %>
      <span class="badge bg-light text-dark me-1">
        <%= "#{ov.option_type.name}: #{ov.value}" %>
      </span>
    <% end %>
  </td>
  <td>
    <input type="number" 
           class="form-control form-control-sm" 
           style="width: 100px;"
           value="<%= variant.price_cents / 100.0 %>" 
           step="0.01"
           data-field="price_cents"
           data-variant-id="<%= variant.id %>"
           data-admin-panel--product-variants-grid-target="priceInput"
           data-action="change->admin-panel--product-variants-grid#savePrice">
  </td>
  <td class="text-center">
    <% inventory = variant.inventory %>
    <% available = inventory&.available_qty || 0 %>
    <% total = inventory&.stock_qty || 0 %>
    <span class="badge bg-<%= available > 0 ? 'success' : 'danger' %>">
      <%= available %> / <%= total %>
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
          class: 'btn btn-outline-warning',
          title: 'Modifier' do %>
        <i class="bi bi-pencil"></i>
      <% end %>
      <%= link_to toggle_status_admin_panel_product_product_variant_path(@product, variant),
          method: :patch,
          class: 'btn btn-outline-info',
          title: variant.is_active ? 'Désactiver' : 'Activer',
          data: { confirm: "Confirmer #{variant.is_active ? 'désactivation' : 'activation'} ?" } do %>
        <i class="bi bi-<%= variant.is_active ? 'eye-slash' : 'eye' %>"></i>
      <% end %>
      <%= link_to admin_panel_product_product_variant_path(@product, variant),
          method: :delete,
          data: { confirm: 'Confirmer suppression ?' },
          class: 'btn btn-outline-danger',
          title: 'Supprimer' do %>
        <i class="bi bi-trash"></i>
      <% end %>
    </div>
  </td>
</tr>
```

---

## ✅ Vue 3 : Bulk Edit - NOUVEAU

**Fichier** : `app/views/admin_panel/product_variants/bulk_edit.html.erb`

**Code exact** :
```erb
<div class="mb-4">
  <h1>Édition en masse</h1>
  <p class="text-muted">Modifier plusieurs variantes à la fois</p>
</div>

<%= form_with url: bulk_update_admin_panel_product_product_variants_path(@product),
    method: :patch,
    local: true do |f| %>
  
  <% @variants.each do |variant| %>
    <%= hidden_field_tag "variant_ids[]", variant.id %>
    
    <div class="card mb-3">
      <div class="card-header">
        <strong><%= variant.sku %></strong>
      </div>
      <div class="card-body">
        <div class="row">
          <div class="col-md-4">
            <%= f.label "variants[#{variant.id}][price_cents]", "Prix (cents)", class: "form-label" %>
            <%= f.number_field "variants[#{variant.id}][price_cents]",
                value: variant.price_cents,
                class: "form-control",
                step: 1 %>
          </div>
          <div class="col-md-4">
            <%= f.label "variants[#{variant.id}][stock_qty]", "Stock", class: "form-label" %>
            <%= f.number_field "variants[#{variant.id}][stock_qty]",
                value: variant.stock_qty,
                class: "form-control",
                step: 1,
                min: 0 %>
          </div>
          <div class="col-md-4">
            <%= f.label "variants[#{variant.id}][is_active]", "Statut", class: "form-label" %>
            <%= f.select "variants[#{variant.id}][is_active]",
                options_for_select([
                  ['Actif', true],
                  ['Inactif', false]
                ], variant.is_active),
                {},
                { class: "form-select" } %>
          </div>
        </div>
      </div>
    </div>
  <% end %>
  
  <div class="d-flex justify-content-between">
    <%= link_to 'Annuler', admin_panel_product_product_variants_path(@product),
        class: 'btn btn-secondary' %>
    <%= f.submit 'Mettre à jour', class: 'btn btn-primary' %>
  </div>
<% end %>
```

---

## ✅ Vue 4 : Inventory Index - NOUVEAU

**Fichier** : `app/views/admin_panel/inventory/index.html.erb`

**Code exact** :
```erb
<div class="mb-4">
  <h1>Inventaire - Dashboard</h1>
  <p class="text-muted">Vue d'ensemble du stock</p>
</div>

<div class="row g-3 mb-4">
  <div class="col-md-6">
    <div class="card border-warning">
      <div class="card-body">
        <h5 class="card-title text-warning">⚠️ Stock Faible</h5>
        <h2 class="text-warning mb-0"><%= @low_stock.count %></h2>
        <small class="text-muted">&lt; 10 unités disponibles</small>
      </div>
    </div>
  </div>
  
  <div class="col-md-6">
    <div class="card border-danger">
      <div class="card-body">
        <h5 class="card-title text-danger">🔴 Rupture</h5>
        <h2 class="text-danger mb-0"><%= @out_of_stock.count %></h2>
        <small class="text-muted">0 unité disponible</small>
      </div>
    </div>
  </div>
</div>

<div class="card mb-4">
  <div class="card-header">
    <h5 class="mb-0">Stock Faible</h5>
  </div>
  <div class="table-responsive">
    <table class="table mb-0">
      <thead class="table-light">
        <tr>
          <th>Produit</th>
          <th>SKU</th>
          <th>Disponible</th>
          <th>Total</th>
          <th>Réservé</th>
        </tr>
      </thead>
      <tbody>
        <% @low_stock.each do |variant| %>
          <tr>
            <td><%= variant.product.name %></td>
            <td><code><%= variant.sku %></code></td>
            <td>
              <span class="badge bg-warning">
                <%= variant.inventory.available_qty %>
              </span>
            </td>
            <td><%= variant.inventory.stock_qty %></td>
            <td><%= variant.inventory.reserved_qty %></td>
          </tr>
        <% end %>
      </tbody>
    </table>
  </div>
</div>

<div class="card">
  <div class="card-header d-flex justify-content-between align-items-center">
    <h5 class="mb-0">Mouvements Récents</h5>
    <%= link_to 'Voir tous', admin_panel_inventory_transfers_path, class: 'btn btn-sm btn-outline-primary' %>
  </div>
  <div class="table-responsive">
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
            <td><%= movement.inventory.product_variant.product.name %></td>
            <td>
              <span class="badge bg-info">
                <%= movement.reason %>
              </span>
            </td>
            <td><%= number_with_precision(movement.quantity, precision: 0) %></td>
            <td><%= movement.before_qty %></td>
            <td><%= l(movement.created_at, format: :short) %></td>
            <td><%= movement.user&.email || 'Système' %></td>
          </tr>
        <% end %>
      </tbody>
    </table>
  </div>
</div>
```

---

## ✅ Vue 5 : Formulaire Produits avec Tabs - NOUVEAU (2025-12-24)

**Fichier** : `app/views/admin_panel/products/_form.html.erb`

**Structure** : Formulaire refactorisé avec structure en **5 tabs** (Produit, Prix, Inventaire, Variantes, SEO)

**Fonctionnalités** :
- ✅ Header avec actions (Enregistrer, Publier, Aperçu)
- ✅ Navigation par tabs (desktop) et accordion (mobile)
- ✅ Validation en temps réel avec feedback visuel
- ✅ Auto-save avec barre de statut
- ✅ Compteurs de caractères
- ✅ Génération automatique du slug

**Partials associés** :
- `_image_upload.html.erb` - Upload drag & drop avec preview
- `_variants_section.html.erb` - Gestion variantes avec preview

---

## ✅ Checklist Globale

### **Phase 3 (Semaine 3-4)** ✅
- [x] Créer vue ProductVariants Index (GRID)
- [x] Créer partial `_grid_row.html.erb`
- [x] Créer vue Bulk Edit (route créée)
- [x] Créer vue Inventory Index
- [x] Adapter formulaires pour `images: []` (has_many_attached)
- [x] Refactoriser formulaire produits avec tabs
- [x] Créer partials `_image_upload.html.erb` et `_variants_section.html.erb`
- [x] Tester toutes les vues

---

**Retour** : [README Boutique](./README.md) | [INDEX principal](../INDEX.md)
