# 🛣️ ROUTES - Dashboard

**Priorité** : 🔴 HAUTE | **Phase** : 0-1 | **Semaine** : 1  
**Version** : 1.1 | **Dernière mise à jour** : 2025-01-13

---

## 📋 Description

Routes pour le dashboard et la maintenance.

---

## ✅ Routes Dashboard ✅ EXISTENT

**Fichier** : `config/routes.rb`

**Routes existantes** :
```ruby
namespace :admin_panel, path: "admin-panel" do
  root "dashboard#index"  # ✅ Existe
  get "dashboard", to: "dashboard#index"  # ✅ Existe (optionnel)
end
```

---

## ✅ Routes Maintenance ✅ AJOUTÉES

**Fichier** : `config/routes.rb`

**Routes ajoutées** :
```ruby
namespace :admin_panel, path: "admin-panel" do
  # Maintenance Mode (admin uniquement)
  resource :maintenance, only: [], controller: "maintenance" do
    member do
      patch :toggle
    end
  end
end
```

**Route générée** :
- `toggle_admin_panel_maintenance_path` → `PATCH /admin-panel/maintenance/toggle`

**Sécurité** :
- ✅ Protégée par `BaseController` (level >= 60)
- ✅ Protégée par `MaintenancePolicy` (double vérification)

---

## ✅ Checklist Globale

### **Phase 0-1 (Semaine 1)** ✅ COMPLÉTÉ
- [x] Vérifier routes dashboard ✅
- [x] Ajouter routes maintenance ✅
- [x] Tester toutes les routes ✅

---

**Retour** : [README Dashboard](./README.md) | [INDEX principal](../INDEX.md)
