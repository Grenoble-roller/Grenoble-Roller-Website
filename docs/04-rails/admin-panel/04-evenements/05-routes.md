# 🛣️ ROUTES - Événements

**Priorité** : 🟡 MOYENNE | **Phase** : 4 | **Semaine** : 6+

---

## 📋 Description

Routes pour événements, routes, participations et candidatures organisateur.

---

## ✅ Routes

**Fichier** : `config/routes.rb`

**Code à implémenter** :
```ruby
namespace :admin_panel, path: 'admin-panel' do
  resources :events do
    member do
      post :convert_waitlist
      post :notify_waitlist
    end
  end
  
  resources :routes
  resources :attendances
  resources :organizer_applications do
    member do
      patch :approve
      patch :reject
    end
  end
end
```

---

## ✅ Checklist Globale

### **Phase 4 (Semaine 6+)**
- [ ] Ajouter routes events
- [ ] Ajouter routes routes
- [ ] Ajouter routes attendances
- [ ] Ajouter routes organizer_applications
- [ ] Tester toutes les routes

---

**Retour** : [README Événements](./README.md) | [INDEX principal](../INDEX.md)
