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

1. **Exécuter le test spécifique** pour voir l'erreur exacte (avec `RAILS_ENV=test` si tu passes par le conteneur dev) :
   ```bash
   docker compose -f ops/dev/docker-compose.yml exec -e RAILS_ENV=test web bundle exec rspec ./spec/[chemin]/[fichier]_spec.rb:XX
   ```
   Ou avec le nom du conteneur : `docker exec -e RAILS_ENV=test grenoble-roller-dev bundle exec rspec ./spec/...`

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

1. **Appliquer la solution** dans le code
2. **Exécuter le test** pour vérifier qu'il passe
3. **Vérifier qu'on n'a pas cassé d'autres tests** :
   ```bash
   docker compose -f ops/dev/docker-compose.yml exec -e RAILS_ENV=test web bundle exec rspec ./spec/[chemin]/[fichier]_spec.rb
   ```
4. **Vérifier l'impact des modifications** :
   - Identifier les **vues / écrans** concernés par le code modifié (contrôleur, modèle, service).
   - Si des vues ou flux utilisateur sont touchés : **test manuel** des écrans concernés (ou au minimum relire le code pour confirmer l’absence de régression).
   - Documenter dans la fiche d’erreur si un impact vue a été vérifié (ou « aucune vue modifiée »).

### Phase 6 : Validation finale

- **Checklist** : tous les tests passent, comportement identique (sauf amélioration voulue), Rubocop, complexité < 10, méthode < 15 lignes (ou justifiée), pas de vulnérabilité Brakeman.
- **Livrable** : [refactoring/REFACTORING_REPORT.md](refactoring/REFACTORING_REPORT.md) (métriques avant/après, changements, breaking changes, impact perf, recommandations).

---

## Contraintes

- **À faire** : rechercher les standards, analyser le contexte, proposer un plan étape par étape, expliquer les changements, attendre validation entre étapes, produire les fichiers Markdown.
- **À ne pas faire** : générer tout le code d’un coup, modifier sans validation, ignorer les tests existants, introduire des breaking changes sans discussion, optimiser sans mesurer, utiliser des gems obsolètes.

---

## Standards code (référence 2026)

- [ ] Erreur exécutée et copiée
- [ ] Code du test lu et compris
- [ ] Code de l'application lu et compris
- [ ] Type de problème identifié (test ou logique)
- [ ] Solutions proposées documentées
- [ ] Solution appliquée
- [ ] Test passé
- [ ] Vérification impact : autres tests + vues/écrans concernés (test manuel ou relecture)
- [ ] Documentation mise à jour
- [ ] Statut mis à jour dans README.md

---

## Commandes utiles

1. **Une erreur à la fois** : Ne pas mélanger plusieurs corrections
2. **Toujours tester** : Vérifier que la correction fonctionne
3. **Documenter tout** : Mettre à jour les fichiers d'erreur
4. **Vérifier les dépendances** : S'assurer qu'on ne casse pas d'autres tests ; vérifier l'impact sur les vues/écrans concernés (étape 5.4)
5. **Suivre les priorités** : Traiter les erreurs par ordre de priorité

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
