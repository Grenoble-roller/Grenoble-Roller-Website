# 🎨 SIDEBAR ADMIN PANEL - Documentation Technique

**Date** : 2025-12-24 | **Version** : 2.1 | **Status** : ✅ **IMPLÉMENTÉ**

---

## 📋 Vue d'Ensemble

Sidebar responsive avec collapse/expand, permissions par grade, et optimisations performance.

**Menu Actuel (2025-12-24)** :
- ✅ Initiations (level >= 40)
- ✅ Boutique (level >= 60) - Produits, Inventaire
- ✅ Commandes (level >= 60)
- ✅ ActiveAdmin (lien externe)
- ❌ Tableau de bord (retiré - non conforme)

**Fichiers principaux** :
- `app/views/admin/shared/_sidebar.html.erb` - Template principal
- `app/views/admin/shared/_menu_items.html.erb` - Partial réutilisable (desktop + mobile)
- `app/javascript/controllers/admin/admin_sidebar_controller.js` - Controller Stimulus optimisé
- `app/assets/stylesheets/admin_panel.scss` - Styles dédiés
- `app/javascript/admin_panel_navbar.js` - Calcul hauteur navbar
- `app/helpers/admin_panel_helper.rb` - Helpers permissions

---

## 🏗️ Architecture

### **Structure des Fichiers**

```
app/
├── views/admin/shared/
│   ├── _sidebar.html.erb          # Template principal (desktop + mobile)
│   └── _menu_items.html.erb       # Partial menu réutilisable
├── javascript/
│   ├── controllers/admin/
│   │   └── admin_sidebar_controller.js  # Controller Stimulus
│   └── admin_panel_navbar.js      # Calcul hauteur navbar
├── assets/stylesheets/
│   └── admin_panel.scss           # Styles sidebar
└── helpers/
    └── admin_panel_helper.rb      # Helpers permissions
```

### **⚠️ Important : Footer et Déconnexion**

**Footer de l'application** :
- Le layout admin (`app/views/layouts/admin.html.erb`) utilise maintenant le footer standard de l'application (`_footer-simple.html.erb`)
- Cohérence visuelle avec le reste du site

**Déconnexion et informations utilisateur** :
- ❌ **Supprimé de la sidebar** : Le footer avec email et déconnexion a été retiré
- ✅ **Disponible dans la navbar** : Ces éléments sont accessibles via le menu déroulant utilisateur dans la navbar principale
- **Raison** : Éviter la redondance et améliorer la cohérence UX

---

## 🎯 Fonctionnalités

### ✅ **1. Menu Actuel (2025-12-24)**

**Structure du menu sidebar** :
1. **Initiations** (level >= 40)
   - Icône : `bi-people`
   - Route : `admin_panel_initiations_path`
   - Permissions : Lecture (level >= 40), Écriture (level >= 60)

2. **Boutique** (level >= 60) - Menu avec sous-menus
   - Icône : `bi-shop`
   - Sous-menu : Produits (`admin_panel_products_path`), Inventaire (`admin_panel_inventory_path`)
   - Permissions : Accès complet (level >= 60)
   - Design : Collapse/expand avec chevron

3. **Commandes** (level >= 60)
   - Icône : `bi-box-seam`
   - Route : `admin_panel_orders_path`
   - Permissions : Accès complet (level >= 60)

4. **Séparateur** (`<hr>`)

5. **ActiveAdmin** (lien externe)
   - Icône : `bi-gear`
   - Route : `/activeadmin`
   - Accessible à tous (ouvre dans un nouvel onglet)

**Modules retirés** (non conformes) :
- ❌ **Tableau de bord** - Retiré le 2025-12-22 (non conforme)

**Code actuel** :
```erb
<!-- Initiations -->
<% if can_view_initiations? %>
  <li class="admin-menu-item">
    <%= link_to admin_panel_initiations_path, class: "admin-menu-link..." %>
  </li>
<% end %>

<!-- Boutique (avec sous-menu) -->
<% if can_access_admin_panel?(60) %>
  <li class="admin-menu-item">
    <a href="#boutique-submenu" class="admin-menu-link" data-bs-toggle="collapse">
      <i class="bi bi-shop"></i>
      <span>Boutique</span>
      <i class="bi bi-chevron-down"></i>
    </a>
    <ul class="collapse" id="boutique-submenu">
      <li><%= link_to admin_panel_products_path, class: "admin-menu-sublink" %></li>
      <li><%= link_to admin_panel_inventory_path, class: "admin-menu-sublink" %></li>
    </ul>
  </li>
<% end %>

<!-- Commandes -->
<% if can_access_admin_panel?(60) %>
  <li class="admin-menu-item">
    <%= link_to admin_panel_orders_path, class: "admin-menu-link..." %>
  </li>
<% end %>

<!-- ActiveAdmin -->
<li class="admin-menu-item">
  <%= link_to "/activeadmin", target: "_blank", class: "admin-menu-link..." %>
</li>
```

---

### ✅ **2. Partial Réutilisable**

**Fichier** : `app/views/admin/shared/_menu_items.html.erb`

- ✅ **DRY** : Un seul partial pour desktop ET mobile
- ✅ **Paramètre `mobile`** : Adapte le comportement (offcanvas dismiss)
- ✅ **Permissions intégrées** : Utilise les helpers `can_access_admin_panel?()`

**Utilisation** :
```erb
<!-- Desktop -->
<%= render 'admin/shared/menu_items', mobile: false %>

<!-- Mobile -->
<%= render 'admin/shared/menu_items', mobile: true %>
```

---

### ✅ **3. Helpers Permissions**

**Fichier** : `app/helpers/admin_panel_helper.rb`

**Helpers créés** :
```ruby
# Vérification par niveau
can_access_admin_panel?(min_level = 60)

# Helpers spécifiques
can_view_initiations?  # level >= 40
can_view_boutique?     # level >= 60

# Détection état actif
admin_panel_active?(controller_name, action_name = nil)
```

**Avantages** :
- ✅ **Maintenabilité** : Plus de `current_user&.role&.level.to_i >= X` répétés
- ✅ **Lisibilité** : Code plus clair dans les vues
- ✅ **Cohérence** : Un seul endroit pour les règles

---

### ✅ **4. Controller Stimulus Optimisé**

**Fichier** : `app/javascript/controllers/admin/admin_sidebar_controller.js`

**7 Problèmes Critiques Corrigés** :

| # | Problème | Solution |
|---|----------|----------|
| 1 | Pas debounce resize | ✅ `debounce(250ms)` |
| 2 | Magic strings hardcodés | ✅ `static values` (constantes) |
| 3 | Pas responsive breakpoint sync | ✅ Media query observer |
| 4 | DOM queries inefficaces | ✅ Cache refs (`cacheRefs()`) |
| 5 | Style inline vs CSS | ✅ Bootstrap `.d-none` |
| 6 | Pas guard clauses | ✅ Early returns |
| 7 | Pas cleanup listener | ✅ `disconnect()` complet |

**Constantes Configurables** :
```javascript
static values = {
  collapsedWidth: { type: String, default: "64px" },
  expandedWidth: { type: String, default: "280px" },
  breakpoint: { type: Number, default: 992 },
  debounceMs: { type: Number, default: 250 }
}
```

**Méthodes Principales** :
- `connect()` - Initialisation + cache refs + restore state
- `toggle()` - Collapse/expand sidebar
- `handleResize()` - Debounced resize handler
- `disconnect()` - Cleanup listeners

---

## 🎨 Design & Responsive

### **Desktop/Tablet (≥ 992px)**
- ✅ Sidebar fixe à gauche (collapsible)
- ✅ Largeur : 280px (expanded) / 64px (collapsed)
- ✅ Transition smooth avec CSS
- ✅ Chevron rotate sur collapse

### **Mobile (< 992px)**
- ✅ Offcanvas Bootstrap (slide depuis gauche)
- ✅ Backdrop overlay
- ✅ Auto-dismiss sur navigation
- ✅ Touch-friendly (targets ≥ 44px)

### **Design Liquid Glass**
- ✅ Background glassmorphism (`--liquid-glass-bg`)
- ✅ Backdrop filter blur
- ✅ Border subtil (`--liquid-glass-border`)
- ✅ Shadow doux (`shadow-liquid`)

---

## 📊 Performance

### **Optimisations Appliquées**
1. ✅ **Debounce resize** : 250ms (évite CPU spike)
2. ✅ **Cache DOM refs** : Pas de requêtes répétées
3. ✅ **Media query observer** : Sync breakpoint automatique
4. ✅ **Cleanup listeners** : Pas de memory leak
5. ✅ **CSS classes** : Pas de style inline

---

## ✅ Checklist Globale

### **Implémentation**
- [x] Template sidebar (desktop + mobile)
- [x] Partial menu réutilisable
- [x] Controller Stimulus optimisé
- [x] Helpers permissions
- [x] Styles CSS organisés
- [x] Menu Boutique avec sous-menus
- [x] Design Liquid Glass appliqué
- [x] Responsive mobile-first

### **Tests**
- [ ] Tests RSpec sidebar (à créer)
- [ ] Tests JavaScript (à créer)

---

**Retour** : [INDEX principal](../INDEX.md) | [Dashboard README](./README.md)
