# 📝 CHANGELOG - Admin Panel

**Dernière mise à jour** : 2025-12-24

---

## ✅ Modifications Récentes

### **2025-12-24 - Module Boutique Complet**

#### **🛒 Implémentation Complète du Module Boutique**
- ✅ **Migrations** : Tables `inventories` et `inventory_movements` créées avec succès
- ✅ **Modèles** : `Inventory`, `InventoryMovement`, modifications `ProductVariant` (has_many_attached :images)
- ✅ **Services** : `InventoryService` pour gestion stock, réservations, mouvements
- ✅ **Controllers** : `InventoryController`, modifications `ProductsController` et `ProductVariantsController`
- ✅ **Policies** : `InventoryPolicy` et `ProductVariantPolicy` créées
- ✅ **Routes** : Routes inventory et product_variants (index, bulk_edit, bulk_update, toggle_status)
- ✅ **Vues** : Dashboard inventaire, GRID variantes, vues transfers
- ✅ **JavaScript** : Controller Stimulus GRID pour édition inline
- ✅ **Sidebar** : Menu Boutique réactivé avec sous-menus (Produits, Inventaire)

#### **🎨 Design & UX**
- ✅ **Design Liquid Glass** : Toutes les vues utilisent le design système
- ✅ **Responsive** : Mobile-first avec tables adaptatives
- ✅ **Sous-menu moderne** : Collapse/expand avec icônes Bootstrap Icons

#### **📁 Fichiers Créés/Modifiés**
- `db/migrate/20251224032419_create_inventories.rb` - Migration inventaires
- `db/migrate/20251224032423_create_inventory_movements.rb` - Migration mouvements
- `app/models/inventory.rb` - Modèle inventaire
- `app/models/inventory_movement.rb` - Modèle mouvement
- `app/models/product_variant.rb` - Modifié (images multiples + inventory)
- `app/services/inventory_service.rb` - Service gestion stock
- `app/controllers/admin_panel/inventory_controller.rb` - Controller inventaire
- `app/controllers/admin_panel/products_controller.rb` - Actions publish/unpublish ajoutées
- `app/controllers/admin_panel/product_variants_controller.rb` - Actions GRID ajoutées
- `app/policies/admin_panel/inventory_policy.rb` - Policy inventaire
- `app/policies/admin_panel/product_variant_policy.rb` - Policy variantes
- `app/views/admin_panel/inventory/index.html.erb` - Dashboard inventaire
- `app/views/admin_panel/product_variants/index.html.erb` - Vue GRID variantes
- `app/views/admin_panel/product_variants/_grid_row.html.erb` - Partial ligne GRID
- `app/javascript/controllers/admin_panel/product_variants_grid_controller.js` - JS GRID
- `app/views/admin/shared/_menu_items.html.erb` - Menu Boutique réactivé
- `config/routes.rb` - Routes inventory et product_variants

#### **📚 Documentation**
- `CHANGELOG.md` - Entrée ajoutée
- `01-boutique/README.md` - Checklist mise à jour
- `INDEX.md` - Statut Boutique mis à jour (100%)

#### **🔧 Corrections Techniques**
- ✅ **Migration corrigée** : Utilisation de `index: { unique: true }` dans `t.references` pour éviter double index
- ✅ **Index optimisé** : Suppression index redondant dans `CreateInventoryMovements`

---

### **2025-01-XX - Correction Permissions par Grade**

#### **🔐 Correction Hiérarchie des Grades**
- ✅ **Tableau des grades corrigé** : Level 30 = ORGANIZER (aucun accès), Level 40 = INITIATION (accès initiations)
- ✅ **BaseController mis à jour** : Accès initiations pour `level >= 40` au lieu de `level >= 30`
- ✅ **InitiationPolicy corrigé** : `can_view_initiations?` vérifie maintenant `level >= 40`
- ✅ **Sidebar mise à jour** : Liens initiations visibles uniquement pour `level >= 40`
- ✅ **Documentation PERMISSIONS.md** : Tableau et toutes les références corrigées

#### **📋 Changements Clés**
- **Avant** : Level 30 (INITIATION) avait accès aux initiations
- **Après** : Level 30 (ORGANIZER) = aucun accès, Level 40 (INITIATION) = accès initiations
- **Raison** : ORGANIZER peut être n'importe qui, INITIATION est forcément membre Grenoble Roller

#### **📁 Fichiers Modifiés**
- `app/controllers/admin_panel/base_controller.rb` - Seuil initiations changé de 30 à 40
- `app/policies/admin_panel/event/initiation_policy.rb` - `can_view_initiations?` changé de 30 à 40
- `app/helpers/admin_panel_helper.rb` - `can_view_initiations?` changé de 30 à 40
- `app/views/admin/shared/_sidebar.html.erb` - Condition sidebar changée de 30 à 40
- `docs/development/admin-panel/PERMISSIONS.md` - Documentation complète corrigée

#### **📚 Documentation**
- `PERMISSIONS.md` - Tableau des grades, sections permissions, checklist, notes importantes mis à jour
- `CHANGELOG.md` - Entrée ajoutée

---

### **2025-12-22 - Nettoyage Sidebar et Favicon**

#### **🧹 Sidebar Simplifiée**
- ✅ **Suppression "Tableau de bord"** : Retiré de la sidebar (non conforme)
- ✅ **Suppression "Boutique"** : Retiré de la sidebar avec ses sous-menus (non conforme)
- ✅ **Menu épuré** : Sidebar contient maintenant uniquement :
  - Initiations (level >= 30)
  - Commandes (level >= 60)
  - ActiveAdmin (lien externe)
- ✅ **Meilleure cohérence** : Focus sur les modules réellement implémentés et conformes

#### **🎨 Favicon Restauré**
- ✅ **Favicon corrigé** : Utilisation de `app/assets/images/favicon-512.png` via `asset_path`
- ✅ **Configuration mise à jour** : Les layouts utilisent maintenant `favicon_link_tag` avec le bon fichier
- ✅ **SVG ignoré** : Plus de référence au SVG cassé (cercle rouge)

#### **📁 Fichiers Modifiés**
- `app/views/admin/shared/_menu_items.html.erb` - Suppression Tableau de bord et Boutique
- `app/views/layouts/admin.html.erb` - Favicon corrigé
- `app/views/layouts/application.html.erb` - Favicon corrigé

#### **📚 Documentation**
- `CHANGELOG.md` - Entrée ajoutée
- `00-dashboard/sidebar.md` - Mise à jour avec menu actuel, suppression références sous-menus
- `README.md` - Mise à jour vue d'ensemble avec status actuel
- `INDEX.md` - Mise à jour version et dates
- `LIQUID-GLASS-HARMONISATION.md` - Version mise à jour

---

### **2025-12-22 - Harmonisation Footer et Sidebar**

#### **🎨 Footer Unifié**
- ✅ **Layout admin** : Utilise maintenant le footer de l'application normale (`_footer-simple.html.erb`)
- ✅ **Cohérence visuelle** : Même footer dans toute l'application (site + admin)
- ✅ **Suppression footer inline** : Retrait du footer minimaliste "© 2025 Grenoble Roller Admin"

#### **🧹 Nettoyage Sidebar**
- ✅ **Footer sidebar supprimé** : Retrait de l'email utilisateur et du lien de déconnexion
- ✅ **Évite redondance** : Ces éléments sont déjà disponibles dans le menu déroulant de la navbar
- ✅ **Meilleure UX** : Sidebar plus épurée, focus sur la navigation

#### **📁 Fichiers Modifiés**
- `app/views/layouts/admin.html.erb` - Footer remplacé par `render 'layouts/footer-simple'`
- `app/views/admin/shared/_sidebar.html.erb` - Footer supprimé (lignes 29-39)

#### **📚 Documentation**
- `CHANGELOG.md` - Entrée ajoutée
- `00-dashboard/sidebar.md` - Section mise à jour

---

### **2025-01-XX - Harmonisation Liquid Glass Design**

#### **🎨 Application du Design Liquid Glass**
- ✅ **Sidebar** : Glassmorphism avec `--liquid-glass-bg` et `backdrop-filter`
- ✅ **Cards** : Classes `card-liquid`, `rounded-liquid`, `shadow-liquid` appliquées
- ✅ **Buttons** : `btn-liquid-primary`, `btn-outline-liquid-primary`, etc.
- ✅ **Badges** : `badge-liquid-primary`, `badge-liquid-success`, etc.
- ✅ **Forms** : `form-control-liquid` pour inputs et selects
- ✅ **Helpers mis à jour** : `status_badge()`, `active_badge()`, `stock_badge()` avec classes liquid
- ✅ **Background** : Gradient liquid pastel pour body admin

#### **📁 Fichiers Modifiés**
- `app/assets/stylesheets/admin_panel.scss` - Styles liquid glass ajoutés
- `app/views/layouts/admin.html.erb` - Classe `admin-panel` ajoutée
- `app/views/admin_panel/dashboard/index.html.erb` - Cards liquid
- `app/views/admin_panel/initiations/index.html.erb` - Cards + buttons + badges liquid
- `app/views/admin_panel/orders/index.html.erb` - Cards + buttons liquid
- `app/views/admin_panel/orders/show.html.erb` - Cards + buttons liquid
- `app/views/admin_panel/products/index.html.erb` - Cards + buttons + badges liquid
- `app/helpers/admin_panel/orders_helper.rb` - Badges liquid
- `app/helpers/admin_panel/products_helper.rb` - Badges liquid

#### **📚 Documentation**
- `LIQUID-GLASS-HARMONISATION.md` - Guide complet d'harmonisation

---

### **2025-01-XX - Optimisations Sidebar Admin Panel**

#### **🎨 Refactorisation Complète**
- ✅ **Partial réutilisable** : `_menu_items.html.erb` (desktop + mobile)
- ✅ **Sous-menus Boutique** : Produits, Inventaire, Catégories avec collapse/expand
- ✅ **Helpers permissions** : `can_access_admin_panel?()`, `can_view_initiations?()`, `can_view_boutique?()`
- ✅ **CSS organisé** : Fichier `admin_panel.scss` dédié (0 style inline)
- ✅ **JavaScript séparé** : `admin_panel_navbar.js` pour calcul hauteur navbar
- ✅ **Controller Stimulus optimisé** : 7 problèmes critiques corrigés

#### **🔧 7 Problèmes Critiques Corrigés**
1. ✅ Debounce resize (250ms) - Pas de CPU spike
2. ✅ Constantes au lieu de magic strings - `static values`
3. ✅ Media query observer - Responsive breakpoint sync
4. ✅ Cache références DOM - Pas de requêtes répétées
5. ✅ Bootstrap classes - Pas de style inline
6. ✅ Guard clauses - Early returns
7. ✅ Cleanup listeners - Pas de memory leak

#### **📁 Fichiers Créés/Modifiés**
- `app/views/admin/shared/_menu_items.html.erb` (nouveau)
- `app/assets/stylesheets/admin_panel.scss` (nouveau)
- `app/javascript/admin_panel_navbar.js` (nouveau)
- `app/helpers/admin_panel_helper.rb` (modifié - helpers ajoutés)
- `app/javascript/controllers/admin/admin_sidebar_controller.js` (refactorisé)
- `app/views/admin/shared/_sidebar.html.erb` (nettoyé - 0 style inline)
- `app/views/layouts/admin.html.erb` (nettoyé - CSS/JS séparés)
- `app/assets/stylesheets/application.bootstrap.scss` (modifié - import admin_panel)
- `config/importmap.rb` (modifié - pin admin_panel_navbar)

---

### **2025-01-XX - Module Initiations Complet**

#### **🔐 Permissions par Grade**
- ✅ **BaseController** : Accès initiations pour level >= 40, reste pour level >= 60
- ✅ **InitiationPolicy** : Lecture (level >= 40), Écriture (level >= 60)
- ✅ **Utilisation niveaux numériques** : `role&.level.to_i >= X` au lieu de codes
- ✅ **Sidebar conditionnelle** : Liens masqués selon le grade
- ✅ **Boutons conditionnels** : Création/édition uniquement pour level >= 60

#### **🎨 Interface Utilisateur**
- ✅ **Séparation initiations** : Sections "À venir" et "Passées" avec headers colorés
- ✅ **Panel matériel demandé** : Récapitulatif groupé par taille dans vue show
- ✅ **Helpers traduction** : `attendance_status_fr` et `waitlist_status_fr`
- ✅ **Suppression filtre saison** : Retiré (inutile, aucune saison en base)
- ✅ **Boutons alignés à droite** : Filtres et actions dans index

#### **🧪 Tests RSpec**
- ✅ **109 exemples, 0 échecs**
- ✅ Tests policies (BasePolicy, InitiationPolicy, OrderPolicy, ProductPolicy, RollerStockPolicy)
- ✅ Tests controllers (BaseController, InitiationsController, DashboardController, OrdersController)
- ✅ Tests permissions par grade (30, 40, 60, 70)
- ✅ Factories mises à jour (roles, users, products, roller_stocks)

#### **📚 Documentation**
- ✅ **PERMISSIONS.md** : Documentation complète des permissions par grade
- ✅ **09-tests.md** : Documentation des tests RSpec pour Initiations
- ✅ Mise à jour INDEX.md, README.md, fichiers 03-initiations/
- ✅ Références aux niveaux numériques partout

---

## 📊 État d'Avancement (2025-12-24)

| Module | Status | Tests | Documentation | Sidebar |
|--------|--------|-------|---------------|---------|
| **Sidebar** | ✅ 100% | ✅ Optimisée | ✅ Complète | ✅ Implémenté |
| **Boutique** | ✅ 100% | ⚠️ À créer | ✅ Complète | ✅ Dans sidebar |
| **Initiations** | ✅ 100% | ✅ 109 exemples | ✅ Complète | ✅ Dans sidebar |
| **Commandes** | 🟡 60% | ⚠️ À créer | ✅ Partielle | ✅ Dans sidebar |
| **Dashboard** | 🟡 30% | ⚠️ À créer | ✅ Partielle | ❌ Retiré (non conforme) |

**Menu Sidebar Actuel** :
- ✅ Initiations (level >= 40)
- ✅ Boutique (level >= 60) - Produits, Inventaire
- ✅ Commandes (level >= 60)
- ✅ ActiveAdmin (lien externe)
- ❌ Tableau de bord (retiré - non conforme)

---

## 🔄 Prochaines Étapes

1. **Tests RSpec** pour Dashboard, Boutique, Commandes
2. **Documentation** des autres modules
3. **Permissions** pour les autres ressources (si nécessaire)

---

**Retour** : [INDEX principal](./INDEX.md) | [Permissions](./PERMISSIONS.md)
