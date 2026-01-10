# 🔐 PERMISSIONS ADMIN PANEL - Par Grade

**Date de mise à jour** : 2025-01-XX | **Version** : 1.0

---

## 📊 Tableau des Grades

| Grade | Code | Nom | Level | Accès AdminPanel |
|-------|------|-----|-------|------------------|
| 10 | USER | Utilisateur | 10 | ❌ Aucun accès |
| 20 | REGISTERED | Inscrit | 20 | ❌ Aucun accès |
| 30 | ORGANIZER | Organisateur | 30 | ❌ Aucun accès |
| 40 | INITIATION | Initiation | 40 | ✅ Initiations (lecture seule) |
| 50 | MODERATOR | Modérateur | 50 | ✅ Initiations (lecture seule) |
| 60 | ADMIN | Admin | 60 | ✅ Accès complet |
| 70 | SUPERADMIN | Super Admin | 70 | ✅ Accès complet |

---

## 🎯 Permissions par Ressource

### ✅ **INITIATIONS** (`/admin-panel/initiations`)

#### **Grade 40+ (INITIATION, MODERATOR, ADMIN, SUPERADMIN)**
- ✅ **Lecture** : `index?`, `show?`
  - Voir la liste des initiations
  - Voir les détails d'une initiation
  - Voir les participants, bénévoles, liste d'attente
  - Voir le matériel demandé
- ❌ **Écriture** : `create?`, `update?`, `destroy?`
  - Ne peut pas créer d'initiation
  - Ne peut pas modifier d'initiation
  - Ne peut pas supprimer d'initiation
- ❌ **Actions spéciales** : `presences?`, `update_presences?`, `convert_waitlist?`, `notify_waitlist?`, `toggle_volunteer?`
  - Ne peut pas gérer les présences
  - Ne peut pas convertir la liste d'attente
  - Ne peut pas notifier la liste d'attente
  - Ne peut pas modifier le statut bénévole

#### **Grade 60+ (ADMIN, SUPERADMIN)**
- ✅ **Lecture** : `index?`, `show?`
- ✅ **Écriture** : `create?`, `update?`, `destroy?`
- ✅ **Actions spéciales** : `presences?`, `update_presences?`, `convert_waitlist?`, `notify_waitlist?`, `toggle_volunteer?`

**Boutons visibles dans les vues** :
- Grade 40-50 : Aucun bouton de création/modification
- Grade 60+ : Bouton "Créer une initiation" (index), Bouton "Éditer" (show)

#### **Grade 30 (ORGANIZER)**
- ❌ **Aucun accès** : Accès refusé (redirection vers root_path)

---

### ❌ **DASHBOARD** (`/admin-panel`)

#### **Grade 60+ uniquement (ADMIN, SUPERADMIN)**
- ✅ Accès au tableau de bord
- ✅ Voir les statistiques (utilisateurs, produits, commandes)
- ✅ Voir les commandes récentes

#### **Grade < 60**
- ❌ Accès refusé (redirection vers root_path)

**Sidebar** : Le lien "Tableau de bord" n'est visible que pour level >= 60

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

### ❌ **STOCK ROLLERS** (`/admin-panel/roller-stocks`)

#### **Grade 60+ uniquement (ADMIN, SUPERADMIN)**
- ✅ Accès complet (CRUD)

#### **Grade < 60**
- ❌ Accès refusé (redirection vers root_path)

**Sidebar** : Pas de lien visible (non implémenté dans la sidebar actuelle)

---

## 🔧 Implémentation Technique

### **BaseController** (`app/controllers/admin_panel/base_controller.rb`)

```ruby
def authenticate_admin_user!
  unless user_signed_in?
    redirect_to new_user_session_path, alert: 'Vous devez être connecté pour accéder à cette page.'
    return
  end
  
  user_level = current_user&.role&.level.to_i
  
  # Les initiations sont accessibles pour level >= 40 (INITIATION, MODERATOR, ADMIN, SUPERADMIN)
  # INITIATION (40) est forcément membre Grenoble Roller
  # ORGANIZER (30) peut être n'importe qui, donc pas accès aux initiations
  # Toutes les autres ressources nécessitent level >= 60 (ADMIN, SUPERADMIN)
  if controller_name == 'initiations'
    unless user_level >= 40
      redirect_to root_path, alert: 'Accès non autorisé'
    end
  else
    unless user_level >= 60 # ADMIN (60) ou SUPERADMIN (70)
      redirect_to root_path, alert: 'Accès admin requis'
    end
  end
end
```

### **InitiationPolicy** (`app/policies/admin_panel/event/initiation_policy.rb`)

```ruby
def index?
  can_view_initiations? # level >= 40
end

def show?
  can_view_initiations? # level >= 40
end

def create?
  admin_user? # level >= 60
end

def update?
  admin_user? # level >= 60
end

def destroy?
  admin_user? # level >= 60
end

def presences?
  admin_user? # level >= 60
end

# ... autres actions spéciales nécessitent level >= 60
```

### **BasePolicy** (`app/policies/admin_panel/base_policy.rb`)

```ruby
def admin_user?
  user.present? && user.role&.level.to_i >= 60
end
```

**Note** : Toutes les autres policies (ProductPolicy, OrderPolicy, RollerStockPolicy) héritent de BasePolicy et utilisent `admin_user?`, donc elles bloquent automatiquement level < 60.

---

## 📋 Checklist de Vérification

### ✅ **Grade 30 (ORGANIZER)**
- [x] Ne peut pas accéder à `/admin-panel/initiations` (accès refusé)
- [x] Ne peut pas accéder au dashboard (lien masqué)
- [x] Ne peut pas accéder aux commandes (lien masqué)
- [x] Ne peut accéder à AUCUNE ressource AdminPanel

### ✅ **Grade 40 (INITIATION)**
- [x] Peut accéder à `/admin-panel/initiations`
- [x] Peut voir la liste des initiations
- [x] Peut voir les détails d'une initiation
- [x] Ne peut pas créer d'initiation (bouton masqué)
- [x] Ne peut pas éditer d'initiation (bouton masqué)
- [x] Ne peut pas accéder au dashboard (lien masqué)
- [x] Ne peut pas accéder aux commandes (lien masqué)
- [x] Ne peut accéder à AUCUNE autre ressource AdminPanel

### ✅ **Grade 60 (ADMIN)**
- [x] Accès complet à toutes les ressources
- [x] Peut créer/modifier/supprimer des initiations
- [x] Peut gérer les présences
- [x] Peut accéder au dashboard
- [x] Peut accéder aux commandes

### ✅ **Grade 70 (SUPERADMIN)**
- [x] Accès complet à toutes les ressources (identique à ADMIN)

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

**Retour** : [INDEX principal](./INDEX.md) | [Initiations - Tests](../03-initiations/09-tests.md)
