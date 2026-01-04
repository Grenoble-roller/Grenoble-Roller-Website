# 📚 Documentation - Développement en Cours

**Section** : Documentation des fonctionnalités en cours de développement, plans d'implémentation, audits et améliorations à venir.

---

## 📋 Vue d'Ensemble

Cette section contient toute la documentation liée aux **fonctionnalités en développement**, aux **plans d'implémentation**, aux **audits nécessitant des actions**, et aux **améliorations planifiées**.

**Principe** : Les fichiers sont organisés par **domaine fonctionnel** pour faciliter la navigation et la maintenance.

---

## 📁 Structure par Domaine

### 📧 Mailing & Notifications
**Dossier** : [`../04-rails/mailing/`](../04-rails/mailing/)

Documentation complète du système de mailing automatique :
- Mailers et leurs méthodes
- Jobs automatiques (rappels, renouvellements)
- Préférences utilisateur
- Configuration SMTP
- Tests et sécurité

**📖 Documentation principale** : [`docs/04-rails/mailing/README.md`](../04-rails/mailing/README.md)

**Fichiers troubleshooting** :
- `docs/04-rails/mailing/troubleshooting/waitlist-email-issue.md` - Diagnostic problèmes emails waitlist
- `docs/04-rails/mailing/troubleshooting/solid-queue-deployment-fix.md` - Corrections déploiement Solid Queue

---

### 🎨 UX & Améliorations
**Dossier** : [`ux-improvements/`](ux-improvements/)

Backlog d'améliorations UX et plans d'action :
- Analyses de parcours utilisateur
- Quick wins identifiés
- Améliorations prioritaires

**Fichiers** :
- `ux-improvements-backlog.md` - Backlog complet (119 améliorations identifiées)
- `todo-restant.md` - Récapitulatif des tâches restantes
- `quick-wins-helloasso.md` - Quick wins et intégration HelloAsso

---

---

### ♿ Accessibilité
**Dossier** : [`accessibility/`](accessibility/)

Audits et plans d'action pour l'accessibilité :
- Audits d'accessibilité
- Plans d'action Lighthouse
- Guides de test

**Fichiers** :
- `accessibility-audit.md` - Audit complet d'accessibilité
- `lighthouse-action-plan.md` - Plan d'action Lighthouse
- `a11y-testing.md` - Guide de test d'accessibilité

---

### 🚀 Phase 2
**Dossier** : [`phase2/`](phase2/)

Documentation des fonctionnalités Phase 2 (non encore implémentées) :
- Plans de développement
- Migrations et modèles prévus

**Fichiers** :
- `cycle-01-phase-2-plan.md` - Plan Phase 2 (Events & Admin)
- `phase2-migrations-models.md` - Migrations et modèles Phase 2

---

### 🧪 Testing
**Dossier** : [`testing/`](testing/)

Documentation des tests en cours ou à améliorer :
- Roadmaps de tests
- Todolists de corrections

**Fichiers** :
- `ROADMAP.md` - Roadmap des tests RSpec
- `TODOLIST.md` - Todolist des corrections de tests

---

### 🏗️ Infrastructure
**Dossier** : [`infrastructure/`](infrastructure/)

Documentation infrastructure en développement (pour l'instant vide, prêt pour futurs fichiers).

---

### 📦 Mises à jour de Dépendances
**Fichier** : [`../dependencies-update-analysis.md`](../dependencies-update-analysis.md)

Analyse et suivi des mises à jour de dépendances Dependabot :

**✅ Phase 1 TERMINÉE** (5 gems mises à jour) :
- `aws-sdk-s3`, `bootsnap`, `debug`, `thruster`, `selenium-webdriver`

**⚠️ Phase 2 EN ATTENTE** (3 dépendances nécessitant tests) :
- `kamal` : 2.9.0 → 2.10.1 (tester déploiement staging)
- `actions/checkout` : v4 → v6 (tester CI)
- `actions/upload-artifact` : v4 → v6 (tester CI)

**🚨 Phase 3 EN ATTENTE** (migration majeure) :
- `pagy` : 8.6.3 → 43.2.2 (saut de version majeur, migration nécessaire)

**📖 Documentation complète** : [`docs/dependencies-update-analysis.md`](../dependencies-update-analysis.md)

---

## 🔄 Cycle de Vie des Documents

### Quand un document entre dans `development/` ?
- ✅ Fonctionnalité **en cours de développement** (WIP, EN COURS)
- ✅ Plan d'implémentation **non terminé**
- ✅ Audit avec **actions à réaliser**
- ✅ Backlog d'améliorations **non implémentées**
- ✅ Spécifications **non finalisées**

### Quand un document sort de `development/` ?
- ✅ Fonctionnalité **terminée et validée** → Déplacer vers section appropriée
- ✅ Plan **complètement implémenté** → Archiver ou déplacer vers section complétée
- ✅ Audit **toutes actions réalisées** → Déplacer vers section appropriée

**Exemples de déplacements récents** :
- ✅ `admin-panel/` → `04-rails/admin-panel/` (100% complété)
- ✅ `cron/` → `04-rails/background-jobs/` (Solid Queue actif, migration terminée)

---

## 📝 Conventions

### Nommage
- **kebab-case** uniquement
- **Descriptif** : Utiliser des noms descriptifs (ex: `ux-improvements-backlog.md` pas `backlog.md`)

### Frontmatter
Tous les documents doivent avoir un frontmatter YAML :
```yaml
---
title: "Document Title"
status: "wip|planned|in-review|blocked"
version: "1.0"
created: "YYYY-MM-DD"
updated: "YYYY-MM-DD"
authors: ["Author Name"]
tags: ["tag1", "tag2"]
---
```

### Statuts possibles
- `wip` : En cours de développement actif
- `planned` : Planifié mais pas encore commencé
- `in-review` : En cours de revue/validation
- `blocked` : Bloqué (dépendance externe, décision en attente)
- `deprecated` : Déprécié, ne plus utiliser

---

## 🔗 Liens Utils

- **Documentation principale** : [`../README.md`](../README.md)
- **Shape Up** : [`../02-shape-up/`](../02-shape-up/)
- **Architecture** : [`../03-architecture/`](../03-architecture/)
- **Product** : [`../09-product/`](../09-product/)

---

## 📊 Éléments Restants à Faire

**Dernière mise à jour** : 2025-01-30

### 📈 Vue d'Ensemble

- **🔴 Priorité Haute** : 5 tâches critiques (tests préprod, fonctionnalités urgentes) - Dépendances terminées ✅
- **🟡 Priorité Moyenne** : ~60 tâches (UX importantes, accessibilité, SEO)
- **🟢 Priorité Basse** : ~52 tâches (newsletter reportée, améliorations futures, optimisations)

---

### 🔴 Priorité Haute (5 tâches)

#### 1. Mises à jour de Dépendances ✅ **TERMINÉES**

**✅ Toutes les mises à jour de dépendances sont terminées !**

**✅ Phase 2 TERMINÉE** (3 dépendances) :
- ✅ `kamal` : 2.9.0 → 2.10.1
- ✅ `actions/checkout` : v4 → v6
- ✅ `actions/upload-artifact` : v4 → v6
- **📖 Détails** : [`../dependencies-update-analysis.md`](../dependencies-update-analysis.md)

**✅ Phase 3 TERMINÉE** (1 dépendance) :
- ✅ `pagy` : 8.6.3 → 43.2.2
- **⚠️ Note** : Configuration adaptée (Pagy.options au lieu de Pagy::DEFAULT, extras chargés automatiquement)
- **⚠️ Breaking changes corrigés** :
  - ✅ `Pagy::Frontend` n'existe plus → Helpers personnalisés créés dans `ApplicationHelper`
  - ✅ `Pagy::Backend` n'existe plus → Méthode `pagy()` créée dans `ApplicationController`
  - ✅ Retiré tous les `include Pagy::Backend` des contrôleurs (11 fichiers)
  - ✅ Correction `Pagy.new` → `Pagy::Offset.new(**vars)` avec `limit` au lieu de `items` (2025-01-30)
- **📖 Détails** : [`../dependencies-update-analysis.md`](../dependencies-update-analysis.md)

#### 2. Tests Préproduction

**Tests Capybara** ✅ **TERMINÉS** - Tous les tests passent (57 exemples, 0 échec) :
- [x] Corriger helper Pagy 43 (Pagy::Frontend n'existe plus) ✅
- [x] Réactiver les tests skipés (5 tests : xit → it) ✅
- [x] Corriger tests non-JS (test "Voir plus" corrigé) ✅
- [x] Ajouter Chrome dans Dockerfile.dev pour tests JS ✅
- [x] Reconstruire conteneur Docker avec Chrome ✅
- [x] Corriger les tests JavaScript (modals, formulaires, confirmations) ✅
- [x] Valider les parcours utilisateur complets (inscription/désinscription) ✅
- **📖 Détails** : [`phase2/cycle-01-phase-2-plan.md`](phase2/cycle-01-phase-2-plan.md) (section "📅 PRÉPROD - AVANT PRODUCTION")

#### 3. Fonctionnalités Urgentes

**Parcours 2 : Inscription** : ✅ TERMINÉ
- [x] Validation email en temps réel (Vérifier si email existe déjà via AJAX) ✅
  - **✅ Implémenté** : Endpoint AJAX `/users/check_email` avec validation en temps réel pendant la saisie (debounce 500ms)
- [x] Page de bienvenue après inscription (Redirection vers `/welcome` avec guide "Prochaines étapes") ✅
  - **✅ Implémenté** : Page `/welcome` avec guide des prochaines étapes (confirmation email, adhésion, événements), textes harmonisés avec le ton de l'association
- **📖 Détails** : [`ux-improvements/todo-restant.md`](ux-improvements/todo-restant.md)

**Parcours 3 : Découverte des Événements** : ✅ TERMINÉ
- [x] Filtres basiques (Filtres par route, niveau) ✅
  - **✅ Implémenté** : Filtres par route et niveau avec formulaire en haut de page (2025-01-30)
- [x] Pagination et affichage optimisé ✅
  - **✅ Implémenté** : 
    - Événements à venir : 6 minicards (sans pagination) pour mise en avant visuelle
    - Événements passés : Tableau compact avec pagination (10 par page) pour consultation historique (2025-01-30)
- **📖 Détails** : [`ux-improvements/todo-restant.md`](ux-improvements/todo-restant.md)

**Parcours 5 : Gestion de Mes Inscriptions** : ✅ TERMINÉ
- [x] Filtres basiques (Filtres par statut rappel) ✅
  - **✅ Implémenté** : Filtre par statut de rappel (activé/désactivé) avec formulaire (2025-01-30)
- [x] Pagination ✅
  - **✅ Implémenté** : Pagination séparée pour événements à venir et passés (12 par page) avec `pagy_array` (2025-01-30)
- **📖 Détails** : [`ux-improvements/todo-restant.md`](ux-improvements/todo-restant.md)

**✅ Déjà fait** :
- ✅ Masquer sections non implémentées footer (Équipe, Carrières, Blog masquées avec `if false`)

---

### 🟡 Priorité Moyenne (~60 tâches)

#### 4. Accessibilité

**Admin (ActiveAdmin)** :
- [ ] Tableaux : Vérifier headers associés aux cellules
- [ ] Formulaires : Vérifier accessibilité formulaires admin
- [ ] Navigation : Vérifier navigation clavier dans sidebar
- **📖 Détails** : [`accessibility/accessibility-audit.md`](accessibility/accessibility-audit.md) (section "Admin (ActiveAdmin)")

**Lighthouse - SEO** :
- [ ] Meta description spécifique par page (Association, Événements liste, Événement détail, Boutique, Produit détail)
- [ ] Vérifier hiérarchie headings (Association, Événements liste, Événement détail, Boutique)
- **📖 Détails** : [`accessibility/lighthouse-action-plan.md`](accessibility/lighthouse-action-plan.md)

#### 5. Améliorations UX Importantes

**Note** : Les améliorations futures ont été réévaluées et retirées de la roadmap. Seules les fonctionnalités essentielles déjà implémentées sont conservées.

**Parcours 2 : Inscription** : ✅ TERMINÉ
- ✅ Validation email en temps réel
- ✅ Page de bienvenue après inscription

**Parcours 3 : Découverte des Événements** : ✅ TERMINÉ
- ✅ Filtres basiques (route, niveau)
- ✅ Pagination et affichage optimisé

**Parcours 5 : Gestion de Mes Inscriptions** : ✅ TERMINÉ
- ✅ Filtres basiques (statut rappel)
- ✅ Pagination séparée pour événements à venir et passés

---

### 🟢 Priorité Basse (~50 tâches)

#### 6. Quick Wins Restants (8 tâches)

**Parcours 7 : Achat en Boutique** :
- [ ] Barre de recherche produits (AJAX) - **DÉPRIORISÉ** (peu de produits ~6-7)

**📖 Détails** : [`ux-improvements/todo-restant.md`](ux-improvements/todo-restant.md) (section "🟢 QUICK WINS RESTANTS")

#### 7. Newsletter (Reportée)

**Parcours 1 : Découverte de l'Association** :
- [ ] Newsletter fonctionnelle (Formulaire footer + backend avec service email)
  - **⚠️ Statut** : Reportée pour l'instant (section déjà masquée dans footer avec `if false`)
  - **📖 Détails** : [`ux-improvements/todo-restant.md`](ux-improvements/todo-restant.md)

#### 8. Améliorations Futures (~33 tâches)

**Parcours 1-9** : Témoignages membres, galerie photos, carte interactive, inscription réseaux sociaux, suggestions personnalisées, inscription groupée, liste d'attente, QR codes, statistiques personnelles, éditeur WYSIWYG, planification récurrente, comparaison produits, liste de souhaits, avis clients, codes promo, etc.

**📖 Détails complets** : [`ux-improvements/todo-restant.md`](ux-improvements/todo-restant.md) (section "🔴 AMÉLIORATIONS FUTURES")

#### 9. Optimisations Performance (Fin du Dev)

**Lighthouse - Optimisations** :
- [ ] Optimisation images (WebP, compression)
- [ ] Purge CSS inutilisé
- [ ] Optimisation JavaScript (tree shaking, code splitting)
- [ ] Lazy loading images
- [ ] Configuration sécurité production (HTTPS, CSP headers, HSTS, COOP, Trusted Types)

**📖 Détails** : [`accessibility/lighthouse-action-plan.md`](accessibility/lighthouse-action-plan.md) (section "⏳ À Faire Plus Tard")

#### 10. Tests (Améliorations)

**Roadmap et Corrections** :
- [ ] Voir roadmap dans `testing/ROADMAP.md`
- [ ] Voir todolist dans `testing/TODOLIST.md` (si fichier existe)

**📖 Détails** : [`testing/ROADMAP.md`](testing/ROADMAP.md)

#### 11. Phase 2 (Fonctionnalités Futures)

**Plans et Migrations** :
- [ ] Voir plans dans `phase2/cycle-01-phase-2-plan.md`
- [ ] Voir migrations dans `phase2/phase2-migrations-models.md`

**📖 Détails** : [`phase2/cycle-01-phase-2-plan.md`](phase2/cycle-01-phase-2-plan.md)

---

## 📊 Statistiques Globales

- **🔴 Priorité Haute** : Dépendances terminées ✅
- **🟡 Priorité Moyenne** : Accessibilité et optimisations
- **🟢 Priorité Basse** : Optimisations performance (fin dev)

**Répartition par domaine** :
- **Dépendances** : Phase 2 + Phase 3 terminées ✅
- **Tests** : Capybara préprod terminés ✅
- **UX** : Fonctionnalités essentielles implémentées ✅
- **Accessibilité** : Améliorations en cours
- **Performance** : Optimisations fin dev

---

## 🔧 Corrections Récentes (2025-01-30)

### Corrections Pagy 43
- ✅ **Correction `Pagy::Backend`** : Créé méthode `pagy()` dans `ApplicationController` (remplace le module qui n'existe plus dans Pagy 43)
- ✅ Retiré tous les `include Pagy::Backend` des contrôleurs admin (11 fichiers dans `app/controllers/admin_panel/`)
- ✅ Helpers frontend déjà corrigés précédemment (`Pagy::Frontend` → helpers personnalisés dans `ApplicationHelper`)
- ✅ **Correction `Pagy.new`** : Correction de l'erreur `ArgumentError` - utilisation de `Pagy::Offset.new(**vars)` au lieu de `Pagy.new(vars)` dans les méthodes `pagy()` et `pagy_array()` (2025-01-30)
- ✅ **Correction `items` → `limit`** : Remplacement de toutes les références à `items` par `limit` dans les instances `Pagy::Offset` (API Pagy 43)

### Corrections UX
- ✅ **Navbar** : Boutons "Se connecter" et "S'inscrire" côte à côte sur desktop, empilés sur mobile uniquement
- ✅ **Messages de bienvenue** : Messages personnalisés après connexion/inscription/confirmation email avec prénom de l'utilisateur
- ✅ **Validation email en temps réel** : Vérification AJAX de la disponibilité de l'email pendant la saisie dans le formulaire d'inscription (endpoint `/users/check_email`, debounce 500ms) (2025-01-30)
- ✅ **Page de bienvenue** : Page `/welcome` avec guide "Prochaines étapes" après inscription (confirmation email, adhésion, événements) (2025-01-30)
- ✅ **Textes page welcome** : Textes harmonisés avec le ton de l'association (communauté, randonnées urbaines, convivialité) (2025-01-30)
- ✅ **Filtres événements** : Filtres par route et niveau avec formulaire en haut de page (2025-01-30)
- ✅ **Affichage optimisé événements** : 6 minicards pour événements à venir, tableau paginé (10/page) pour événements passés (2025-01-30)
- ✅ **Filtres "Mes sorties"** : Filtre par statut de rappel (activé/désactivé) avec formulaire (2025-01-30)
- ✅ **Pagination "Mes sorties"** : Pagination séparée pour événements à venir et passés (12 par page) avec `pagy_array` (2025-01-30)
- ✅ **Redirection** : Utilisateurs déjà connectés visitant `/users/sign_in` redirigés vers l'accueil avec message de bienvenue

---

**Dernière mise à jour** : 2025-01-30 (Correction bug Pagy + Filtres et pagination "Mes sorties")
