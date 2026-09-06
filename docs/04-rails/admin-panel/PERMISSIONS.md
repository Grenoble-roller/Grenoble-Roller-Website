# 🔐 PERMISSIONS ADMIN PANEL - Par Grade

**Date de mise à jour** : 2026-06-07 | **Version** : 1.1

Aligné sur `db/seeds.rb` et les policies Pundit (le **level** prime sur le code du rôle).

| Grade | Code | Nom | Level | Accès AdminPanel |
|-------|------|-----|-------|------------------|
| 10 | USER | Utilisateur | 10 | ❌ Aucun accès |
| 20 | REGISTERED | Inscrit | 20 | ❌ Aucun accès |
| 30 | INITIATION | Initiation | 30 | ✅ Initiations (lecture), carrousel homepage (base) |
| 40 | ORGANIZER | Organisateur | 40 | ✅ + Événements randos (lecture), retour matériel |
| 50 | MODERATOR | Modérateur | 50 | ✅ Idem ORGANIZER |
| 60 | ADMIN | Admin | 60 | ✅ Accès complet (écriture) |
| 70 | SUPERADMIN | Super Admin | 70 | ✅ Accès complet |

**Note sidebar :** `can_view_initiations?` / liens menu utilisent level ≥ 40 — les utilisateurs level 30 peuvent accéder aux URLs autorisées par policy mais ne voient pas tous les liens sidebar.

---

## 🎯 Permissions par Ressource

### ✅ **ÉVÉNEMENTS (randos)** (`/admin-panel/events`)

#### **Grade 40+ (ORGANIZER, MODERATOR, ADMIN, SUPERADMIN)**
- ✅ **Lecture** : `index?`, `show?` — liste et détail des randos (hors initiations)
- ❌ **Écriture** : create/update/destroy, waitlist actions — réservé level ≥ 60

#### **Grade < 40**
- ❌ Accès refusé par `BaseController` (min level 40 pour controller `events`)

**Sidebar :** level 40–59 → lien « Événements » direct ; level ≥ 60 → sous-menu complet (organizers, routes, participations, candidatures).

---

### ✅ **ENTITÉS ORGANISATRICES** (`/admin-panel/event-organizers`)

#### **Grade 60+ uniquement**
- ✅ CRUD complet (admin submenu)

---

### ✅ **INITIATIONS** (`/admin-panel/initiations`)

#### **Grade 30+ (INITIATION, ORGANIZER, MODERATOR, ADMIN, SUPERADMIN)**
- ✅ **Lecture** : `index?`, `show?`
  - Voir la liste et le détail des initiations
  - Voir participants, bénévoles, liste d'attente, matériel demandé
- ❌ **Écriture** : `create?`, `update?`, `destroy?` — level ≥ 60
- ❌ **Actions spéciales** (présences, waitlist, bénévoles) — level ≥ 60
- ✅ **`return_material?`** : level ≥ 40 — clôture les réservations matériel (`stock_returned_at`)

#### **Grade 60+ (ADMIN, SUPERADMIN)**
- ✅ Écriture complète + présences, waitlist, bénévoles

#### **Grade < 30**
- ❌ Accès refusé

---

### ❌ **DASHBOARD** (`/admin-panel`)

#### **Grade 40+ (sidebar) / BaseController min 40 pour controller `dashboard`**
- ✅ Accès au tableau de bord (KPIs visibles — contenu orienté admin/boutique)
- Toggle maintenance : level ≥ 60 uniquement

#### **Grade < 40**
- ❌ Accès refusé

---

### ❌ **COMMANDES** (`/admin-panel/orders`)

#### **Grade 60+ uniquement (ADMIN, SUPERADMIN)**
- ✅ Accès complet (lecture, modification, export)

#### **Grade < 60**
- ❌ Accès refusé (redirection vers root_path)

**Sidebar** : Le lien "Commandes" n'est visible que pour level >= 60

---

### ❌ **PRODUITS** (`/admin-panel/products`)

#### **Grade 60+ uniquement (ADMIN, SUPERADMIN)**
- ✅ Accès complet (CRUD)

#### **Grade < 60**
- ❌ Accès refusé (redirection vers root_path)

**Sidebar** : Pas de lien visible (non implémenté dans la sidebar actuelle)

---

### ✅ **ADHÉSIONS / GOODIES** (`/admin-panel/memberships`)

#### **Grade 60+ uniquement**
- ✅ CRUD adhésions, filtre « Goodies en attente », champ `goodies_distributed`

---

### ❌ **CARROUSEL HOMEPAGE** (`/admin-panel/homepage_carousels`)

#### **Grade 30+ (BaseController) — sidebar level ≥ 40**
- ✅ CRUD slides, publish/unpublish, reorder
- ✅ Paramètres autoplay (`HomepageCarouselSetting`) via `update_settings`

---

### ❌ **STOCK ROLLERS** (`/admin-panel/roller-stocks`)

#### **Grade 60+ uniquement (ADMIN, SUPERADMIN)**
- ✅ Accès complet (CRUD parc physique)
- ✅ **Clôturer les prêts terminés** (`return_all`) — clôture `stock_returned_at`, libère réservations

#### **Grade < 60**
- ❌ Accès refusé (redirection vers root_path)

**Sidebar** : lien dans menu admin (level ≥ 60)

---

## 🔧 Implémentation Technique

### **BaseController** (`app/controllers/admin_panel/base_controller.rb`)

Seuil minimal par controller (`required_admin_panel_level`) :

| Controllers | Min level |
| --- | --- |
| `initiations`, `homepage_carousels`, `homepage_announcements` | 30 |
| `dashboard`, `events` | 40 |
| Tous les autres | 60 |

Les policies Pundit peuvent restreindre davantage (ex. écriture events = 60).

### **InitiationPolicy** (`app/policies/admin_panel/event/initiation_policy.rb`)

```ruby
def index?
  can_view_initiations? # level >= 30
end

def show?
  can_view_initiations? # level >= 30
end

def return_material?
  can_return_material? # level >= 40
end

def create?
  admin_user? # level >= 60
end

# ... update?, destroy?, presences?, etc. — level >= 60
```

### **EventPolicy** (`app/policies/admin_panel/event_policy.rb`)

- `index?`, `show?` : level ≥ 40
- create/update/destroy/waitlist : level ≥ 60

### **BasePolicy** (`app/policies/admin_panel/base_policy.rb`)

```ruby
def admin_user?
  user.present? && user.role&.level.to_i >= 60
end
```

**Note** : Toutes les autres policies (ProductPolicy, OrderPolicy, RollerStockPolicy) héritent de BasePolicy et utilisent `admin_user?`, donc elles bloquent automatiquement level < 60.

---

## 📋 Checklist de Vérification

### ✅ **Grade 30 (INITIATION)**
- [x] Peut accéder à `/admin-panel/initiations` (lecture)
- [x] Ne peut pas créer/éditer initiations (level < 60)
- [x] Ne peut pas accéder aux commandes / boutique (level < 60)

### ✅ **Grade 40 (ORGANIZER)**
- [x] Peut accéder aux initiations (lecture) et **retour matériel**
- [x] Peut accéder à `/admin-panel/events` (lecture randos)
- [x] Ne peut pas créer/éditer randos (level < 60)

### ✅ **Grade 60 (ADMIN)**
- [x] Accès complet écriture (initiations, events, boutique, stock rollers, adhésions)
- [x] Peut gérer les présences, waitlist, mail logs

### ✅ **Grade 70 (SUPERADMIN)**
- [x] Accès complet ; seul un super admin peut modifier un autre super admin (`UserPolicy`)

---

## 🎨 Interface Utilisateur

### **Sidebar** (`app/views/admin/shared/_sidebar.html.erb`)

Les liens de la sidebar sont conditionnels selon le grade :

```erb
<!-- Tableau de bord : level >= 60 uniquement -->
<% if current_user&.role&.level.to_i >= 60 %>
  <li class="nav-item">...</li>
<% end %>

<!-- Initiations : level >= 40 -->
<% if current_user&.role&.level.to_i >= 40 %>
  <li class="nav-item">...</li>
<% end %>

<!-- Commandes : level >= 60 uniquement -->
<% if current_user&.role&.level.to_i >= 60 %>
  <li class="nav-item">...</li>
<% end %>
```

### **Vues Initiations**

**Index** (`app/views/admin_panel/initiations/index.html.erb`) :
- Bouton "Créer une initiation" : visible uniquement si `level >= 60`

**Show** (`app/views/admin_panel/initiations/show.html.erb`) :
- Bouton "Éditer" : visible uniquement si `level >= 60`
- Bouton "Présences" : visible pour tous (mais l'action nécessite level >= 60, donc sera bloquée par la policy)

---

## ⚠️ Notes Importantes

1. **Grade 30 (ORGANIZER)** : Aucun accès au panel admin. Les organisateurs peuvent créer des événements mais n'ont pas accès au panel d'administration.

2. **Grade 40 (INITIATION)** : Peut voir uniquement les initiations (lecture seule). Toutes les autres ressources sont bloquées par `BaseController`. INITIATION (40) est forcément membre Grenoble Roller.

3. **Cohérence** : Toutes les vérifications utilisent `role&.level.to_i >= X` et non `role&.code.in?(%w[...])` pour plus de flexibilité.

4. **Sécurité** : Les permissions sont vérifiées à deux niveaux :
   - **Controller** : `BaseController#authenticate_admin_user!` bloque l'accès
   - **Policy** : Pundit vérifie les permissions spécifiques

5. **Tests** : Toutes les permissions sont testées via RSpec (109 exemples, 0 échecs).

---

---

## 🧪 Tests RSpec

**Status** : ✅ Tests complets (109 exemples, 0 échecs)

**Fichiers** :
- `spec/policies/admin_panel/base_policy_spec.rb` - Tests BasePolicy
- `spec/policies/admin_panel/event/initiation_policy_spec.rb` - Tests InitiationPolicy
- `spec/policies/admin_panel/order_policy_spec.rb` - Tests OrderPolicy
- `spec/policies/admin_panel/product_policy_spec.rb` - Tests ProductPolicy
- `spec/policies/admin_panel/roller_stock_policy_spec.rb` - Tests RollerStockPolicy
- `spec/requests/admin_panel/base_controller_spec.rb` - Tests BaseController
- `spec/requests/admin_panel/initiations_spec.rb` - Tests InitiationsController
- `spec/requests/admin_panel/dashboard_spec.rb` - Tests DashboardController
- `spec/requests/admin_panel/orders_spec.rb` - Tests OrdersController

**Exécution** :
```bash
bundle exec rspec spec/policies/admin_panel spec/requests/admin_panel
```

**Documentation** : Voir [`spec/requests/admin_panel/README.md`](../../../spec/requests/admin_panel/README.md)

---

**Retour** : [INDEX principal](./INDEX.md) | [Initiations - Routes](./03-initiations/05-routes.md)
