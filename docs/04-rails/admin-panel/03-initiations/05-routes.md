# 🛣️ ROUTES - Initiations

**Priorité** : 🟡 MOYENNE | **Phase** : 5 | **Semaine** : 5

---

## 📋 Description

Routes pour initiations et stock rollers.

---

## ✅ Routes

**Fichier** : `config/routes.rb`

**Code à ajouter dans le namespace `admin_panel`** :

```ruby
namespace :admin_panel, path: 'admin-panel' do
  # ... autres routes existantes ...

  # Initiations
  resources :initiations do
    member do
      get :presences
      patch :update_presences
      post :convert_waitlist
      post :notify_waitlist
      patch :toggle_volunteer
      post :return_material
    end
  end

  # Roller Stock
  resources :roller_stocks, path: 'roller-stocks' do
    collection do
      post :return_all
    end
  end
end
```

---

## 📋 Routes Générées

### **Initiations**

| Méthode | Route | Action | Description |
|---------|-------|--------|-------------|
| GET | `/admin-panel/initiations` | `index` | Liste des initiations |
| GET | `/admin-panel/initiations/:id` | `show` | Détails initiation |
| GET | `/admin-panel/initiations/:id/presences` | `presences` | Dashboard présences |
| PATCH | `/admin-panel/initiations/:id/update_presences` | `update_presences` | Mise à jour présences |
| POST | `/admin-panel/initiations/:id/convert_waitlist` | `convert_waitlist` | Convertir waitlist |
| POST | `/admin-panel/initiations/:id/notify_waitlist` | `notify_waitlist` | Notifier waitlist |
| PATCH | `/admin-panel/initiations/:id/toggle_volunteer` | `toggle_volunteer` | Toggle bénévole |
| POST | `/admin-panel/initiations/:id/return_material` | `return_material` | Marquer matériel comme rendu (remet les rollers en stock) |

### **Roller Stocks**

| Méthode | Route | Action | Description |
|---------|-------|--------|-------------|
| GET | `/admin-panel/roller-stocks` | `index` | Liste stock rollers |
| POST | `/admin-panel/roller-stocks/return_all` | `return_all` | Tout remettre en stock (initiations terminées non encore marquées « Matériel rendu ») |
| GET | `/admin-panel/roller-stocks/:id` | `show` | Détails stock |
| GET | `/admin-panel/roller-stocks/new` | `new` | Nouveau stock |
| POST | `/admin-panel/roller-stocks` | `create` | Créer stock |
| GET | `/admin-panel/roller-stocks/:id/edit` | `edit` | Éditer stock |
| PATCH | `/admin-panel/roller-stocks/:id` | `update` | Mettre à jour stock |
| DELETE | `/admin-panel/roller-stocks/:id` | `destroy` | Supprimer stock |

---

## ✅ Helpers Rails

Les helpers suivants seront disponibles :

**Initiations** :
- `admin_panel_initiations_path` → `/admin-panel/initiations`
- `admin_panel_initiation_path(@initiation)` → `/admin-panel/initiations/:id`
- `presences_admin_panel_initiation_path(@initiation)` → `/admin-panel/initiations/:id/presences`
- `update_presences_admin_panel_initiation_path(@initiation)` → `/admin-panel/initiations/:id/update_presences`
- `convert_waitlist_admin_panel_initiation_path(@initiation)` → `/admin-panel/initiations/:id/convert_waitlist`
- `notify_waitlist_admin_panel_initiation_path(@initiation)` → `/admin-panel/initiations/:id/notify_waitlist`
- `toggle_volunteer_admin_panel_initiation_path(@initiation)` → `/admin-panel/initiations/:id/toggle_volunteer`
- `return_material_admin_panel_initiation_path(@initiation)` → `/admin-panel/initiations/:id/return_material`

**Roller Stocks** :
- `admin_panel_roller_stocks_path` → `/admin-panel/roller-stocks`
- `return_all_admin_panel_roller_stocks_path` → `/admin-panel/roller-stocks/return_all` (POST)
- `admin_panel_roller_stock_path(@roller_stock)` → `/admin-panel/roller-stocks/:id`
- `new_admin_panel_roller_stock_path` → `/admin-panel/roller-stocks/new`
- `edit_admin_panel_roller_stock_path(@roller_stock)` → `/admin-panel/roller-stocks/:id/edit`

---

## ✅ Checklist Globale

### **Phase 5 (Semaine 5)**
- [ ] Ajouter routes initiations dans `config/routes.rb`
- [ ] Ajouter routes roller_stocks dans `config/routes.rb`
- [ ] Vérifier routes avec `rails routes | grep initiations`
- [ ] Vérifier routes avec `rails routes | grep roller_stocks`
- [ ] Tester toutes les routes

---

**Retour** : [README Initiations](./README.md) | [INDEX principal](../INDEX.md)
