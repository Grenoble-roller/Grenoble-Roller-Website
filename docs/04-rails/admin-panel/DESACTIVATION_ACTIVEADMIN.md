# 🚫 Désactivation d'ActiveAdmin

**Date** : 2025-01-13 | **Version** : 1.0

---

## ✅ État Actuel

**Tous les modules sont migrés vers AdminPanel** :
- ✅ Dashboard
- ✅ Boutique (Produits, Variantes, Inventaire, Catégories)
- ✅ Commandes
- ✅ Initiations
- ✅ Événements (Events, Routes, Attendances, OrganizerApplications)
- ✅ Utilisateurs (Users, Roles, Memberships)
- ✅ Communication (ContactMessages, Partners)
- ✅ Système (Payments, MailLogs, Mission Control Jobs)

**Status** : ✅ **100% migré** - ActiveAdmin peut être désactivé

---

## 🔧 Étapes de Désactivation

### **Étape 1 : Commenter les routes ActiveAdmin** ✅ RECOMMANDÉ

**Fichier** : `config/routes.rb`

```ruby
Rails.application.routes.draw do
  # ActiveAdmin désactivé - Tout migré vers AdminPanel
  # ActiveAdmin.routes(self)

  # ===== NOUVEAU PANEL ADMIN =====
  namespace :admin_panel, path: "admin-panel" do
    # ... reste du code ...
  end
end
```

**Impact** : Les routes `/activeadmin/*` ne seront plus accessibles

---

### **Étape 2 : Retirer le lien ActiveAdmin du menu** ✅ RECOMMANDÉ

**Fichier** : `app/views/admin/shared/_menu_items.html.erb`

**Retirer ou commenter** :
```erb
<!-- ACTIVEADMIN (Lien vers l'ancien admin) - DÉSACTIVÉ -->
<!--
<li class="admin-menu-item">
  <%= link_to "/activeadmin", 
      class: "admin-menu-link admin-menu-link-external",
      title: "ActiveAdmin (Ancien panel)",
      target: "_blank",
      rel: "noopener noreferrer",
      data: { bs_dismiss: mobile ? "offcanvas" : nil }.compact do %>
    <i class="bi bi-gear admin-menu-icon" aria-hidden="true"></i>
    <span class="admin-menu-label">ActiveAdmin</span>
    <i class="bi bi-box-arrow-up-right admin-menu-external-icon" aria-hidden="true"></i>
  <% end %>
</li>
-->
```

---

### **Étape 3 : Commenter la méthode active_admin_access_denied** ✅ OPTIONNEL

**Fichier** : `app/controllers/application_controller.rb`

**Si la méthode existe, la commenter** :
```ruby
# ActiveAdmin désactivé
# def active_admin_access_denied(exception)
#   # ... code existant ...
# end
```

---

### **Étape 4 : Garder les fichiers app/admin/*.rb** ✅ RECOMMANDÉ

**Action** : **NE PAS SUPPRIMER** les fichiers `app/admin/*.rb`

**Raison** :
- Backup en cas de besoin
- Référence pour comprendre l'ancienne implémentation
- Peut être utile pour migration de données

**Recommandation** : Les laisser en place mais ils ne seront plus chargés si les routes sont commentées

---

### **Étape 5 : Retirer la gem ActiveAdmin** ⚠️ ATTENTION

**Fichier** : `Gemfile`

**Option 1 : Commenter (RECOMMANDÉ pour test)**
```ruby
# ActiveAdmin désactivé - Tout migré vers AdminPanel
# gem "activeadmin"
```

**Option 2 : Supprimer (après vérification)**
```ruby
# Retirer la ligne : gem "activeadmin"
```

**⚠️ IMPORTANT** :
- Vérifier que rien d'autre ne dépend d'ActiveAdmin
- Faire `bundle install` après modification
- Tester que l'application démarre correctement

---

## 🧪 Tests à Effectuer

Après désactivation, vérifier :

1. ✅ **Application démarre** : `rails s` fonctionne
2. ✅ **Routes AdminPanel** : `/admin-panel` accessible
3. ✅ **Routes ActiveAdmin** : `/activeadmin` retourne 404 ou erreur (attendu)
4. ✅ **Menu sidebar** : Pas de lien ActiveAdmin visible
5. ✅ **Toutes les fonctionnalités AdminPanel** : Dashboard, Boutique, Commandes, etc.

---

## 🔄 Réactivation (si besoin)

Si besoin de réactiver ActiveAdmin temporairement :

1. Décommenter `ActiveAdmin.routes(self)` dans `config/routes.rb`
2. Décommenter le lien dans `app/views/admin/shared/_menu_items.html.erb`
3. Redémarrer l'application

---

## 📊 Impact

### **Avant Désactivation**
- Routes ActiveAdmin : `/activeadmin/*` accessibles
- Routes AdminPanel : `/admin-panel/*` accessibles
- 2 interfaces admin en parallèle

### **Après Désactivation**
- Routes ActiveAdmin : ❌ Non accessibles
- Routes AdminPanel : ✅ `/admin-panel/*` accessibles
- 1 seule interface admin : AdminPanel

---

## ✅ Checklist de Désactivation

- [ ] Commenter `ActiveAdmin.routes(self)` dans `config/routes.rb`
- [ ] Retirer/commenter le lien ActiveAdmin dans `app/views/admin/shared/_menu_items.html.erb`
- [ ] Commenter `active_admin_access_denied` dans `application_controller.rb` (si existe)
- [ ] Tester que l'application démarre
- [ ] Tester que `/admin-panel` fonctionne
- [ ] Vérifier que `/activeadmin` retourne 404
- [ ] Optionnel : Commenter la gem dans `Gemfile` et faire `bundle install`
- [ ] Tester toutes les fonctionnalités AdminPanel

---

**Retour** : [INDEX principal](./INDEX.md)
