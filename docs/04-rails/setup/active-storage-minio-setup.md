# Configuration Active Storage avec MinIO

**Dernière mise à jour** : 2026-08-14


Ce document décrit la configuration complète d'Active Storage avec MinIO (S3-compatible) pour le projet Grenoble Roller.

## Vue d'ensemble

Active Storage est maintenant intégré avec MinIO pour le stockage des fichiers (images de produits, événements, avatars, cartes de parcours).

## Architecture

- **MinIO** : Service S3-compatible pour le stockage des fichiers
- **Active Storage** : Framework Rails pour la gestion des uploads
- **Environnements** :
  - Dev : MinIO sur port 9000 (API) et 9001 (Console)
  - Staging : MinIO sur port 9002 (API) et 9003 (Console)
  - Production : MinIO sur port 9004 (API) et 9005 (Console)

## Configuration des credentials

### 1. Éditer les credentials Rails

```bash
bin/rails credentials:edit
```

### 2. Ajouter la configuration MinIO

```yaml
minio:
  access_key_id: minioadmin
  secret_access_key: minioadmin
  endpoint: http://minio:9000  # Pour dev (dans Docker)
  # Pour staging: http://minio:9000
  # Pour production: http://minio:9000
```

**Note** : Les endpoints sont relatifs au réseau Docker. Depuis l'hôte, utilisez `localhost:9000` (dev), `localhost:9002` (staging), `localhost:9004` (production).

### 3. Configuration par environnement

#### Development
- Endpoint Docker : `http://minio:9000`
- Endpoint Hôte : `http://localhost:9000`
- Console : `http://localhost:9001`

#### Staging
- Endpoint Docker : `http://minio:9000`
- Endpoint Hôte : `http://localhost:9002`
- Console : `http://localhost:9003`

#### Production
- Endpoint Docker : `http://minio:9000`
- Endpoint Hôte : `http://localhost:9004`
- Console : `http://localhost:9005`

## Configuration MinIO

### Créer les buckets

Une fois MinIO démarré, accédez à la console web et créez les buckets suivants :

- `grenoble-roller-development`
- `grenoble-roller-staging`
- `grenoble-roller-production`

**Via la console web** :
1. Accédez à `http://localhost:9001` (dev)
2. Connectez-vous avec `minioadmin` / `minioadmin`
3. Créez les buckets nécessaires

**Via la ligne de commande** (dans le conteneur) :
```bash
docker exec -it grenoble-roller-minio-dev mc mb /data/grenoble-roller-development
```

## Modèles migrés

Les modèles suivants utilisent maintenant Active Storage :

- **Event** : `cover_image` (remplace `cover_image_url`)
- **Product** : `image` (remplace `image_url`)
- **ProductVariant** : `image` (remplace `image_url`)
- **User** : `avatar` (remplace `avatar_url`)
- **Route** : `map_image` (remplace `map_image_url`)

## Transition

Les colonnes `*_url` sont conservées pour la transition. Les vues et helpers gèrent automatiquement :
1. Active Storage attaché (priorité)
2. URL string (fallback)
3. Image par défaut (si aucune image)

## Migration des données existantes

Si vous avez des données existantes avec des URLs, vous pouvez créer une migration pour les convertir :

```ruby
# db/migrate/YYYYMMDDHHMMSS_migrate_urls_to_active_storage.rb
class MigrateUrlsToActiveStorage < ActiveRecord::Migration[8.1]
  def up
    # Exemple pour Event
    Event.where.not(cover_image_url: nil).find_each do |event|
      next if event.cover_image.attached?
      # Télécharger l'image depuis l'URL et l'attacher
      # (nécessite une gem comme open-uri ou httparty)
    end
  end
end
```

## Tests

Les tests utilisent le service `:test` (stockage local temporaire) configuré dans `config/environments/test.rb`.

## Dépannage

### MinIO ne démarre pas

Vérifiez les logs :
```bash
docker logs grenoble-roller-minio-dev
```

### Erreur de connexion

1. Vérifiez que MinIO est démarré : `docker ps | grep minio`
2. Vérifiez les credentials dans `bin/rails credentials:show`
3. Vérifiez l'endpoint dans `config/storage.yml`

### Bucket introuvable

Créez le bucket manuellement via la console web ou la CLI MinIO.

## Sécurité Production

Pour la production, changez les credentials par défaut :

1. Modifiez `MINIO_ROOT_USER` et `MINIO_ROOT_PASSWORD` dans `docker-compose.yml`
2. Mettez à jour les credentials Rails
3. Utilisez des secrets sécurisés (variables d'environnement, secrets manager)

## Références

- [Active Storage Overview](https://guides.rubyonrails.org/active_storage_overview.html)
- [MinIO Documentation](https://min.io/docs/)
- [AWS S3 SDK for Ruby](https://github.com/aws/aws-sdk-ruby)

