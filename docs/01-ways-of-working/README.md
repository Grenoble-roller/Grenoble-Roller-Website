---
title: "Ways of Working - Grenoble Roller"
status: "active"
version: "1.1"
created: "2025-01-30"
updated: "2026-08-14"
tags: ["workflow", "git", "pr", "conventions", "team"]
---

# Ways of Working - Grenoble Roller

**Dernière mise à jour** : 2026-08-14

Ce document définit les règles d'équipe, conventions Git, workflows PR, et pratiques de développement pour le projet Grenoble Roller.

---

## 🌿 Git Workflow

### Branches

#### Branches Principales
- **`main`** : Branche de production (stable, toujours déployable) — `grenoble-roller.org`
- **`staging`** : Branche de staging (test avant production, déployée via Dokploy)
- **`Dev`** : Branche d'intégration — les branches de fonctionnalité fusionnent ici en premier

#### Convention de Nommage des Branches
```
<type>/<description-kebab-case>

Types :
- feature/    : Nouvelle fonctionnalité
- fix/        : Correction de bug
- refactor/   : Refactoring (pas de changement fonctionnel)
- docs/       : Documentation uniquement
- test/       : Ajout/modification de tests
- chore/      : Tâches de maintenance (deps, config)
- ux/         : Améliorations UX (parcours, densité, pages)

Exemples :
- feature/add-pagination-events
- fix/cart-persistent-storage
- docs/update-deployment-guide
- refactor/extract-order-service
- ux/pages-verification
```

### Workflow Git Flow Simplifié

1. **Créer une branche** depuis `Dev` (branche d'intégration)
   ```bash
   git checkout Dev
   git pull origin Dev
   git checkout -b feature/my-feature
   ```

2. **Développer et commiter** régulièrement
   ```bash
   git add .
   git commit -m "feat: add pagination to events list"
   ```

3. **Pusher** et créer une Pull Request
   ```bash
   git push origin feature/my-feature
   ```

4. **Merge** après review et validation des tests
   - PR de fonctionnalité → `Dev` (intégration)
   - PR **`Dev` → `staging`** pour tests (mettre à jour [`release-dev-to-staging-2026-06.md`](../10-decisions-and-changelog/release-dev-to-staging-2026-06.md) + CHANGELOG avant)
   - Merge `staging` → `main` pour production **après validation humaine**
   - CI : `.github/workflows/ci.yml` (Brakeman, importmap audit, RuboCop, `bin/rails test test:system`) sur PR + push sur `main`

---

## 📝 Messages de Commit

### Format Conventional Commits

```
<type>(<scope>): <description>

[optional body]

[optional footer]
```

### Types
- **`feat`** : Nouvelle fonctionnalité
- **`fix`** : Correction de bug
- **`docs`** : Documentation
- **`style`** : Formatage (pas de changement de code)
- **`refactor`** : Refactoring
- **`test`** : Tests
- **`chore`** : Maintenance (deps, config, etc.)
- **`perf`** : Amélioration performance
- **`ci`** : CI/CD

### Exemples
```bash
feat(events): add pagination to events list
fix(cart): persist cart for logged users
docs(setup): update local development guide
refactor(orders): extract payment service
test(attendances): add specs for counter cache
chore(deps): update rails to 8.1.1
```

### Scope (optionnel mais recommandé)
- `events`, `initiations`, `products`, `orders`, `cart`, `admin`, `auth`, `setup`, etc.

---

## 🔀 Pull Requests

### Règles de PR

1. **Titre clair et descriptif**
   - Format : `feat: Ajout pagination événements` ou `fix: Correction panier persistant`
   - En français pour le titre (contexte produit)

2. **Description complète**
   - Contexte et problème résolu
   - Solution apportée
   - Tests effectués
   - Checklist de review

3. **Petites PRs**
   - Une PR = une fonctionnalité/bug fix
   - Maximum ~500 lignes de code si possible
   - Si trop grande, découper en plusieurs PRs

4. **Tests requis**
   - Tous les tests passent (`bundle exec rspec`)
   - Nouveaux tests pour nouvelles fonctionnalités
   - Couverture maintenue ou améliorée

5. **Review obligatoire**
   - Minimum 1 approbation avant merge
   - Auto-review accepté pour fixes mineurs/docs

### Template PR

```markdown
## Description
[Description du changement]

## Type de changement
- [ ] Bug fix
- [ ] Nouvelle fonctionnalité
- [ ] Refactoring
- [ ] Documentation
- [ ] Autre

## Tests
- [ ] Tests unitaires ajoutés/modifiés
- [ ] Tests d'intégration ajoutés/modifiés
- [ ] Tests manuels effectués

## Checklist
- [ ] Code conforme aux conventions (RuboCop)
- [ ] Tests passent (RSpec)
- [ ] Documentation mise à jour si nécessaire
- [ ] Changelog mis à jour si nécessaire
```

---

## 👥 Code Review

### Principes

1. **Respect et bienveillance**
   - Critique constructive
   - Expliquer le "pourquoi"
   - Proposer des solutions alternatives

2. **Focus**
   - Architecture et design
   - Bugs potentiels
   - Performance
   - Sécurité
   - Tests

3. **Temps de réponse**
   - Répondre dans les 24-48h
   - Si blocage, communiquer rapidement

### Checklist Review

- [ ] Code lisible et maintenable
- [ ] Conventions respectées (RuboCop)
- [ ] Pas de duplication inutile
- [ ] Tests complets et pertinents
- [ ] Sécurité (pas de secrets, sanitization, etc.)
- [ ] Performance (pas de N+1, requêtes optimisées)
- [ ] Documentation à jour

---

## 🧪 Tests

### Règles

1. **Nouvelles fonctionnalités = nouveaux tests**
   - Tests unitaires (models, services)
   - Tests d'intégration (controllers, requests)
   - Tests système (features) si applicable

2. **Tous les tests doivent passer**
   ```bash
   bundle exec rspec
   # 166 tests, 0 échec
   ```

3. **Coverage**
   - Maintenir la couverture actuelle
   - Cibler 80%+ pour nouvelles features

4. **Factories**
   - Utiliser FactoryBot pour données de test
   - Factories existantes : utiliser ou étendre
   - Créer nouvelles factories si nécessaire

---

## 📚 Documentation

### Règles

1. **Documentation vivante**
   - Mettre à jour avec chaque changement significatif
   - Documentation dans `docs/` (markdown)

2. **Structure**
   - Utiliser les sections existantes (`00-overview`, `04-rails`, etc.)
   - Suivre les conventions de nommage (kebab-case)

3. **ADRs**
   - Créer ADR pour décisions architecturales importantes
   - Template : `docs/11-templates/adr-template.md`

4. **Changelog**
   - Mettre à jour `docs/10-decisions-and-changelog/CHANGELOG.md`
   - Format : date, type, description

---

## 🛠️ Conventions de Code

### Ruby/Rails

- **RuboCop Rails Omakase** : Configuration par défaut
- **Formatage** : Standard Ruby style guide
- **Indentation** : 2 espaces
- **Noms** : snake_case (variables, méthodes), PascalCase (classes)

### Frontend

- **Bootstrap 5** : Utiliser les classes Bootstrap
- **Stimulus** : Contrôleurs JavaScript
- **Turbo** : Navigation SPA-like
- **HTML** : ERB templates, sémantique correcte

### Base de Données

- **Migrations** : Une migration = un changement atomique
- **Nommage** : snake_case, descriptif
- **Index** : Ajouter pour performances (foreign keys, recherches fréquentes)

---

## 🚀 Déploiement

### Workflow

1. **Staging** : Tests avant production
   - Merge dans `staging`
   - Déploiement automatique (watchdog)
   - Tests de validation

2. **Production** : Après validation staging
   - Merge dans `main`
   - Déploiement automatique (watchdog)
   - Monitoring

### Règles

- **Jamais de merge direct en production** sans passer par staging
- **Backups automatiques** avant chaque déploiement
- **Health checks** automatiques après déploiement
- **Rollback** automatique si échec

**Voir détails** : [`docs/07-ops/deployment.md`](../07-ops/deployment.md)

---

## 📅 Rituels d'Équipe

### Daily Standup (Optionnel)
- Quoi fait hier ?
- Quoi prévu aujourd'hui ?
- Blocages ?

### Cycle Shape Up
- **Shaping** : Définition des limites
- **Betting Table** : Priorisation
- **Building** : Développement (3 semaines)
- **Cooldown** : Repos, amélioration (1 semaine)

**Voir détails** : [`docs/02-shape-up/README.md`](../02-shape-up/README.md)

---

## 🔗 Références

- **Overview projet** : [`docs/00-overview/README.md`](../00-overview/README.md)
- **Shape Up** : [`docs/02-shape-up/README.md`](../02-shape-up/README.md)
- **Conventions Rails** : [`docs/04-rails/conventions/README.md`](../04-rails/conventions/README.md)
- **Tests** : [`docs/05-testing/rspec/README.md`](../05-testing/rspec/README.md)

---

**Version** : 1.0  
**Dernière mise à jour** : 2025-01-30

