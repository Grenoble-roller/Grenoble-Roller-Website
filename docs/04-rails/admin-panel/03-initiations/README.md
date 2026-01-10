# 🎓 INITIATIONS - Plan d'Implémentation

**Priorité** : 🟡 MOYENNE | **Phase** : 5 | **Semaine** : 5

---

## 📋 Vue d'ensemble

Gestion des initiations : participants, bénévoles, liste d'attente, présences.

**Objectif** : Migrer la gestion des initiations depuis ActiveAdmin vers AdminPanel pour une interface unifiée.

**Status actuel** : ✅ **IMPLÉMENTÉ** - Module complet fonctionnel dans AdminPanel

---

## 📄 Documentation

### **📁 Fichiers détaillés par type (CODE EXACT)**
- [`01-migrations.md`](./01-migrations.md) - Migrations (code exact)
- [`02-modeles.md`](./02-modeles.md) - Modèles (code exact)
- [`03-services.md`](./03-services.md) - Services (code exact)
- [`04-controllers.md`](./04-controllers.md) - Controllers (code exact)
- [`05-routes.md`](./05-routes.md) - Routes (code exact)
- [`06-policies.md`](./06-policies.md) - Policies (code exact)
- [`07-vues.md`](./07-vues.md) - Vues ERB (code exact)
- [`08-javascript.md`](./08-javascript.md) - JavaScript (code exact)
- [`09-tests.md`](./09-tests.md) - Tests RSpec (code exact)

### **📁 Fichiers par fonctionnalité**
- [`gestion-initiations.md`](./gestion-initiations.md) - Workflow complet initiations
- [`stock-rollers.md`](./stock-rollers.md) - Gestion stock rollers

---

## 🎯 Fonctionnalités Incluses

### ✅ Controller Initiations
- CRUD initiations
- Gestion participants/bénévoles
- Liste d'attente (convertir, notifier)
- Dashboard présences
- **Séparation initiations à venir / passées** (triées par date)
- **Récapitulatif matériel demandé** (groupé par taille)

### ✅ Policy Initiation
- Autorisations admin (ADMIN et SUPERADMIN uniquement)

### ✅ Routes Initiations
- Routes REST + actions personnalisées

### ✅ Vues Initiations
- **Index** : Liste séparée (à venir / passées), bouton "Créer une initiation" (admin uniquement)
- **Show** : Détails + panels, bouton "Éditer" (admin uniquement, ouvre dans nouvel onglet)
- **Presences** : Dashboard présences avec statuts traduits en français

### ✅ RollerStock (Stock Rollers)
- Liste avec filtres (taille, quantité, actif)
- CRUD complet
- Panel "Demandes en attente" (attendances avec besoin matériel)
- Gestion tailles (EU)
- Activation/désactivation tailles

---

## ✅ Checklist Globale

### **Phase 5 (Semaine 5)**
- [x] Controller InitiationsController (séparation à venir/passées)
- [x] Controller RollerStock
- [x] Policy InitiationPolicy (permissions par grade)
- [x] Policy RollerStock
- [x] Routes initiations + roller_stock
- [x] Vue index (sections séparées, bouton création conditionnel)
- [x] Vue show (panel matériel, bouton édition conditionnel)
- [x] Vue presences (statuts traduits)
- [x] Vues RollerStock (index, show, edit, new)
- [x] Helpers traduction (attendance_status_fr, waitlist_status_fr)
- [x] Tests RSpec (109 exemples, 0 échecs)

---

## 📊 Estimation

- **Temps** : 1-2 semaines
- **Complexité** : ⭐⭐⭐
- **Dépendances** : Aucune (utilise le modèle `Attendance` existant pour demandes matériel)
- **Status** : ✅ **TERMINÉ** - Implémentation complète avec tests

---

## 🔐 Permissions

**Voir documentation complète** : [`../PERMISSIONS.md`](../PERMISSIONS.md)

**Résumé** :
- **Grade 30+** (INITIATION, ORGANIZER, MODERATOR) : Lecture seule des initiations
- **Grade 60+** (ADMIN, SUPERADMIN) : Accès complet (création, modification, présences)

**Implémentation** : Utilise `role&.level.to_i >= X` (niveaux numériques) au lieu des codes de rôle.

---

## 🧪 Tests RSpec

**Status** : ✅ Tests complets (109 exemples, 0 échecs)

**Fichiers** :
- `spec/policies/admin_panel/event/initiation_policy_spec.rb` - Tests InitiationPolicy
- `spec/policies/admin_panel/roller_stock_policy_spec.rb` - Tests RollerStockPolicy
- `spec/requests/admin_panel/initiations_spec.rb` - Tests InitiationsController

**Exécution** :
```bash
bundle exec rspec spec/policies/admin_panel/event/initiation_policy_spec.rb
bundle exec rspec spec/requests/admin_panel/initiations_spec.rb
```

---

**Retour** : [INDEX principal](../INDEX.md) | [Permissions complètes](../PERMISSIONS.md)
