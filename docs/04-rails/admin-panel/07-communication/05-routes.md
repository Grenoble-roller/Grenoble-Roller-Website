# 🛣️ ROUTES - Communication

**Priorité** : 🟢 BASSE | **Phase** : 7 | **Semaine** : 7+

---

## 📋 Description

Routes pour messages de contact (public + admin) et partenaires.

---

## ✅ Routes

**Fichier** : `config/routes.rb`

**Code à implémenter** :
```ruby
# Route publique
get 'contact', to: 'contact#new'
post 'contact', to: 'contact#create'

namespace :admin_panel, path: 'admin-panel' do
  resources :contact_messages, only: [:index, :show, :destroy]
  resources :partners
end
```

---

## ✅ Checklist Globale

### **Phase 7 (Semaine 7+)**
- [ ] Ajouter routes contact (public)
- [ ] Ajouter routes contact_messages (admin)
- [ ] Ajouter routes partners
- [ ] Tester toutes les routes

---

**Retour** : [README Communication](./README.md) | [INDEX principal](../INDEX.md)
