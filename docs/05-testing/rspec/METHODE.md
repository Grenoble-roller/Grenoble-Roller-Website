# Méthodologie Tests RSpec & Refactoring Rails Standards 2026

**Dernière mise à jour** : 2026-01-31

---

## Partie A : Correction des erreurs RSpec

Objectif : corriger les tests qui échouent de façon reproductible.

1. **Analyser** : exécuter le test (`bundle exec rspec spec/[chemin]/[fichier]_spec.rb:XX`), copier l’erreur, lire le code du test et le code applicatif.
2. **Documenter** : créer/mettre à jour une fiche dans `errors/` (voir [errors/TEMPLATE.md](errors/TEMPLATE.md)).
3. **Typage** : problème de **test** (config, données, helpers) ou de **logique** (bug applicatif).
4. **Corriger** : appliquer la solution la plus simple, relancer le test puis la suite du fichier.
5. **Clôturer** : mettre à jour le statut dans la fiche et dans [README.md](README.md).

**Règles** : une erreur à la fois, toujours vérifier qu’on ne casse pas d’autres specs, suivre les priorités (voir [RSPEC_AUDIT_REPORT.md](RSPEC_AUDIT_REPORT.md)).

---

## Partie B : Refactoring d’une méthode (Standards 2026)

Approche : **Research → Analyze → Plan → Implement**. Les livrables sont des fichiers Markdown (pas de génération de code automatique sans validation).

### Phase 1 : Identification & Contexte

- **Entrée** : fichier + méthode (ex. `app/models/order.rb #calculate_total`).
- **Contexte** : qui appelle la méthode (contrôleurs, services, jobs, vues) ; fréquence (route critique ou background) ; tests existants ; impact métier.
- **Livrable** : [refactoring/METHODE_CONTEXT.md](refactoring/METHODE_CONTEXT.md).

### Phase 2 : Recherche standards 2026

- **Catégoriser** la méthode :
  - **A** Logique métier complexe → service object, single responsibility
  - **B** Query/Scope ActiveRecord → N+1, eager loading, Arel
  - **C** Validation/Callback → callbacks minimaux, concerns
  - **D** API / service externe → timeout, retry, circuit breaker, async
  - **E** Vue / Helper → ViewComponent, logique minimale
  - **F** Authorization / sécurité → Pundit, StrongParameters
- **Recherche** : patterns Rails 7.2/8, Ruby 3.3, anti-patterns (callbacks en cascade, `rescue nil`, N+1, SQL interpolé, god objects).
- **Livrable** : [refactoring/METHODE_RESEARCH.md](refactoring/METHODE_RESEARCH.md).

### Phase 3 : Analyse de la méthode

- **Tableau** : ligne / code / problème / standard 2026 / priorité.
- **Métriques** : complexité cyclomatique, nombre de lignes, dépendances, side effects.
- **Code smells** : perf (N+1, cache), maintenabilité (longueur, imbrication, DRY), sécurité (SQL, mass assignment), robustesse (rescue large, nil checks, tests).
- **Livrable** : [refactoring/METHODE_ANALYSIS.md](refactoring/METHODE_ANALYSIS.md).

### Phase 4 : Plan de refactoring

- **Stratégie** :
  - **A** In-place (< 30 %) : même fichier, optimisations locales.
  - **B** Extraction service (30–70 %) : `app/services/...`, tests migrés.
  - **C** Refonte (> 70 %) : design pattern, plusieurs fichiers, tests réécrits.
- **Étapes** : (1) Sécuriser avec tests, (2) Extractions simples, (3) Optimisations queries, (4) Simplifications logiques, (5) Extraction service si B/C, (6) Cleanup, (7) Documentation.
- **Livrable** : [refactoring/REFACTORING_PLAN.md](refactoring/REFACTORING_PLAN.md).

### Phase 5 : Implémentation guidée

- Pour **chaque étape** : afficher code AVANT → expliquer transformation → code APRÈS → commande de test → **attendre validation** avant de continuer.
- **Ne pas** tout coder d’un coup ; ne pas modifier sans validation explicite.

### Phase 6 : Validation finale

- **Checklist** : tous les tests passent, comportement identique (sauf amélioration voulue), Rubocop, complexité < 10, méthode < 15 lignes (ou justifiée), pas de vulnérabilité Brakeman.
- **Livrable** : [refactoring/REFACTORING_REPORT.md](refactoring/REFACTORING_REPORT.md) (métriques avant/après, changements, breaking changes, impact perf, recommandations).

---

## Contraintes

- **À faire** : rechercher les standards, analyser le contexte, proposer un plan étape par étape, expliquer les changements, attendre validation entre étapes, produire les fichiers Markdown.
- **À ne pas faire** : générer tout le code d’un coup, modifier sans validation, ignorer les tests existants, introduire des breaking changes sans discussion, optimiser sans mesurer, utiliser des gems obsolètes.

---

## Standards code (référence 2026)

- **Ruby 3.3** : pattern matching, endless methods, paramètres numérotés, safe navigation `&.`.
- **Rails 7.2/8** : Hotwire/Turbo, ActiveRecord `with` / `strict_loading` / `async`, credentials, Solid Queue/Cache.
- **Perf** : N+1 → `includes`/`preload`/`eager_load`, pagination (pagy), cache, jobs.
- **Sécurité** : StrongParameters, Pundit `authorize`, CSRF, Content Security Policy.
- **Tests** : RSpec, FactoryBot `build_stubbed` quand possible, Capybara headless Chrome pour system.
- **Style** : Rubocop, snake_case, YARD pour méthodes complexes, ~120 caractères/ligne.

---

## Commandes utiles

```bash
# Tests
bundle exec rspec spec/[fichier]_spec.rb
bundle exec rspec spec/[fichier]_spec.rb:XX
bundle exec rspec --profile 10

# Analyse
bundle exec rubocop [fichier]
bundle exec brakeman
```

---

## Fichiers du dossier

| Fichier | Rôle |
|---------|------|
| [README.md](README.md) | Vue d’ensemble et index |
| [METHODE.md](METHODE.md) | Ce document (correction erreurs + refactoring 2026) |
| [RSPEC_AUDIT_REPORT.md](RSPEC_AUDIT_REPORT.md) | Audit quantitatif/qualitatif et priorités |
| [errors/TEMPLATE.md](errors/TEMPLATE.md) | Template fiche d’erreur |
| [refactoring/](refactoring/) | Templates des livrables refactoring (Phase 1 à 6) |
