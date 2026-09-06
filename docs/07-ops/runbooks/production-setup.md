# Production Environment Setup

**Dernière mise à jour** : 2026-08-14


Ce guide décrit la mise en place et l’exécution de l’environnement de production local simulé via Docker Compose.

## Pré-requis
- Docker Engine 20.10+
- Docker Compose 2.0+
- Accès au dépôt
- Fichier `.env` (optionnel) et `config/master.key` (jamais commité)

## Vue d’ensemble
- Port: `3002` (mappé vers 3000 dans le conteneur)
- Base de données: `grenoble_roller_production` (PostgreSQL)
- Environnement Rails: `production`
- Conteneur app: `grenoble-roller-prod`

## Démarrage

### 1) Construire et lancer

```bash
docker compose -f ops/production/docker-compose.yml up -d --build
```

Cela démarre la base PostgreSQL et l’application Rails avec healthcheck.

### 2) Initialiser la base

```bash
docker exec grenoble-roller-prod bin/rails db:migrate
# Optionnel: données de démo
docker exec grenoble-roller-prod bin/rails db:seed
```

### 3) Vérifier

- Application: http://localhost:3002
- Santé: `curl -f http://localhost:3002/up`
- Logs: `docker logs -f grenoble-roller-prod`

## Opérations courantes
- Console Rails: `docker exec -it grenoble-roller-prod bin/rails console`
- Migrations: `docker exec grenoble-roller-prod bin/rails db:migrate`
- Arrêt: `docker compose -f ops/production/docker-compose.yml down`
- Rebuild: `docker compose -f ops/production/docker-compose.yml up -d --build`

## Sauvegarde / Restauration DB

```bash
# Backup
docker exec grenoble-roller-db-prod pg_dump -U postgres grenoble_roller_production > backup_$(date +%Y%m%d_%H%M%S).sql

# Restore
cat backup_YYYYMMDD_HHMMSS.sql | docker exec -i grenoble-roller-db-prod psql -U postgres grenoble_roller_production
```

## Variables d’environnement
Paramètres sensibles fournis via `.env` (optionnel) ou `RAILS_MASTER_KEY`.

```yaml
# Extrait ops/production/docker-compose.yml
environment:
  DATABASE_URL: postgresql://postgres:postgres@db:5432/grenoble_roller_production
  RAILS_ENV: production
  # RAILS_MASTER_KEY: ${RAILS_MASTER_KEY}
```

## Dépannage
- Conteneur KO: `docker ps -a`, `docker logs grenoble-roller-prod`
- DB: `docker exec grenoble-roller-db-prod pg_isready -U postgres`
- Port occupé: modifier `ports: ["3002:3000"]`
- Credentials manquants: vérifier `RAILS_MASTER_KEY` et `config/master.key`

## Liens utiles
- Local Dev: `../../04-rails/setup/local-development.md`
- Staging: `./staging-setup.md`
- Credentials: `../../04-rails/setup/credentials.md`
