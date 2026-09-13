# Rebuild Without Cache - Staging

**Dernière mise à jour** : 2026-08-14


Guide pour rebuilder les conteneurs Docker sans utiliser le cache, utile pour forcer la recompilation des assets et résoudre les problèmes d'images manquantes.

## Rebuild Complet Sans Cache

### Staging

```bash
# Arrêter les conteneurs
docker compose -f ops/staging/docker-compose.yml down

# Supprimer l'image existante (optionnel mais recommandé)
docker rmi staging-web 2>/dev/null || true

# Rebuild sans cache
docker compose -f ops/staging/docker-compose.yml build --no-cache

# Redémarrer
docker compose -f ops/staging/docker-compose.yml up -d

# Vérifier les logs
docker logs -f grenoble-roller-staging
```

### Development

```bash
# Arrêter les conteneurs
docker compose -f ops/dev/docker-compose.yml down

# Rebuild sans cache
docker compose -f ops/dev/docker-compose.yml build --no-cache

# Redémarrer
docker compose -f ops/dev/docker-compose.yml up -d
```

## Nettoyer le Cache Docker

Si le problème persiste, nettoyer le cache Docker :

```bash
# Nettoyer les images non utilisées
docker image prune -a

# Nettoyer tout le cache de build
docker builder prune -a

# Rebuild
docker compose -f ops/staging/docker-compose.yml build --no-cache
```

## Forcer la Recompilation des Assets Rails

Dans le conteneur :

```bash
# Nettoyer les assets compilés
docker exec grenoble-roller-staging bin/rails assets:clobber

# Recompiler les assets
docker exec grenoble-roller-staging bin/rails assets:precompile

# Redémarrer le conteneur
docker compose -f ops/staging/docker-compose.yml restart web
```

## Vérifier les Assets

```bash
# Lister les assets compilés
docker exec grenoble-roller-staging ls -la public/assets/

# Vérifier les chemins d'images
docker exec grenoble-roller-staging bin/rails runner "puts ActionController::Base.helpers.asset_path('img/bannersmall3.png')"
```

## Problèmes Courants

### Images 404 après rebuild

1. Vérifier que les images existent dans `app/assets/images/`
2. Vérifier que les chemins utilisent `asset-url()` dans le CSS
3. Vérifier que les vues utilisent `image_tag()` ou `image_path()` helpers
4. Nettoyer et recompiler les assets

### CSS ne se met pas à jour

```bash
# Forcer la recompilation CSS
docker exec grenoble-roller-staging bin/rails assets:clobber
docker exec grenoble-roller-staging bin/rails assets:precompile
docker compose -f ops/staging/docker-compose.yml restart web
```

### Cache du navigateur

- Vider le cache du navigateur (Ctrl+Shift+R ou Cmd+Shift+R)
- Ouvrir en navigation privée
- Vérifier les headers de cache dans les DevTools

