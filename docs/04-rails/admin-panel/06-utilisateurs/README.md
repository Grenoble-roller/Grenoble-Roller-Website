# 👥 UTILISATEURS - Plan d'Implémentation

**Priorité** : 🟡 MOYENNE | **Phase** : 6 | **Semaine** : 6+

---

## 📋 Vue d'ensemble

Gestion des utilisateurs, rôles et adhésions.

**Status actuel** : ✅ **100% IMPLÉMENTÉ** - Module complet fonctionnel dans AdminPanel (2025-01-13)

**Note** : Les candidatures organisateur (OrganizerApplications) sont gérées dans [`04-evenements/`](../04-evenements/README.md)

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

### **📁 Fichiers par fonctionnalité**
- [`utilisateurs.md`](./utilisateurs.md) - Gestion utilisateurs
- [`roles.md`](./roles.md) - Gestion rôles
- [`adhesions.md`](./adhesions.md) - Gestion adhésions

---

## 🎯 Fonctionnalités Incluses

### ✅ Users (Utilisateurs)
- Liste avec filtres (email, nom, rôle, bénévole, confirmé)
- Détails complets (infos perso, adresse, confirmation email, préférences)
- Édition (infos, mot de passe, rôle, avatar)
- Suppression
- Panel inscriptions (attendances)

### ✅ Roles (Rôles)
- Liste avec filtres
- CRUD complet
- Panel utilisateurs associés

### ✅ Memberships (Adhésions)
- Liste avec scopes (actives, en attente, expirées, personnelles, enfants)
- Détails complets (adhésion, enfant, questionnaire santé, consentements)
- Action personnalisée : `activate` (valider adhésion)
- Gestion adhésions enfants (infos parent, autorisation)

---

## ✅ Checklist Globale

### **Phase 6 (Semaine 6+)**
- [x] Controller Users ✅ **IMPLÉMENTÉ**
- [x] Controller Roles ✅ **IMPLÉMENTÉ**
- [x] Controller Memberships ✅ **IMPLÉMENTÉ**
- [x] Policies (Users, Roles, Memberships) ✅ **IMPLÉMENTÉES**
- [x] Routes ✅ **IMPLÉMENTÉES**
- [x] Vues (index, show, edit, new) ✅ **IMPLÉMENTÉES** (12 vues au total)
- [x] Sidebar ✅ **AJOUTÉE** (menu Utilisateurs avec sous-menu)
- [x] Tests RSpec ✅ **CRÉÉS** (3 policies + 3 controllers)

---

## 🔗 Dépendances

- **Orders** : Pour afficher commandes utilisateur
- **Initiations/Events** : Pour afficher participations utilisateur

---

## 📊 Estimation

- **Temps** : 2 semaines
- **Complexité** : ⭐⭐⭐⭐
- **Dépendances** : Commandes, Initiations, Events

---

**Retour** : [INDEX principal](../INDEX.md)
