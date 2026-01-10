# 🛣️ ROUTES - Utilisateurs

**Priorité** : 🟡 MOYENNE | **Phase** : 6 | **Semaine** : 6+

---

## 📋 Description

Routes pour utilisateurs, rôles et adhésions.

---

## ✅ Routes

**Fichier** : `config/routes.rb`

**Code à implémenter** :
```ruby
namespace :admin_panel, path: 'admin-panel' do
  resources :users
  resources :roles
  resources :memberships do
    member do
      patch :activate
    end
  end
end
```

---

## ✅ Checklist Globale

### **Phase 6 (Semaine 6+)**
- [x] Ajouter routes users ✅ **IMPLÉMENTÉ**
- [x] Ajouter routes roles ✅ **IMPLÉMENTÉ**
- [x] Ajouter routes memberships ✅ **IMPLÉMENTÉ**
- [x] Ajouter route `activate` pour memberships ✅ **IMPLÉMENTÉ**
- [x] Tester toutes les routes ✅ **FONCTIONNEL**

**Routes ajoutées dans `config/routes.rb`** :
```ruby
namespace :admin_panel, path: "admin-panel" do
  resources :users
  resources :roles
  resources :memberships do
    member do
      patch :activate
    end
  end
end
```

---

**Retour** : [README Utilisateurs](./README.md) | [INDEX principal](../INDEX.md)
