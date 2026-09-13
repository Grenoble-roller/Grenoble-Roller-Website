# Vue d’ensemble système

**Dernière mise à jour** : 2026-08-14


Monolithe Ruby on Rails 8 avec PostgreSQL. L’application expose des pages publiques, une boutique (catalogue, panier, commandes) et utilise Devise pour l’authentification.

## Contexte (C4 – Niveau 1)

```
[Navigateur] ──HTTP──> [Rails 8 Monolithe]
                         │
                         ├── ActiveRecord ──> PostgreSQL 16
                         ├── Devise (auth)
                         ├── Turbo + Stimulus (front dynamique)
                         └── CSS bundling (Sass + PostCSS)
```

## Environnements
- Développement: Docker Compose (`ops/dev/`), port `3000` (DB exposée sur `5434`).
- Staging: Docker Compose (`ops/staging/`), port `3001`, mode proche production.
- Production: Docker Compose (`ops/production/`), port `3002`, build optimisé.

Santé: `GET /up` retourne 200 si l’app est OK (healthcheck Docker).

## Données & modèles clés
- Utilisateurs (Devise) + Rôles (7 niveaux)
- Produits, Variantes, Options (size/color)
- Commandes, Lignes de commande, Paiements (structure multi-fournisseurs)

## Sécurité
- Authentification via Devise, `authenticate_user!` sur les commandes
- Secrets via Credentials Rails (`config/credentials.yml.enc`, `config/master.key`)
- Brakeman + RuboCop Rails Omakase en dev

## Observabilité légère
- Healthcheck `/up`
- Logs de conteneurs (`docker logs`)

## Contraintes non-fonctionnelles (NFR)
- Simplicité: monolithe Rails d’abord
- Performance: éviter N+1 via `includes`, index DB
- Déploiement: conteneurs Docker par environnement
