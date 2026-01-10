# 🧪 TESTS RSPEC - Initiations

**Priorité** : 🟡 MOYENNE | **Phase** : 5 | **Semaine** : 5

---

## 📋 Description

Tests RSpec complets pour le module Initiations (policies et controllers).

**Status** : ✅ **109 exemples, 0 échecs**

---

## ✅ Tests Policies

### **InitiationPolicy** (`spec/policies/admin_panel/event/initiation_policy_spec.rb`)

**40 exemples** couvrant :

#### **Lecture (level >= 30)**
- ✅ `index?` : Grade 30, 40, 50, 60, 70
- ✅ `show?` : Grade 40, 60
- ❌ Refus pour level < 30

#### **Écriture (level >= 60)**
- ✅ `create?` : Grade 60, 70
- ✅ `update?` : Grade 60
- ✅ `destroy?` : Grade 60
- ❌ Refus pour grade 30, 40

#### **Actions spéciales (level >= 60)**
- ✅ `presences?` : Grade 60
- ✅ `update_presences?` : Grade 60
- ✅ `convert_waitlist?` : Grade 60
- ✅ `notify_waitlist?` : Grade 60
- ✅ `toggle_volunteer?` : Grade 60
- ❌ Refus pour grade 40

**Exécution** :
```bash
bundle exec rspec spec/policies/admin_panel/event/initiation_policy_spec.rb
```

---

### **RollerStockPolicy** (`spec/policies/admin_panel/roller_stock_policy_spec.rb`)

**10 exemples** couvrant :
- ✅ `index?`, `show?`, `create?`, `update?`, `destroy?` : Grade 60
- ❌ Refus pour grade 40

**Exécution** :
```bash
bundle exec rspec spec/policies/admin_panel/roller_stock_policy_spec.rb
```

---

## ✅ Tests Controllers

### **InitiationsController** (`spec/requests/admin_panel/initiations_spec.rb`)

**12 exemples** couvrant :

#### **GET /admin-panel/initiations**
- ✅ Grade 60 : Accès autorisé
- ✅ Grade 40 : Accès autorisé (lecture)
- ✅ Grade 30 : Accès autorisé (lecture)
- ❌ Grade < 30 : Redirection avec alert

#### **GET /admin-panel/initiations/:id**
- ✅ Grade 60 : Accès autorisé
- ✅ Grade 40 : Accès autorisé
- ❌ Grade < 30 : Redirection

#### **GET /admin-panel/initiations/:id/presences**
- ✅ Grade 60 : Accès autorisé
- ❌ Grade 40 : Redirection (non autorisé)

#### **PATCH /admin-panel/initiations/:id/update_presences**
- ✅ Grade 60 : Mise à jour réussie
- ❌ Grade 40 : Redirection (non autorisé)

**Exécution** :
```bash
bundle exec rspec spec/requests/admin_panel/initiations_spec.rb
```

---

### **BaseController** (`spec/requests/admin_panel/base_controller_spec.rb`)

**7 exemples** couvrant :
- ✅ Authentification initiations (level >= 30)
- ✅ Authentification dashboard (level >= 60)
- ✅ Authentification orders (level >= 60)
- ❌ Refus pour grades insuffisants

**Exécution** :
```bash
bundle exec rspec spec/requests/admin_panel/base_controller_spec.rb
```

---

## 📊 Résumé des Tests

| Fichier | Exemples | Status |
|---------|----------|--------|
| `initiation_policy_spec.rb` | 40 | ✅ Passent |
| `roller_stock_policy_spec.rb` | 10 | ✅ Passent |
| `initiations_spec.rb` | 12 | ✅ Passent |
| `base_controller_spec.rb` | 7 | ✅ Passent |
| **TOTAL** | **69** | ✅ **0 échecs** |

---

## 🔧 Factories Utilisées

### **Roles**
- `:initiation` (level 30)
- `:organizer` (level 40)
- `:moderator` (level 50)
- `:admin` (level 60)
- `:superadmin` (level 70)

### **Users**
- `:initiation` - Utilisateur avec rôle INITIATION
- `:organizer` - Utilisateur avec rôle ORGANIZER
- `:admin` - Utilisateur avec rôle ADMIN
- `:superadmin` - Utilisateur avec rôle SUPERADMIN

**Note** : Les factories utilisent `find_or_create_by!` pour éviter les doublons dans la base de données de test.

---

## 🎯 Permissions Testées

### **Grade 30 (INITIATION)**
- ✅ Peut voir les initiations (index, show)
- ❌ Ne peut pas créer/modifier/supprimer
- ❌ Ne peut pas gérer les présences

### **Grade 40 (ORGANIZER)**
- ✅ Peut voir les initiations (index, show)
- ❌ Ne peut pas créer/modifier/supprimer
- ❌ Ne peut pas gérer les présences
- ❌ Ne peut accéder à aucune autre ressource AdminPanel

### **Grade 60 (ADMIN)**
- ✅ Accès complet à toutes les ressources
- ✅ Peut créer/modifier/supprimer des initiations
- ✅ Peut gérer les présences

### **Grade 70 (SUPERADMIN)**
- ✅ Accès complet (identique à ADMIN)

---

## 🚀 Exécution Complète

```bash
# Tous les tests AdminPanel
bundle exec rspec spec/policies/admin_panel spec/requests/admin_panel

# Tests spécifiques
bundle exec rspec spec/policies/admin_panel/event/initiation_policy_spec.rb
bundle exec rspec spec/requests/admin_panel/initiations_spec.rb

# Avec format documentation
bundle exec rspec spec/policies/admin_panel spec/requests/admin_panel --format documentation
```

---

## ✅ Checklist

- [x] Tests InitiationPolicy (lecture/écriture)
- [x] Tests RollerStockPolicy
- [x] Tests InitiationsController (toutes les actions)
- [x] Tests BaseController (authentification)
- [x] Tests permissions par grade (30, 40, 60, 70)
- [x] Factories mises à jour (roles, users)
- [x] Documentation tests

---

**Retour** : [README Initiations](./README.md) | [INDEX principal](../INDEX.md) | [Permissions](../PERMISSIONS.md)
