# 📅 ÉVÉNEMENTS - Plan d'Implémentation

**Priorité** : 🟡 MOYENNE | **Phase** : 4 | **Semaine** : 6+

---

## 📋 Vue d'ensemble

Gestion des événements (randonnées, sorties) et routes.

**Status actuel** : 
- ✅ **Events** : Migré vers AdminPanel (100% fonctionnel)
- ✅ **Routes** : Migré vers AdminPanel (100% fonctionnel)
- ✅ **Attendances** : Migré vers AdminPanel (100% fonctionnel)
- ✅ **OrganizerApplications** : Migré vers AdminPanel (100% fonctionnel)

**Note** : Les initiations (Event::Initiation) sont gérées séparément dans [`03-initiations/`](../03-initiations/README.md)

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
- [`randonnees.md`](./randonnees.md) - Gestion randonnées (Events)
- [`routes.md`](./routes.md) - Gestion routes/parcours
- [`participations.md`](./participations.md) - Gestion participations (Attendances)
- [`candidatures-organisateur.md`](./candidatures-organisateur.md) - Candidatures organisateur

---

## 🎯 Fonctionnalités Incluses

### ✅ Events (Randonnées)
- Liste avec scopes (à venir, publiés, en attente validation, refusés, annulés)
- Filtres (titre, statut, route, créateur, date)
- Détails complets (infos, inscriptions, liste d'attente)
- Actions personnalisées : `convert_waitlist`, `notify_waitlist`
- CRUD complet
- Gestion image de couverture (Active Storage)

### ✅ Routes (Parcours)
- Liste avec scopes (faciles, intermédiaires, difficiles)
- Filtres (nom, difficulté, distance, dénivelé)
- Détails avec panel événements associés
- CRUD complet
- Gestion carte (GPX, image)

### ✅ Attendances (Participations)
- Liste avec scopes (actives, annulées)
- Filtres (utilisateur, événement, statut, matériel)
- Détails complets (infos participant, matériel, paiement)
- CRUD complet
- Gestion besoin matériel (rollers)

### ✅ OrganizerApplications (Candidatures Organisateur)
- Liste avec scopes (en attente, approuvées, refusées)
- Actions personnalisées : `approve`, `reject`
- Suivi review (reviewed_by, reviewed_at)

---

## ✅ Checklist Globale

### **Phase 4 (Semaine 6+)**
- [x] Controller Events ✅ **IMPLÉMENTÉ**
- [x] Policy Event ✅ **IMPLÉMENTÉE**
- [x] Routes Events ✅ **IMPLÉMENTÉES** (RESTful partiel intentionnel)
- [x] Vues Events (index, show) ✅ **IMPLÉMENTÉES**
- [x] Controller Routes ✅ **IMPLÉMENTÉ**
- [x] Controller Attendances ✅ **IMPLÉMENTÉ**
- [x] Controller OrganizerApplications ✅ **IMPLÉMENTÉ**
- [x] Policies (Routes, Attendances, OrganizerApplications) ✅ **IMPLÉMENTÉES**
- [x] Routes (Routes, Attendances, OrganizerApplications) ✅ **IMPLÉMENTÉES** (RESTful)
- [x] Vues (Routes, Attendances, OrganizerApplications) ✅ **IMPLÉMENTÉES**
- [x] Tests RSpec Routes ✅ **18 exemples, 0 échecs**
- [x] Tests RSpec Attendances ✅ **18 exemples, 0 échecs**
- [x] Tests RSpec OrganizerApplications ✅ **20 exemples, 0 échecs**
- [x] Factory OrganizerApplication ✅ **CRÉÉE**
- [x] Factory Attendance ✅ **MISE À JOUR**

**Status** : ✅ **100% COMPLÉTÉ** - Tous les modules Événements sont migrés vers AdminPanel et fonctionnels avec tests RSpec complets

---

## 🔗 Dépendances

- **Users** : Pour afficher créateur et participants
- **Payments** : Pour afficher paiements liés
- **RollerStock** : Pour gestion matériel

---

## 📊 Estimation

- **Temps** : 2-3 semaines
- **Complexité** : ⭐⭐⭐⭐
- **Dépendances** : Utilisateurs, Paiements, Matériel

---

**Retour** : [INDEX principal](../INDEX.md)
