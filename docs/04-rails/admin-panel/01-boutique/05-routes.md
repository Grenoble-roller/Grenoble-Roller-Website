# 🛣️ ROUTES - Boutique

**Priorité** : 🔴 HAUTE | **Phase** : 2 | **Semaine** : 2

---

## 📋 Description

Routes nécessaires pour produits, variantes et inventaire dans le namespace AdminPanel.

---

## ✅ Routes à Ajouter/Modifier

**Fichier** : `config/routes.rb`

**Code exact** :

```ruby
namespace :admin_panel, path: 'admin-panel' do
  # ... autres routes existantes ...
  
  # Products
  resources :products do
    member do
      post :publish
      post :unpublish
    end
    collection do
      get :export
      post :import
      get :check_sku
      post :preview_variants
      patch :bulk_update_variants
    end
    
    # Product Variants (nested)
    resources :product_variants, except: [] do  # CHANGÉ : retirer except: [:index]
      collection do
        get :bulk_edit
        patch :bulk_update
      end
      member do
        patch :toggle_status
      end
    end
  end
  
  # Inventory
  get 'inventory', to: 'inventory#index'
  get 'inventory/transfers', to: 'inventory#transfers'
  patch 'inventory/adjust_stock', to: 'inventory#adjust_stock'
end
```

---

## 📊 Routes Complètes (Référence)

### **Products**
- `GET    /admin-panel/products` → `index`
- `GET    /admin-panel/products/new` → `new`
- `POST   /admin-panel/products` → `create`
- `GET    /admin-panel/products/:id` → `show`
- `GET    /admin-panel/products/:id/edit` → `edit`
- `PATCH  /admin-panel/products/:id` → `update`
- `DELETE /admin-panel/products/:id` → `destroy`
- `POST   /admin-panel/products/:id/publish` → `publish` (NOUVEAU)
- `POST   /admin-panel/products/:id/unpublish` → `unpublish` (NOUVEAU)
- `GET    /admin-panel/products/export` → `export`
- `POST   /admin-panel/products/import` → `import`
- `GET    /admin-panel/products/check_sku` → `check_sku`
- `POST   /admin-panel/products/preview_variants` → `preview_variants`
- `PATCH  /admin-panel/products/bulk_update_variants` → `bulk_update_variants`

### **Product Variants**
- `GET    /admin-panel/products/:product_id/product_variants` → `index` (NOUVEAU)
- `GET    /admin-panel/products/:product_id/product_variants/new` → `new`
- `POST   /admin-panel/products/:product_id/product_variants` → `create`
- `GET    /admin-panel/products/:product_id/product_variants/:id/edit` → `edit`
- `PATCH  /admin-panel/products/:product_id/product_variants/:id` → `update`
- `DELETE /admin-panel/products/:product_id/product_variants/:id` → `destroy`
- `GET    /admin-panel/products/:product_id/product_variants/bulk_edit` → `bulk_edit` (NOUVEAU)
- `PATCH  /admin-panel/products/:product_id/product_variants/bulk_update` → `bulk_update` (NOUVEAU)
- `PATCH  /admin-panel/products/:product_id/product_variants/:id/toggle_status` → `toggle_status` (NOUVEAU)

### **Inventory**
- `GET    /admin-panel/inventory` → `index` (NOUVEAU)
- `GET    /admin-panel/inventory/transfers` → `transfers` (NOUVEAU)
- `PATCH  /admin-panel/inventory/adjust_stock` → `adjust_stock` (NOUVEAU)

---

## ✅ Checklist Globale

### **Phase 2 (Semaine 2)** ✅
- [x] Ajouter routes `publish` / `unpublish` pour products
- [x] Retirer `except: [:index]` pour product_variants
- [x] Ajouter routes `bulk_edit` / `bulk_update` pour variants
- [x] Ajouter route `toggle_status` pour variants
- [x] Ajouter routes inventory (3 routes)
- [x] Tester toutes les routes avec `rails routes | grep admin_panel`

---

**Retour** : [README Boutique](./README.md) | [INDEX principal](../INDEX.md)
