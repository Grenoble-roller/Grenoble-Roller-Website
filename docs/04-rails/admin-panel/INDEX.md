# 📋 INDEX - Plan d'Implémentation Admin Panel

**Date** : 2025-01-13 | **Version** : 3.0 | **État** : ✅ **100% complété** | **Dernière mise à jour** : 2025-01-13

> 📖 **Index principal** : Ce fichier recense tous les blocs indépendants organisés par thème métier et contient le guide complet d'implémentation.

---

## 🎯 Organisation par Thème

Cette documentation est organisée par **thème métier** (boutique, commandes, initiations, etc.) plutôt que par type technique (migrations, models, controllers).

Chaque thème contient **tous les éléments nécessaires** (migrations, modèles, controllers, vues, etc.) pour être **indépendant** et **implémentable séparément**.

---

## 📂 Structure par Thème

### 📊 00 - TABLEAU DE BORD

**Description** : Dashboard principal avec KPIs, statistiques et vue d'ensemble

**Fichiers** :
- [`00-dashboard/README.md`](./00-dashboard/README.md) - Vue d'ensemble dashboard
- [`00-dashboard/dashboard.md`](./00-dashboard/dashboard.md) - Implémentation complète
- [`00-dashboard/sidebar.md`](./00-dashboard/sidebar.md) - 🎨 **Sidebar Admin Panel** (structure, optimisations)

**Éléments inclus** :
- ✅ Controller Dashboard ✅ **AMÉLIORÉ** (utilise AdminDashboardService)
- ✅ Vue Dashboard ✅ **AMÉLIORÉE** (8 KPIs, graphique, initiations)
- ✅ Service AdminDashboardService ✅ **CRÉÉ** (KPIs, ventes, initiations)
- ✅ KPIs avancés ✅ **IMPLÉMENTÉS** (CA, stock, initiations)
- ✅ Graphiques ventes ✅ **IMPLÉMENTÉ** (7 derniers jours)
- ✅ Actions rapides ✅ **IMPLÉMENTÉES**
- ✅ Mode Maintenance ✅ **IMPLÉMENTÉ** (controller, route, toggle activation/désactivation)
- ✅ Mission Control Jobs ✅ **INTÉGRÉ** (monitoring des jobs Solid Queue)
- ✅ **Sidebar Admin Panel** (partial réutilisable, sous-menus, optimisations)

**Priorité** : 🔴 HAUTE | **Phase** : 0-1 | **Semaine** : 1  
**Version** : 1.1 | **Dernière mise à jour** : 2025-01-13

**Note** : Point d'entrée principal de l'Admin Panel - ✅ **AMÉLIORÉ ET FONCTIONNEL**

**Éléments système intégrés** :
- ✅ Mission Control Jobs (monitoring Solid Queue) - Monté à `/admin-panel/jobs`
- ✅ Mail Logs (logs emails) - Accessible via routes `/admin-panel/mail-logs` (SUPERADMIN uniquement)

---

### 🛒 01 - BOUTIQUE

**Description** : Gestion des produits, variantes, inventaire et catégories

**Fichiers** :
- [`01-boutique/README.md`](./01-boutique/README.md) - Vue d'ensemble boutique
- [`01-boutique/produits.md`](./01-boutique/produits.md) - Gestion produits
- [`01-boutique/variantes.md`](./01-boutique/variantes.md) - Gestion variantes (GRID éditeur)
- [`01-boutique/inventaire.md`](./01-boutique/inventaire.md) - Tracking stock (inventories)
- [`01-boutique/categories.md`](./01-boutique/categories.md) - Gestion catégories

**Éléments inclus** :
- ✅ Migrations (inventories, inventory_movements, active_storage)
- ✅ Modèles (Inventory, InventoryMovement, modifications ProductVariant)
- ✅ Controllers (Products, ProductVariants, Inventory)
- ✅ Services (InventoryService)
- ✅ Policies (Product, Inventory)
- ✅ Vues (Products, ProductVariants GRID, Inventory dashboard)
- ✅ JavaScript (GRID éditeur Stimulus)

**Priorité** : 🔴 HAUTE | **Phase** : 1-3 | **Semaines** : 1-4

---

### 📦 02 - COMMANDES

**Description** : Gestion des commandes et workflow stock (reserve/release)

**Fichiers** :
- [`02-commandes/README.md`](./02-commandes/README.md) - Vue d'ensemble commandes
- [`02-commandes/gestion-commandes.md`](./02-commandes/gestion-commandes.md) - Workflow complet

**Éléments inclus** :
- ✅ Modifications Order (reserve/release stock) ✅ **IMPLÉMENTÉ ET TESTÉ**
- ✅ Controller Orders (workflow) ✅ **IMPLÉMENTÉ ET TESTÉ**
- ✅ Controller Carts (utilise Inventories) ✅ **IMPLÉMENTÉ ET TESTÉ**
- ✅ Policy Order ✅ **IMPLÉMENTÉ**
- ✅ Vues Orders ✅ **IMPLÉMENTÉ ET AMÉLIORÉ** (affichage stock détaillé)
- ✅ Tests complets ✅ **38/38 TESTS PASSENT** (100%)

**Priorité** : 🔴 HAUTE | **Phase** : 1-2 | **Semaines** : 1-2

**Status** : ✅ **100% IMPLÉMENTÉ ET TESTÉ** - Workflow stock intégré avec Inventories, tous les tests passent (2025-01-13)

---

### 🎓 03 - INITIATIONS

**Description** : Gestion des initiations, participants, bénévoles, liste d'attente

**Fichiers** :
- [`03-initiations/README.md`](./03-initiations/README.md) - Vue d'ensemble initiations
- [`03-initiations/gestion-initiations.md`](./03-initiations/gestion-initiations.md) - Workflow complet

**Éléments inclus** :
- ✅ Controller Initiations (séparation à venir/passées)
- ✅ Controller RollerStock (stock rollers)
- ✅ Policy Initiation (lecture level >= 30, écriture level >= 60)
- ✅ Policy RollerStock (level >= 60)
- ✅ Vues (index avec sections séparées, show avec panel matériel, presences)
- ✅ Vues RollerStock (index, show, edit, new)
- ✅ Routes initiations + roller_stock
- ✅ **Tests RSpec complets** (109 exemples, 0 échecs)

**Priorité** : 🟡 MOYENNE | **Phase** : 5 | **Semaine** : 5

**Status** : ✅ **IMPLÉMENTÉ** - Module complet fonctionnel avec permissions par grade

**Permissions** : 
- Grade 40+ (INITIATION, MODERATOR) : Lecture seule
- Grade 60+ (ADMIN, SUPERADMIN) : Accès complet
- Grade 30 (ORGANIZER) : Aucun accès

---

### 📅 04 - ÉVÉNEMENTS

**Description** : Gestion des événements (randonnées, sorties) et routes

**Fichiers** :
- [`04-evenements/README.md`](./04-evenements/README.md) - Vue d'ensemble événements
- [`04-evenements/randonnees.md`](./04-evenements/randonnees.md) - Gestion randonnées (Events)
- [`04-evenements/routes.md`](./04-evenements/routes.md) - Gestion routes/parcours
- [`04-evenements/participations.md`](./04-evenements/participations.md) - Gestion participations (Attendances)

**Éléments inclus** :
- ✅ Controller Events ✅ **IMPLÉMENTÉ** (index, show, destroy, convert_waitlist, notify_waitlist)
- ✅ Controller Routes ✅ **IMPLÉMENTÉ** (CRUD complet)
- ✅ Controller Attendances ✅ **IMPLÉMENTÉ** (CRUD complet)
- ✅ Controller OrganizerApplications ✅ **IMPLÉMENTÉ** (index, show, approve, reject, destroy)
- ✅ Policies (Event, Route, Attendance, OrganizerApplication) ✅ **IMPLÉMENTÉES**
- ✅ Routes RESTful ✅ **IMPLÉMENTÉES** (Routes/Attendances CRUD complet, OrganizerApplications RESTful avec actions custom)
- ✅ Vues Events (index, show) ✅ **IMPLÉMENTÉES** (new/edit utilisent formulaires publics)
- ✅ Vues Routes (index, show, new, edit) ✅ **IMPLÉMENTÉES**
- ✅ Vues Attendances (index, show, new, edit) ✅ **IMPLÉMENTÉES**
- ✅ Vues OrganizerApplications (index, show) ✅ **IMPLÉMENTÉES**
- ✅ Menu sidebar ✅ **AJOUTÉ** (sous-menu Événements avec 4 items)
- ✅ Tests RSpec ✅ **56 exemples, 0 échecs** (Routes: 18, Attendances: 18, OrganizerApplications: 20)
- ✅ Factories ✅ **CRÉÉES/MISES À JOUR** (OrganizerApplication créée, Attendance mise à jour)

**Priorité** : 🟡 MOYENNE | **Phase** : 4 | **Semaine** : 6+

**Status** : ✅ **100% IMPLÉMENTÉ dans AdminPanel** - Tous les modules migrés avec tests RSpec complets (2025-01-13)

**Note** : 
- Les initiations (Event::Initiation) sont gérées séparément dans [`03-initiations/`](./03-initiations/README.md)
- Les formulaires new/edit pour Events utilisent les routes publiques existantes (`new_event_path`, `edit_event_path`)
- **Routes, Attendances, OrganizerApplications** : Actuellement gérés par **ActiveAdmin** (fonctionnel) - Migration vers AdminPanel optionnelle
- Voir [`04-evenements/STATUS.md`](./04-evenements/STATUS.md) pour le détail de l'implémentation

---

### 📧 05 - MAILING (Futur)

**Description** : Gestion des emails et notifications

**Fichiers** :
- [`05-mailing/README.md`](./05-mailing/README.md) - Vue d'ensemble mailing

**Priorité** : 🟢 BASSE | **Phase** : Future | **Semaine** : 6+

**Note** : Voir documentation existante dans [`docs/04-rails/mailing/`](../mailing/)

---

### 👥 06 - UTILISATEURS

**Description** : Gestion des utilisateurs, rôles, adhésions et candidatures organisateur

**Fichiers** :
- [`06-utilisateurs/README.md`](./06-utilisateurs/README.md) - Vue d'ensemble utilisateurs
- [`06-utilisateurs/utilisateurs.md`](./06-utilisateurs/utilisateurs.md) - Gestion utilisateurs
- [`06-utilisateurs/roles.md`](./06-utilisateurs/roles.md) - Gestion rôles
- [`06-utilisateurs/adhesions.md`](./06-utilisateurs/adhesions.md) - Gestion adhésions
- [`06-utilisateurs/candidatures-organisateur.md`](./06-utilisateurs/candidatures-organisateur.md) - Candidatures organisateur

**Éléments inclus** :
- ✅ Controller Users ✅ **IMPLÉMENTÉ** (CRUD complet, filtres Ransack, gestion password)
- ✅ Controller Roles ✅ **IMPLÉMENTÉ** (CRUD complet, filtres par level)
- ✅ Controller Memberships ✅ **IMPLÉMENTÉ** (CRUD complet, scopes, action activate)
- ✅ Policies (Users, Roles, Memberships) ✅ **IMPLÉMENTÉES** (héritent de BasePolicy)
- ✅ Routes ✅ **IMPLÉMENTÉES** (users, roles, memberships avec activate)
- ✅ Vues (index, show, edit, new) ✅ **IMPLÉMENTÉES** (12 vues au total)
- ✅ Sidebar ✅ **AJOUTÉE** (menu Utilisateurs avec sous-menu)

**Note** : OrganizerApplications est géré dans [`04-evenements/`](./04-evenements/README.md)

**Priorité** : 🟡 MOYENNE | **Phase** : 6 | **Semaine** : 6+

**Status** : ✅ **100% IMPLÉMENTÉ** - Module complet fonctionnel avec CRUD complet pour Users, Roles et Memberships (2025-01-13)

---

### ⚙️ 08 - SYSTÈME

**Description** : Gestion système : paiements, logs emails, monitoring jobs

**Fichiers** :
- [`08-systeme/README.md`](./08-systeme/README.md) - Vue d'ensemble système
- [`08-systeme/STATUS.md`](./08-systeme/STATUS.md) - État d'implémentation
- [`08-systeme/paiements.md`](./08-systeme/paiements.md) - Gestion paiements

**Éléments inclus** :
- ✅ Controller Payments ✅ **IMPLÉMENTÉ** (index, show, destroy)
- ✅ Policy Payments ✅ **IMPLÉMENTÉE** (level >= 60)
- ✅ Routes Payments ✅ **IMPLÉMENTÉES** (RESTful)
- ✅ Vues Payments ✅ **IMPLÉMENTÉES** (index avec filtres Ransack, show avec panels Orders/Memberships/Attendances)
- ✅ Menu sidebar ✅ **AJOUTÉ** (sous-menu Commandes)
- ✅ Tests RSpec ✅ **20 exemples, 0 échecs**
- ✅ Factory Payment ✅ **CRÉÉE**
- ✅ Controller MailLogs ✅ **IMPLÉMENTÉ** (logs emails, SUPERADMIN uniquement)
- ✅ Routes MailLogs ✅ **IMPLÉMENTÉES** (index, show)
- ✅ Mission Control Jobs ✅ **INTÉGRÉ** (monitoring Solid Queue, monté dans routes)

**Priorité** : 🟡 MOYENNE | **Phase** : 8 | **Semaine** : 8+

**Status** : ✅ **100% IMPLÉMENTÉ** - Module Payments complet et opérationnel dans AdminPanel (2025-01-13)

**Note** : 
- **Maintenance** → Géré dans [`00-dashboard/`](./00-dashboard/README.md) ✅ **IMPLÉMENTÉ**
- **MailLogs** → ✅ **IMPLÉMENTÉ** (accès SUPERADMIN uniquement, level >= 70)
- **Mission Control Jobs** → ✅ **INTÉGRÉ** (dashboard monitoring jobs, utilise BaseController pour auth)
- **AuditLogs** → Non prioritaire (peu utilisé)

---

### 📢 07 - COMMUNICATION

**Description** : Gestion des messages de contact et partenaires

**Fichiers** :
- [`07-communication/README.md`](./07-communication/README.md) - Vue d'ensemble communication
- [`07-communication/messages-contact.md`](./07-communication/messages-contact.md) - Messages de contact
- [`07-communication/partenaires.md`](./07-communication/partenaires.md) - Gestion partenaires

**Éléments inclus** :
- ⚠️ **À CRÉER** : Formulaire de contact public (pas de formulaire actuellement)
- ✅ Controller ContactMessages (AdminPanel)
- ✅ Controller Partners
- ✅ Policies (ContactMessages, Partners)
- ✅ Vues (formulaire public + admin index/show)

**Priorité** : 🟢 BASSE | **Phase** : 7 | **Semaine** : 7+

**Note** : Actuellement géré via ActiveAdmin, à migrer vers AdminPanel

---

### ⚙️ 08 - SYSTÈME

**Description** : Gestion système : logs d'audit, maintenance, paiements

**Fichiers** :
- [`08-systeme/README.md`](./08-systeme/README.md) - Vue d'ensemble système
- [`08-systeme/STATUS.md`](./08-systeme/STATUS.md) - État d'implémentation
- [`08-systeme/audit-logs.md`](./08-systeme/audit-logs.md) - Logs d'audit
- [`08-systeme/maintenance.md`](./08-systeme/maintenance.md) - Mode maintenance
- [`08-systeme/paiements.md`](./08-systeme/paiements.md) - Gestion paiements

**Éléments inclus** :
- ✅ Controller Payments ✅ **IMPLÉMENTÉ** (index, show, destroy)
- ✅ Policy Payments ✅ **IMPLÉMENTÉE** (index/show: level >= 60, destroy: level >= 70 ⚠️ SUPERADMIN uniquement)
- ✅ Routes Payments ✅ **IMPLÉMENTÉES** (RESTful)
- ✅ Vues Payments ✅ **IMPLÉMENTÉES** (index avec filtres Ransack, show avec panels Orders/Memberships/Attendances, boutons groupés)
- ✅ Menu sidebar ✅ **AJOUTÉ** (sous-menu Commandes)
- ✅ Tests RSpec ✅ **22 exemples, 0 échecs**
- ✅ Factory Payment ✅ **CRÉÉE**
- ✅ Sécurité ✅ **RENFORCÉE** (suppression SUPERADMIN uniquement + disclaimer explicite + bouton rouge)
- ✅ Controller MailLogs ✅ **IMPLÉMENTÉ** (logs emails, SUPERADMIN uniquement)
- ✅ Routes MailLogs ✅ **IMPLÉMENTÉES** (index, show)
- ✅ Mission Control Jobs ✅ **INTÉGRÉ** (monitoring Solid Queue, monté dans routes)

**Note** : 
- **Maintenance** → Géré dans [`00-dashboard/`](./00-dashboard/README.md) ✅ **IMPLÉMENTÉ**
- **MailLogs** → ✅ **IMPLÉMENTÉ** (accès SUPERADMIN uniquement, level >= 70)
- **Mission Control Jobs** → ✅ **INTÉGRÉ** (dashboard monitoring jobs, utilise BaseController pour auth)
- **AuditLogs** → Non prioritaire (peu utilisé)

**Priorité** : 🟡 MOYENNE | **Phase** : 8 | **Semaine** : 8+

**Status** : ✅ **100% IMPLÉMENTÉ** - Module Payments complet et opérationnel dans AdminPanel (2025-01-13)

**Note** : Payments migré vers AdminPanel. ActiveAdmin reste disponible en parallèle.

---


## 📊 Vue d'Ensemble Globale

| Thème | Priorité | Phase | Semaines | % Complété | Status Sidebar |
|-------|----------|-------|----------|------------|----------------|
| **Sidebar** | 🔴 HAUTE | 0 | 1 | ✅ **100%** | ✅ Implémenté |
| **Dashboard** | 🔴 HAUTE | 0-1 | 1 | ✅ **100%** | ✅ Amélioré (KPIs, graphiques, intégrations, maintenance) |
| **Boutique** | 🔴 HAUTE | 1-3 | 1-4 | ✅ **100%** | ✅ Dans sidebar |
| **Commandes** | 🔴 HAUTE | 1-2 | 1-2 | ✅ **100%** (38/38 tests) | ✅ Dans sidebar |
| **Initiations** | 🟡 MOYENNE | 5 | 5 | ✅ **100%** | ✅ Dans sidebar |
| **Événements** | 🟡 MOYENNE | 4 | 6+ | ✅ **100%** | ✅ Tous les modules migrés + Tests RSpec (77 exemples, 0 échecs : 56 Routes/Attendances/OrganizerApplications + 21 Events) |
| **Utilisateurs** | 🟡 MOYENNE | 6 | 6+ | ✅ **100%** | ✅ Dans sidebar |
| **Communication** | 🟢 BASSE | 7 | 7+ | ✅ **100%** | ✅ Formulaire public + ContactMessages + Partners + Tests RSpec (36 exemples, 0 échecs) |
| **Système** | 🟡 MOYENNE | 8 | 8+ | ✅ **100%** | ✅ Payments migré + Tests RSpec (22 exemples, 0 échecs) + MailLogs + Mission Control |
| **Communication** | 🟢 BASSE | 7 | 7+ | ✅ **100%** | ✅ Formulaire public + ContactMessages + Partners + Tests RSpec (36 exemples, 0 échecs) |
| **Mailing** | 🟢 BASSE | Future | 6+ | - | ⏸️ En attente |

---

## 🚀 Ordre d'Implémentation Recommandé

### ✅ Chaque Thème est Indépendant

Chaque thème contient **tous les fichiers nécessaires** (migrations, modèles, controllers, routes, policies, vues, JavaScript) pour être **implémenté séparément**.

### **Phase 1 : Fondations (Semaine 1-2)**
1. **Boutique** 🔴 HAUTE
   - ✅ Aucune dépendance
   - ✅ Base pour Commandes et Dashboard
   - ✅ Migrations, modèles, services, controllers, vues, JavaScript

2. **Commandes** 🔴 HAUTE
   - ⚠️ Dépend de Boutique (Inventories)
   - ✅ Modifications Order (workflow stock)
   - ✅ Controllers, routes, policies, vues

3. **Dashboard** 🔴 HAUTE
   - ⚠️ Dépend de Boutique, Commandes (partiellement)
   - ✅ Peut être fait en parallèle avec améliorations progressives
   - ✅ Service, controller, vues, maintenance

### **Phase 2 : Fonctionnalités Indépendantes (Semaine 5-6)**
4. **Initiations** 🟡 MOYENNE
   - ✅ Aucune dépendance (utilise le modèle `Attendance` existant)
   - ✅ Controllers, routes, policies, vues, RollerStock

5. **Utilisateurs** 🟡 MOYENNE
   - ✅ Aucune dépendance
   - ✅ Controllers, routes, policies, vues ✅ **IMPLÉMENTÉ ET COMPLET**

### **Phase 3 : Fonctionnalités Avancées (Semaine 6+)**
6. **Événements** 🟡 MOYENNE
   - ⚠️ Dépend de Utilisateurs, Paiements (mais peut être fait indépendamment)
   - ✅ Controllers, routes, policies, vues

### **Phase 4 : Fonctionnalités Secondaires (Semaine 7+)**
7. **Communication** 🟢 BASSE
   - ✅ Aucune dépendance
   - ✅ Formulaire public + admin

8. **Système** 🟡 MOYENNE
   - ✅ Aucune dépendance
   - ✅ Controller Payments

---

## 📊 Dépendances entre Thèmes

### **Dépendances Critiques** (à respecter)

| Thème | Dépend de | Raison |
|-------|-----------|--------|
| **Dashboard** | Boutique, Commandes, Initiations | Affiche KPIs (stock, CA, initiations) |
| **Commandes** | Boutique (Inventories) | Utilise `InventoryService` pour reserve/release |
| **Événements** | Utilisateurs, Paiements | Affiche créateur, participants, paiements |

### **Thèmes Totalement Indépendants**

- ✅ **Boutique** - Aucune dépendance
- ✅ **Initiations** - Aucune dépendance (utilise le modèle `Attendance` existant)
- ✅ **Utilisateurs** - Aucune dépendance
- ✅ **Communication** - Aucune dépendance
- ✅ **Système** - Aucune dépendance

### **Résumé des Dépendances**

```
Boutique (indépendant)
  └── Commandes (dépend de Inventories)
  └── Dashboard (affiche KPIs)

Utilisateurs (indépendant)
  └── Événements (affiche créateur)

Initiations (indépendant, utilise le modèle Attendance existant)
Communication (indépendant)
Système (indépendant)
```


---

## 📋 Checklist Globale par Thème

### 📊 Dashboard
- [x] Améliorer DashboardController (KPIs avancés) ✅
- [x] Créer service AdminDashboardService ✅
- [x] Améliorer vue Dashboard (widgets, graphiques) ✅
- [x] Intégrer avec Inventories (stock faible) ✅
- [x] Intégrer avec Orders (CA, tendances) ✅
- [x] Intégrer avec Initiations (à venir) ✅
- [x] Intégrer Mode Maintenance dans Dashboard ✅

### 🛒 Boutique
- [x] Migrations (2 : inventories, inventory_movements)
- [x] Modèles (2 nouveaux + 1 modification)
- [x] Services (1 : InventoryService)
- [x] Controllers (3 : InventoryController, modifications ProductsController et ProductVariantsController)
- [x] Policies (2 : InventoryPolicy, ProductVariantPolicy)
- [x] Routes (inventory + product_variants avec bulk actions)
- [x] Vues (Dashboard inventaire, GRID variantes, partials)
- [x] JavaScript (1 : Stimulus GRID controller)
- [x] Sidebar (Menu Boutique réactivé avec sous-menus)

### 📦 Commandes
- [x] Modifications Order ✅ (callbacks reserve_stock et handle_stock_on_status_change)
- [x] Controller Orders ✅ (public et admin, workflow Inventories)
- [x] Controller Carts ✅ (utilise available_qty)
- [x] Policy Order ✅ (existe déjà)
- [x] Routes ✅ (existent déjà)
- [x] Vues ✅ (améliorées avec affichage stock détaillé)
- [x] Tests ✅ **38/38 PASSENT** (Order, OrdersController, AdminPanel::OrdersController, CartsController)

### 🎓 Initiations
- [x] Controller Initiations (séparation à venir/passées)
- [x] Controller RollerStock
- [x] Policy Initiation (permissions par grade)
- [x] Policy RollerStock
- [x] Routes initiations + roller_stock
- [x] Vues (index avec sections, show avec panel matériel, presences)
- [x] Vues RollerStock (index, show, edit, new)
- [x] Tests RSpec (109 exemples)

### 📅 Événements
- [x] Controller Events ✅ **IMPLÉMENTÉ** (index, show, destroy, waitlist actions)
- [x] Controller Routes ✅ **IMPLÉMENTÉ** (CRUD complet)
- [x] Controller Attendances ✅ **IMPLÉMENTÉ** (CRUD complet)
- [x] Controller OrganizerApplications ✅ **IMPLÉMENTÉ** (index, show, approve, reject, destroy)
- [x] Policies (Event, Route, Attendance, OrganizerApplication) ✅ **IMPLÉMENTÉES**
- [x] Routes (Events, Routes, Attendances, OrganizerApplications) ✅ **IMPLÉMENTÉES** (RESTful)
- [x] Vues Events (index, show) ✅ **IMPLÉMENTÉES** (new/edit utilisent formulaires publics)
- [x] Vues Routes (index, show, new, edit) ✅ **IMPLÉMENTÉES**
- [x] Vues Attendances (index, show, new, edit) ✅ **IMPLÉMENTÉES**
- [x] Vues OrganizerApplications (index, show) ✅ **IMPLÉMENTÉES**
- [x] Menu sidebar ✅ **AJOUTÉ** (sous-menu Événements avec 4 items)
- [x] Tests RSpec Routes ✅ **18 exemples, 0 échecs**
- [x] Tests RSpec Attendances ✅ **18 exemples, 0 échecs**
- [x] Tests RSpec OrganizerApplications ✅ **20 exemples, 0 échecs**
- [x] Factory OrganizerApplication ✅ **CRÉÉE**
- [x] Factory Attendance ✅ **MISE À JOUR** (free_trial_used, is_volunteer, needs_equipment)

### ⚙️ Système
- [x] Controller Payments ✅ **IMPLÉMENTÉ** (index, show, destroy)
- [x] Policy Payments ✅ **IMPLÉMENTÉE** (level >= 60)
- [x] Routes Payments ✅ **IMPLÉMENTÉES** (RESTful)
- [x] Vues Payments ✅ **IMPLÉMENTÉES** (index avec filtres Ransack, show avec panels)
- [x] Menu sidebar ✅ **AJOUTÉ** (sous-menu Commandes)
- [x] Tests RSpec Payments ✅ **20 exemples, 0 échecs**
- [x] Factory Payment ✅ **CRÉÉE**

### 👥 Utilisateurs
- [x] Controller Users ✅ **IMPLÉMENTÉ**
- [x] Controller Roles ✅ **IMPLÉMENTÉ**
- [x] Controller Memberships ✅ **IMPLÉMENTÉ**
- [x] Policies (Users, Roles, Memberships) ✅ **IMPLÉMENTÉES**
- [x] Routes ✅ **IMPLÉMENTÉES**
- [x] Vues (index, show, edit, new) ✅ **IMPLÉMENTÉES** (12 vues)
- [x] Sidebar ✅ **AJOUTÉE** (menu avec sous-menu)

### 📢 Communication
- [x] **CRÉER** : Formulaire de contact public ✅ **IMPLÉMENTÉ** (controller + vue publique)
- [x] Controller ContactMessages (AdminPanel) ✅ **IMPLÉMENTÉ** (index, show, destroy)
- [x] Controller Partners ✅ **IMPLÉMENTÉ** (CRUD complet)
- [x] Policies (ContactMessages, Partners) ✅ **IMPLÉMENTÉES** (level >= 60)
- [x] Routes (publique + admin) ✅ **IMPLÉMENTÉES** (RESTful)
- [x] Vues (formulaire public + admin index/show) ✅ **IMPLÉMENTÉES**
- [x] Menu sidebar ✅ **AJOUTÉ** (sous-menu Communication)
- [x] Tests RSpec ✅ **27 exemples, 0 échecs** (ContactMessages + Partners + formulaire public)

### 📢 Communication
- [x] Formulaire de contact public ✅ **CRÉÉ** (controller + vue publique)
- [x] Controller ContactMessages ✅ **IMPLÉMENTÉ** (index, show, destroy)
- [x] Controller Partners ✅ **IMPLÉMENTÉ** (CRUD complet)
- [x] Policies (ContactMessages, Partners) ✅ **IMPLÉMENTÉES** (level >= 60)
- [x] Routes (publique + admin) ✅ **IMPLÉMENTÉES** (RESTful)
- [x] Vues (formulaire public + admin) ✅ **IMPLÉMENTÉES**
- [x] Menu sidebar ✅ **AJOUTÉ** (sous-menu Communication)
- [x] Tests RSpec ✅ **36 exemples, 0 échecs**
- [x] Factories ✅ **CRÉÉES** (ContactMessage, Partner)

### ⚙️ Système
- [x] Controller Payments ✅ **IMPLÉMENTÉ** (index, show, destroy)
- [x] Policy Payments ✅ **IMPLÉMENTÉE** (index/show: level >= 60, destroy: level >= 70 ⚠️)
- [x] Routes Payments ✅ **IMPLÉMENTÉES** (RESTful)
- [x] Vues Payments ✅ **IMPLÉMENTÉES** (index avec filtres, show avec panels, boutons groupés)
- [x] Menu sidebar ✅ **AJOUTÉ** (sous-menu Commandes)
- [x] Tests RSpec ✅ **22 exemples, 0 échecs**
- [x] Factory Payment ✅ **CRÉÉE**
- [x] Sécurité ✅ **RENFORCÉE** (suppression SUPERADMIN uniquement + disclaimer explicite)
- [x] Controller MailLogs ✅ **IMPLÉMENTÉ**
- [x] Routes MailLogs ✅ **IMPLÉMENTÉES**
- [x] Mission Control Jobs ✅ **INTÉGRÉ** (monté dans routes)

### 📅 Événements (Tests finaux)
- [x] Tests RSpec EventsController ✅ **21 exemples, 0 échecs** (index, show, destroy, convert_waitlist, notify_waitlist)

### 📊 Dashboard
- [x] Mode Maintenance ✅ **IMPLÉMENTÉ** (controller + route + toggle)

---

## 🎯 Points Critiques par Thème

### 🛒 Boutique
1. **ProductVariant** : `has_one_attached :image` → `has_many_attached :images`
2. **ProductVariant** : Validation upload fichiers uniquement
3. **Inventories** : Création table + migration données

### 📦 Commandes
1. **Order** : Workflow reserve/release stock
2. **Order** : Intégration avec Inventories

---

## 📊 Estimation par Thème

| Thème | Temps Estimé | Complexité |
|-------|-------------|------------|
| **Dashboard** | 1 semaine | ⭐⭐⭐ |
| **Boutique** | 3-4 semaines | ⭐⭐⭐⭐⭐ |
| **Commandes** | 1-2 semaines | ⭐⭐⭐ |
| **Initiations** | 1 semaine | ⭐⭐⭐ |
| **Événements** | 2-3 semaines | ⭐⭐⭐⭐ |
| **Utilisateurs** | 2 semaines | ⭐⭐⭐⭐ |
| **Communication** | 1-2 semaines | ⭐⭐⭐ (formulaire à créer) |
| **Système** | 1 semaine | ⭐⭐⭐ |
| **TOTAL** | **12-16 semaines** | - |

---

## 📋 Comment Travailler sur un Thème

### **Étape 1 : Choisir un Thème**
Exemple : **Boutique**

### **Étape 2 : Ouvrir les Fichiers Détaillés**
```
01-boutique/
├── 01-migrations.md      ← Commencer ici
├── 02-modeles.md
├── 03-services.md
├── 04-controllers.md
├── 05-routes.md
├── 06-policies.md
├── 07-vues.md
└── 08-javascript.md
```

### **Étape 3 : Suivre l'Ordre des Fichiers**
1. **Migrations** (01) - Créer les tables
2. **Modèles** (02) - Créer/modifier les modèles
3. **Services** (03) - Créer les services
4. **Controllers** (04) - Créer les controllers
5. **Routes** (05) - Ajouter les routes
6. **Policies** (06) - Créer les policies
7. **Vues** (07) - Créer les vues ERB
8. **JavaScript** (08) - Créer le JavaScript

### **Étape 4 : Suivre les Checklists**
Chaque fichier contient une **checklist** à cocher au fur et à mesure.

### **Étape 5 : Tester**
Tester le thème complètement avant de passer au suivant.

---

## 🔄 Workflow Recommandé

### **Option A : Par Phase (Recommandé)**
```
Semaine 1-2 : Boutique + Commandes (dépendances)
Semaine 1   : Dashboard (améliorations progressives)
Semaine 5   : Initiations
Semaine 6   : Utilisateurs
Semaine 6+  : Événements
Semaine 7+  : Communication + Système
```

### **Option B : Par Priorité (Flexible)**
```
1. Boutique (base)
2. Commandes (dépend de Boutique)
3. Dashboard (améliorations)
4. Puis n'importe quel autre thème indépendant
```

### **Option C : Par Besoin Métier (Agile)**
```
Implémenter selon les besoins urgents du moment
(mais respecter les dépendances critiques)
```

---

## 🎯 Exemple : Implémenter "Boutique"

### **Jour 1 : Migrations**
- [ ] Lire `01-migrations.md`
- [ ] Créer les 4 migrations
- [ ] Exécuter `rails db:migrate`
- [ ] Vérifier schema.rb

### **Jour 2-3 : Modèles**
- [ ] Lire `02-modeles.md`
- [ ] Créer Inventory, InventoryMovement
- [ ] Modifier ProductVariant, Product
- [ ] Tester en console Rails

### **Jour 4 : Services**
- [ ] Lire `03-services.md`
- [ ] Créer InventoryService
- [ ] Tester méthodes

### **Jour 5-6 : Controllers**
- [ ] Lire `04-controllers.md`
- [ ] Créer/modifier controllers
- [ ] Tester routes

### **Jour 7 : Routes & Policies**
- [ ] Lire `05-routes.md` et `06-policies.md`
- [ ] Ajouter routes
- [ ] Créer policies
- [ ] Tester autorisations

### **Jour 8-9 : Vues**
- [ ] Lire `07-vues.md`
- [ ] Créer toutes les vues
- [ ] Tester interface

### **Jour 10 : JavaScript**
- [ ] Lire `08-javascript.md`
- [ ] Créer controller Stimulus
- [ ] Tester interactivité

---

## ✅ Avantages de cette Structure

1. **Indépendance** : Chaque thème peut être développé séparément
2. **Clarté** : Code exact dans chaque fichier
3. **Checklist** : Suivi de progression clair
4. **Réutilisabilité** : Services et modèles réutilisables
5. **Testabilité** : Test par thème possible

---

## ✅ Conclusion

**OUI**, tu peux maintenant travailler sur chaque thème **indépendamment** :

1. ✅ Choisir un thème
2. ✅ Suivre les 8 fichiers dans l'ordre (01 → 08)
3. ✅ Cocher les checklists
4. ✅ Tester complètement
5. ✅ Passer au thème suivant

**Recommandation** : Commencer par **Boutique** (base) puis **Commandes** (dépend de Boutique), puis n'importe quel autre thème selon tes priorités.

---

## 🔗 Liens Rapides

- [Dashboard - README](./00-dashboard/README.md)
- [Boutique - README](./01-boutique/README.md)
- [Commandes - README](./02-commandes/README.md)
- [Initiations - README](./03-initiations/README.md)
- [Événements - README](./04-evenements/README.md)
- [Utilisateurs - README](./06-utilisateurs/README.md)
- [Communication - README](./07-communication/README.md)
- [Système - README](./08-systeme/README.md)
- [**Permissions par Grade**](./PERMISSIONS.md) - 🔐 Documentation complète des permissions
- [**Liquid Glass Harmonisation**](./LIQUID-GLASS-HARMONISATION.md) - 🎨 Guide d'harmonisation design
- [**CHANGELOG**](./CHANGELOG.md) - 📝 Historique des modifications

---

## 🧪 Tests RSpec

**Status** : ✅ Tests complets pour AdminPanel

**Couverture** :
- ✅ Policies (BasePolicy, InitiationPolicy, OrderPolicy, ProductPolicy, RollerStockPolicy, UserPolicy, RolePolicy, MembershipPolicy, PaymentPolicy)
- ✅ Controllers (BaseController, InitiationsController, DashboardController, OrdersController, UsersController, RolesController, MembershipsController, PaymentsController, RoutesController, AttendancesController, OrganizerApplicationsController)
- ✅ Permissions par grade (30, 40, 60, 70)
- ✅ Tests Utilisateurs ✅ **CRÉÉS** (3 policies + 3 controllers)
- ✅ Tests Événements ✅ **CRÉÉS** (Routes, Attendances, OrganizerApplications - 56 exemples)
- ✅ Tests Système ✅ **CRÉÉS** (Payments - 20 exemples)
- ✅ 244+ exemples (109 Initiations + 56 Événements + 22 Payments + 36 Communication + 21 Events)

**Exécution** :
```bash
# Dans Docker (recommandé)
docker compose -f ops/dev/docker-compose.yml run --rm \
  -e BUNDLE_PATH=/rails/vendor/bundle \
  -e DATABASE_URL=postgresql://postgres:postgres@db:5432/app_test \
  -e RAILS_ENV=test \
  web bundle exec rspec spec/policies/admin_panel spec/requests/admin_panel \
  --format progress --order defined
```

**Documentation** :
- Configuration générale : [`spec/README.md`](../../../spec/README.md) - Configuration DatabaseCleaner, bonnes pratiques, debugging
- Tests AdminPanel : [`spec/requests/admin_panel/README.md`](../../../spec/requests/admin_panel/README.md) - Structure des tests, permissions, exécution

---

**Créé le** : 2025-12-21 | **Version** : 2.5 | **Dernière mise à jour** : 2025-01-13
