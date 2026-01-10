# 🎮 CONTROLLERS - Communication

**Priorité** : 🟢 BASSE | **Phase** : 7 | **Semaine** : 7+

---

## 📋 Description

Controllers pour messages de contact et partenaires.

---

## ✅ Controller 1 : ContactMessagesController (NOUVEAU)

**Fichier** : `app/controllers/admin_panel/contact_messages_controller.rb`

**Code à implémenter** :
```ruby
module AdminPanel
  class ContactMessagesController < BaseController
    # À créer (lecture seule dans AdminPanel)
  end
end
```

---

## ✅ Controller 2 : ContactController (PUBLIC - NOUVEAU)

**Fichier** : `app/controllers/contact_controller.rb`

**Code à implémenter** :
```ruby
class ContactController < ApplicationController
  # À créer : Formulaire de contact public
end
```

---

## ✅ Controller 3 : PartnersController (NOUVEAU)

**Fichier** : `app/controllers/admin_panel/partners_controller.rb`

**Code à implémenter** :
```ruby
module AdminPanel
  class PartnersController < BaseController
    # À créer
  end
end
```

---

## ✅ Checklist Globale

### **Phase 7 (Semaine 7+)**
- [ ] Créer ContactMessagesController (AdminPanel)
- [ ] Créer ContactController (public)
- [ ] Créer PartnersController
- [ ] Tester toutes les actions

---

**Retour** : [README Communication](./README.md) | [INDEX principal](../INDEX.md)
