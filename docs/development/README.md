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

**Parcours 2 : Inscription** :
- [ ] Validation email en temps réel (Vérifier si email existe déjà via AJAX)
  - **⚠️ État actuel** : Validation format email côté client existe, mais PAS de vérification AJAX si email déjà utilisé
- [ ] Page de bienvenue après inscription (Redirection vers `/welcome` avec guide "Prochaines étapes")
  - **⚠️ État actuel** : Email de bienvenue envoyé (`UserMailer.welcome_email`), mais PAS de page `/welcome` avec redirection
- **📖 Détails** : [`ux-improvements/todo-restant.md`](ux-improvements/todo-restant.md)

**Parcours 3 : Découverte des Événements** :
- [ ] Barre de recherche (Recherche par titre, description, lieu - AJAX)
  - **⚠️ État actuel** : Pas de recherche implémentée dans `EventsController`
- [ ] Filtres basiques (Filtres par date, route, niveau)
  - **⚠️ État actuel** : Pas de filtres utilisateur, seulement scopes upcoming/past
- [ ] Pagination (Pagination avec Kaminari/Pagy - 10-15 événements par page)
  - **⚠️ État actuel** : Pagy utilisé dans admin panel, mais PAS dans contrôleur public. Événements passés limités à 6 avec bouton "Voir tout"
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

#### 5. Améliorations UX Importantes (~48 tâches)

**Parcours 1 : Découverte de l'Association** :
- [ ] Section "Derniers événements" (Carrousel ou grille avec 3-4 derniers événements passés)
- [ ] Section "Tarifs d'adhésion" (Tableau simple avec 3 tarifs + CTA)
- [ ] Page "Équipe" (Créer page statique manquante)

**Parcours 2 : Inscription** : ✅ TERMINÉ
- [ ] Indicateur de progression du formulaire (Barre "Étape 1/1" pour préparer futures étapes) - Priorité basse

**Parcours 3 : Découverte des Événements** :
- [ ] Tri personnalisé (Dropdown "Trier par" : Date, Popularité, Distance, Nouveautés)
- [ ] Vue calendrier (Toggle vue liste/calendrier avec FullCalendar - vue mensuelle)
- [ ] Filtres avancés (Filtres combinés avec tags actifs visibles)

**Parcours 4 : Inscription à un Événement** :
- [ ] Prévisualisation email (Aperçu de l'email de confirmation dans la modal)
- [ ] Confirmation en deux étapes (Étape 1 modal → Étape 2 page de confirmation)
- [ ] Notification push (optionnel) (Demander permission pour notifications push)

**Parcours 5 : Gestion de Mes Inscriptions** :
- [ ] Filtres basiques (Filtres par date, statut rappel)
- [ ] Pagination (Pagination avec Kaminari/Pagy - 10-15 événements par page)
- [ ] Vue calendrier (Toggle vue liste/calendrier avec FullCalendar)
- [ ] Actions en masse (Checkbox pour sélectionner plusieurs événements et désinscription en masse)
- [ ] Tri personnalisé (Dropdown "Trier par" : Date, Nom, Distance)
- [ ] Export calendrier global (Export iCal de toutes ses inscriptions en une fois)

**Parcours 6 : Création d'un Événement** :
- [ ] Formulaire en plusieurs étapes (Étape 1 Infos de base → Étape 2 Détails → Étape 3 Options)
- [ ] Prévisualisation événement (Bouton "Aperçu" qui montre la card événement)
- [ ] Création route depuis formulaire (Modal "Créer un nouveau parcours" directement)
- [ ] Duplication d'événement (Bouton "Dupliquer" sur événement existant)
- [ ] Templates d'événements (Templates pré-remplis : "Rando vendredi soir", etc.)
- [ ] Validation côté client (Validation HTML5 + JavaScript avant soumission)

**Parcours 7 : Achat en Boutique** :
- [ ] Zoom sur image produit (Lightbox pour agrandir l'image au clic) - **PRIORITÉ MOYENNE**
- [ ] Tri des produits (Dropdown "Trier par" : Prix, Nom, Popularité)
- [ ] Galerie d'images (Carrousel avec plusieurs images par produit)
- [ ] Panier persistant pour utilisateurs connectés (Sauvegarder panier en DB, fusionner avec session)
- [ ] Sauvegarde panier avant déconnexion (Sauvegarder automatiquement le panier en DB)
- [ ] Récapitulatif avant paiement (Page intermédiaire "Récapitulatif" avec adresse de livraison)
- [ ] Suggestions produits ("Produits similaires" ou "Autres clients ont aussi acheté")

**Parcours 8 : Administration** :
- [ ] Bulk actions (Sélectionner plusieurs événements → "Publier en masse", "Refuser en masse")
- [ ] Recherche globale (Barre de recherche qui cherche dans Events, Users, Orders)
- [ ] Regroupement menu (Menu groupé : "Événements" → Events, Routes, Attendances)
- [ ] Exports avancés (Exports CSV personnalisés avec colonnes choisies, exports PDF)
- [ ] Filtres sauvegardés (Permettre de sauvegarder des filtres fréquents)
- [ ] Dashboard complet avec graphiques (Graphiques : événements par mois, inscriptions, revenus)

**Parcours 9 : Navigation via Footer** :
- [ ] Page "Équipe" (Créer page statique manquante)
- [ ] Page "Carrières" (Si recrutement prévu : offres d'emploi)
- [ ] Page "Blog" (Si blog prévu, créer structure de base ou masquer le lien)
- [ ] Créer pages statiques essentielles (FAQ, Contact avec formulaire, CGU, Confidentialité)

**📖 Détails complets** : [`ux-improvements/todo-restant.md`](ux-improvements/todo-restant.md) et [`ux-improvements/ux-improvements-backlog.md`](ux-improvements/ux-improvements-backlog.md)

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

- **Total tâches identifiées** : ~122 tâches
- **🔴 Priorité Haute** : 5 tâches (4%) - Dépendances terminées ✅
- **🟡 Priorité Moyenne** : ~60 tâches (49%)
- **🟢 Priorité Basse** : ~52 tâches (43%)

**Répartition par domaine** :
- **Dépendances** : 4 tâches (Phase 2 + Phase 3)
- **Tests** : 5 tâches (Capybara préprod)
- **UX** : ~89 tâches (Quick wins + Importantes + Futures)
- **Accessibilité** : 7 tâches (Admin + Lighthouse SEO)
- **Performance** : 5 tâches (Optimisations fin dev)
- **Phase 2** : Plans et migrations (non quantifiés)

---

## 🔧 Corrections Récentes (2025-01-30)

### Corrections Pagy 43
- ✅ **Correction `Pagy::Backend`** : Créé méthode `pagy()` dans `ApplicationController` (remplace le module qui n'existe plus dans Pagy 43)
- ✅ Retiré tous les `include Pagy::Backend` des contrôleurs admin (11 fichiers dans `app/controllers/admin_panel/`)
- ✅ Helpers frontend déjà corrigés précédemment (`Pagy::Frontend` → helpers personnalisés dans `ApplicationHelper`)

### Corrections UX
- ✅ **Navbar** : Boutons "Se connecter" et "S'inscrire" côte à côte sur desktop, empilés sur mobile uniquement
- ✅ **Messages de bienvenue** : Messages personnalisés après connexion/inscription/confirmation email avec prénom de l'utilisateur
- ✅ **Validation email en temps réel** : Vérification AJAX de la disponibilité de l'email pendant la saisie dans le formulaire d'inscription (2025-01-30)
- ✅ **Page de bienvenue** : Page `/welcome` avec guide "Prochaines étapes" après inscription (confirmation email, adhésion, événements) (2025-01-30)
- ✅ **Redirection** : Utilisateurs déjà connectés visitant `/users/sign_in` redirigés vers l'accueil avec message de bienvenue

---

**Dernière mise à jour** : 2025-01-30
