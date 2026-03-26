# Documentation du projet (Rails)

Ce dossier structure la **documentation vivante** du monolithe Ruby on Rails. Elle suit Shape Up et les bonnes pratiques d’un projet collaboratif (4 devs).

## Sommaire
- 00-overview: vision, périmètre, glossaire, parties prenantes - **Voir [`00-overview/README.md`](00-overview/README.md)**
- 01-ways-of-working: règles d'équipe (branches, PRs, revues, commits, rituels) - **Voir [`01-ways-of-working/README.md`](01-ways-of-working/README.md)**
- 02-shape-up: cycles Shape Up (shaping, betting, building, cooldown) - **Voir [`02-shape-up/README.md`](02-shape-up/README.md)**
- 03-architecture: vues C4, domaine, NFRs, ADRs
- 04-rails: conventions, structure app, setup, sécurité, perf, API
- 05-testing: stratégie de tests, RSpec, données de test, de bout en bout
- 06-events: gestion des événements et initiations (waitlist, essai gratuit, stock rollers) - **Voir [`06-events/README.md`](06-events/README.md)**
- 06-infrastructure: déploiement, CI/CD, observabilité
- 07-ops: runbooks (setup local, backup/restore, incidents)
- 08-security-privacy: modèle de menace, checklist Rails, secrets, RGPD, accessibilité - **Voir [`08-security-privacy/README.md`](08-security-privacy/README.md)**
- 09-product: personas, parcours, critères d'acceptation, wireframes - **Voir [`09-product/README.md`](09-product/README.md)**
- 10-decisions-and-changelog: décisions et changelog
- 11-templates: gabarits (ADR, PR, issues, architectures)
- development: fonctionnalités en développement, plans, audits - **Voir [`development/README.md`](development/README.md)**

## Contribuer à la doc
1. Créer/éditer dans la section adéquate (voir sommaire).
2. Petits PRs, titres clairs, utilisez les templates (`11-templates`).
3. Référencer les ADRs pour toute décision structurante (voir `03-architecture/adr`).
4. Lier depuis `README.md` principal si un document devient critique.

## Conventions (2025 Standards)

### File Naming
- **kebab-case** only (no uppercase, no underscores)
- **English** for technical files, French for product if needed
- **Descriptive names** : `cycle-01-building-log.md` not `current-cycle.md`

### Document Structure
- **Frontmatter YAML** required for all documents:
  ```yaml
  ---
  title: "Document Title"
  status: "active|completed|deprecated"
  version: "1.0"
  created: "YYYY-MM-DD"
  updated: "YYYY-MM-DD"
  authors: ["Author Name"]
  tags: ["tag1", "tag2"]
  ---
  ```

### Shape Up Cycles
- Cycles: `cycle-01`, `cycle-02`, … in `02-shape-up/building/`
- Format: `cycle-XX-building-log.md` or `cycle-XX-phase-Y-plan.md`

### Decision Records
- **ADRs** (Architecture): `ADR-XXX-short-title.md` (see template in `11-templates/`)
- **DRs** (Product/UX): `DR-XXX-short-title.md` (see template in `11-templates/`)
- Sequential numbering, one decision per file

### Documentation Lifecycle
- No obsolete docs: update or delete outdated documents
- Version tracking via frontmatter
- Status tracking: `active`, `completed`, `deprecated`, `superseded`

## Flux recommandé (nouveau dev)
1. Lire le `README.md` principal du projet pour une vue d'ensemble.
2. Suivre `04-rails/setup/local-development.md` pour configurer l'environnement local avec Docker.
3. Consulter `03-architecture/domain/models.md` pour comprendre la structure des données.
4. Lire `04-rails/setup/credentials.md` pour la gestion des secrets.
5. Lire `01-ways-of-working/` (branches, PR, revue).
6. Consulter `05-testing/strategy.md` pour les tests.

## Déploiement
- **Développement** : `04-rails/setup/local-development.md` ou `07-ops/runbooks/local-setup.md`
- **Staging** : `07-ops/runbooks/staging-setup.md`
- **Production** : `07-ops/runbooks/production-setup.md`, `07-ops/deploy-vps.md`
- **Dokploy (staging / prod, doc vivante)** : `07-ops/runbooks/dokploy-setup.md`

## Qualité & sécurité
- Qualité: RuboCop Rails Omakase, Brakeman.
- Tests: RSpec configuré (dossier `spec/`), Minitest disponible (dossier `test/`).
- Secrets: `04-rails/setup/credentials.md` + rotation régulière.
- Performances: traquer N+1, cache, jobs idempotents.

## Documentation actuelle (État du projet - Nov 2025)

### Versions
- **Ruby** : 3.4.2
- **Rails** : 8.1.1
- **PostgreSQL** : 16
- **Bootstrap** : 5.3.2
- **Bootstrap Icons** : 1.11.1

### Setup & Configuration
- ✅ `04-rails/setup/local-development.md` - Guide de setup avec Docker (dev)
- ✅ `04-rails/setup/credentials.md` - Gestion des credentials Rails
- ✅ `04-rails/setup/email-confirmation.md` - Confirmation email (sécurité, QR code, SMTP)
- ✅ `04-rails/setup/emails-recapitulatif.md` - Récapitulatif complet de tous les emails
- ✅ `07-ops/runbooks/staging-setup.md` - Guide d'installation staging
- ✅ `07-ops/runbooks/production-setup.md` - Guide d'installation production
- 🔄 `07-ops/runbooks/dokploy-setup.md` - Déploiement Dokploy (doc vivante, décisions & questions)

### Architecture
- ✅ `03-architecture/domain/models.md` - Modèles de domaine (Phase 1 + Phase 2)
- ✅ `03-architecture/system-overview.md` - Vue d'ensemble système (C4 niveau Contexte)

### Operations
- ✅ `07-ops/runbooks/local-setup.md` - Runbook setup local

### Rails
- ✅ `04-rails/routes.md` - Routes et flux principaux (incluant pages légales et cookies)
- ✅ `04-rails/conventions/README.md` - Conventions Rails du projet
- ✅ `04-rails/admin-panel-research.md` - Recherche et recommandations pour le panel admin (Phase 2)
- ✅ `04-rails/admin-panel/` - Documentation complète du panel admin (100% implémenté, migré depuis ActiveAdmin)
- ✅ `04-rails/background-jobs/` - Documentation complète des jobs récurrents (Solid Queue, migration terminée)
- ✅ `02-shape-up/building/phase2-migrations-models.md` - Documentation Phase 2 (migrations et modèles) ✅ **TERMINÉ**
- ✅ `04-rails/setup/README.md` - Index de la documentation setup Rails
- ✅ `04-rails/pwa/` - Étude PWA (Progressive Web App) conformité 2026, modifications à prévoir, impact déploiement (Kamal vs scripts)

### Événements & Initiations
- ✅ `06-events/README.md` - Documentation complète gestion événements
- ✅ `06-events/logique-essai-gratuit.md` - Logique d'essai gratuit v3.0 (règles métier, validations, cas limites)

### Développement en Cours
- ✅ `development/README.md` - Documentation des fonctionnalités en développement (actuellement vide - toutes fonctionnalités terminées)
- ✅ `09-product/ux-improvements-backlog.md` - Référence historique des améliorations UX (fonctionnalités essentielles terminées)
- ✅ `09-product/quick-wins-helloasso.md` - Intégration HelloAsso (100% intégré)
- ✅ `09-product/todo-restant.md` - Récapitulatif des fonctionnalités essentielles terminées
- ✅ `02-shape-up/building/cycle-01-phase-2-plan.md` - Plan Phase 2 (Events & Admin) ✅ **COMPLETED**
- ✅ `02-shape-up/building/phase2-migrations-models.md` - Migrations et modèles Phase 2 ✅ **TERMINÉ**
- ✅ `04-rails/mailing/` - Documentation complète système de mailing (18 emails, jobs récurrents, configuration)

### Admin Panel (Complété)
- ✅ `04-rails/admin-panel/` - Documentation complète du panel admin (100% implémenté, migré depuis ActiveAdmin)

### Tests
- ✅ `05-testing/strategy.md` - Stratégie de tests (RSpec configuré)
- ✅ **166 exemples, 0 échec** (135 models + 12 policies + 19 requests)
- ✅ FactoryBot factories pour tous les modèles
- ✅ Tests complets pour counter cache et max_participants

### Changelog
- ✅ `10-decisions-and-changelog/CHANGELOG.md` - Changelog des modifications significatives

### Sécurité & Conformité
- ✅ `08-security-privacy/README.md` - Documentation accessibilité, performance, pages légales
- ✅ `08-security-privacy/legal-pages-guide.md` - Guide complet pages légales (mis à jour 2025-11-17)
- ✅ `08-security-privacy/informations-a-collecter.md` - Formulaire complété (2025-11-17)
- ✅ `08-security-privacy/conformite-2025-checklist.md` - Checklist conformité 2025 (WCAG 2.2, NIST, RGPD)
- ✅ **Pages légales créées** : Mentions Légales, RGPD, CGV, CGU, Contact (2025-11-21)
- ✅ **Gestion des cookies** : Système conforme RGPD 2025 avec Stimulus (2025-11-21)
- ✅ **Quick Wins Devise** : Formulaire inscription simplifié, confirmation email, profil complet avec changement mot de passe intégré (2025-11-24)
- ✅ **Confirmation Email Complète** : Sécurité renforcée, QR code mobile, audit trail, rate limiting (2025-12-07)

### Overview & Vision
- ✅ `00-overview/README.md` - Overview complet du projet (vision, architecture, statut)
- ✅ `00-overview/features-status.md` - État des fonctionnalités (implémentées, partiels, non implémentées)

### Ways of Working
- ✅ `01-ways-of-working/README.md` - Workflow Git, PR, conventions équipe

### À compléter
- `10-decisions-and-changelog/` - ADRs à créer pour décisions structurantes

## Mise à jour continue
- À chaque PR significative: mettre à jour la section concernée.
- À chaque décision: créer/mettre à jour un ADR.
- À chaque cycle: renseigner `02-shape-up/building/cycle-XX-build-log.md` puis `cooldown`.
