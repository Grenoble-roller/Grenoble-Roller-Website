# 🔐 POLICIES - Initiations

**Priorité** : 🟡 MOYENNE | **Phase** : 5 | **Semaine** : 5

---

## 📋 Description

Policies Pundit pour initiations et stock rollers avec **permissions par grade**.

---

## ✅ Policy 1 : InitiationPolicy

**Fichier** : `app/policies/admin_panel/event/initiation_policy.rb`

```ruby
# frozen_string_literal: true

module AdminPanel
  module Event
    class InitiationPolicy < AdminPanel::BasePolicy
      # Permissions pour les initiations :
      # - Lecture (index?, show?) : level >= 30 (INITIATION, ORGANIZER, MODERATOR, ADMIN, SUPERADMIN)
      # - Écriture (create?, update?, destroy?) : level >= 60 (ADMIN, SUPERADMIN)
      # - Actions spéciales (presences, waitlist, etc.) : level >= 60 (ADMIN, SUPERADMIN)
      # - Retour matériel (return_material?) : level >= 40 (INITIATION, ORGANIZER, MODERATOR, ADMIN, SUPERADMIN)

      def index?
        can_view_initiations?
      end

      def show?
        can_view_initiations?
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

      def update_presences?
        admin_user? # level >= 60
      end

      def convert_waitlist?
        admin_user? # level >= 60
      end

      def notify_waitlist?
        admin_user? # level >= 60
      end

      def toggle_volunteer?
        admin_user? # level >= 60
      end

      def return_material?
        can_view_initiations? # level >= 40 (INITIATION, ORGANIZER, MODERATOR, ADMIN, SUPERADMIN)
      end

      private

      def can_view_initiations?
        user.present? && user.role&.level.to_i >= 30 # INITIATION (30), ORGANIZER (40), MODERATOR (50), ADMIN (60), SUPERADMIN (70)
      end

      def admin_user?
        user.present? && user.role&.level.to_i >= 60 # ADMIN (60) ou SUPERADMIN (70)
      end
    end
  end
end
```

---

## ✅ Policy 2 : RollerStockPolicy

**Fichier** : `app/policies/admin_panel/roller_stock_policy.rb`

```ruby
# frozen_string_literal: true

module AdminPanel
  class RollerStockPolicy < BasePolicy
    # Les méthodes index?, show?, create?, update?, destroy? héritent de BasePolicy
    # qui vérifie admin_user? (ADMIN ou SUPERADMIN)

    # Pas de méthodes supplémentaires nécessaires pour l'instant
  end
end
```

---

## 📋 Autorisations

### **InitiationPolicy**

| Action | Autorisation | Grade requis | Code |
|--------|--------------|--------------|------|
| `index?` | ✅ `can_view_initiations?` | Level >= 30 | INITIATION, ORGANIZER, MODERATOR, ADMIN, SUPERADMIN |
| `show?` | ✅ `can_view_initiations?` | Level >= 30 | INITIATION, ORGANIZER, MODERATOR, ADMIN, SUPERADMIN |
| `create?` | ✅ `admin_user?` | Level >= 60 | ADMIN, SUPERADMIN |
| `update?` | ✅ `admin_user?` | Level >= 60 | ADMIN, SUPERADMIN |
| `destroy?` | ✅ `admin_user?` | Level >= 60 | ADMIN, SUPERADMIN |
| `presences?` | ✅ `admin_user?` | Level >= 60 | ADMIN, SUPERADMIN |
| `update_presences?` | ✅ `admin_user?` | Level >= 60 | ADMIN, SUPERADMIN |
| `convert_waitlist?` | ✅ `admin_user?` | Level >= 60 | ADMIN, SUPERADMIN |
| `notify_waitlist?` | ✅ `admin_user?` | Level >= 60 | ADMIN, SUPERADMIN |
| `toggle_volunteer?` | ✅ `admin_user?` | Level >= 60 | ADMIN, SUPERADMIN |
| `return_material?` | ✅ `can_view_initiations?` | Level >= 40 | INITIATION, ORGANIZER, MODERATOR, ADMIN, SUPERADMIN |

**Note** : Utilise `role&.level.to_i >= X` au lieu de `role&.code.in?(%w[...])` pour plus de flexibilité.

### **RollerStockPolicy**

| Action | Autorisation | Grade requis | Code |
|--------|--------------|--------------|------|
| `index?` | ✅ Hérite de BasePolicy | Level >= 60 | ADMIN, SUPERADMIN |
| `show?` | ✅ Hérite de BasePolicy | Level >= 60 | ADMIN, SUPERADMIN |
| `create?` | ✅ Hérite de BasePolicy | Level >= 60 | ADMIN, SUPERADMIN |
| `update?` | ✅ Hérite de BasePolicy | Level >= 60 | ADMIN, SUPERADMIN |
| `destroy?` | ✅ Hérite de BasePolicy | Level >= 60 | ADMIN, SUPERADMIN |

---

## ✅ Checklist Globale

### **Phase 5 (Semaine 5)**
- [x] Créer InitiationPolicy (permissions par grade)
- [x] Créer RollerStockPolicy
- [x] Tester autorisations avec différents rôles (tests RSpec)
- [x] Vérifier redirections si non autorisé

---

## 🧪 Tests RSpec

**Fichier** : `spec/policies/admin_panel/event/initiation_policy_spec.rb`

**Couverture** :
- ✅ Tests lecture (level >= 30) : index?, show?
- ✅ Tests écriture (level >= 60) : create?, update?, destroy?
- ✅ Tests actions spéciales (level >= 60) : presences?, convert_waitlist?, etc.
- ✅ Tests tous les grades (30, 40, 50, 60, 70)

**Exécution** :
```bash
bundle exec rspec spec/policies/admin_panel/event/initiation_policy_spec.rb
```

---

**Retour** : [README Initiations](./README.md) | [INDEX principal](../INDEX.md) | [Permissions complètes](../PERMISSIONS.md)
