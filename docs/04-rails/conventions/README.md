# Conventions Rails du projet

**Dernière mise à jour** : 2026-08-14


## Général
- Rails 8, Ruby 3.4.2
- Style: RuboCop Rails Omakase
- Nommage: anglais pour le code, français pour les textes UI

## Controllers
- Fins et RESTful, redirigent vers des modèles/services
- Auth: `authenticate_user!` pour actions sensibles (ex: commandes)
- Eager loading systématique (`includes`) pour éviter N+1

## Models
- Validations + index DB cohérents
- Logique métier proche des modèles
- Relations explicites + contraintes FK

## Vues
- ERB + Bootstrap 5, classes utilitaires
- Partials pour réutilisation (cart items, listings, etc.)
- Turbo/Stimulus pour interactions légères

## CSS & Build
- `cssbundling-rails` (Sass + PostCSS Autoprefixer)
- Scripts NPM: `build:css`, `watch:css`
- Watcher séparé dans Docker (`css-watcher`)

## Sécurité
- Devise pour l’authentification
- Credentials chiffrés (`config/credentials.yml.enc`) – ne jamais commiter `config/master.key`
- Brakeman en développement

## Performances
- Éviter N+1 (e.g. produits → variantes → options)
- Index sur colonnes de recherche (slugs, FKs)

## Tests
- Minitest (`test/`), exécution via `bin/rails test`

## Divers
- Pas de namespace admin (pour l’instant)
- Monolithe (pas de microservices)
