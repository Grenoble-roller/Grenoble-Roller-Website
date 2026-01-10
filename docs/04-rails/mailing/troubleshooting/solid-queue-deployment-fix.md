# 🔧 Correction Déploiement Solid Queue - Rebuild No-Cache Forcé

**Date** : 2025-12-30  
**Dernière mise à jour** : 2025-12-30 (ajout relance automatique `compose up -d`)  
**Problème** : Le conteneur s'arrête car Solid Queue ne peut pas démarrer (tables SQLite manquantes)  
**Solution** : Rebuild `--no-cache` forcé 100% du temps + migrations SQLite dans docker-entrypoint + relance automatique `compose up -d`

---

## 🚨 Problème Identifié

### Symptômes

1. **Le conteneur démarre** puis **s'arrête immédiatement**
2. **Cause** : Solid Queue essaie de se connecter à SQLite mais les tables n'existent pas encore
3. **Impact** : Le script `verify_migrations_synced()` échoue car il utilise `docker exec` qui nécessite un conteneur running

### Diagnostic

```
Image Docker : 66 migrations présentes ✅
Conteneur running : 66 migrations détectées avec docker exec ✅
Le script fonctionne quand le conteneur est running ✅

Problème réel :
- Le conteneur s'arrête avant que la vérification ne s'exécute
- Solid Queue ne peut pas démarrer (tables SQLite manquantes)
- L'image Docker est ancienne (pas de sqlite3 dans Gemfile)
```

---

## ✅ Solutions Appliquées

### 1. Rebuild `--no-cache` Forcé 100% du Temps

**Fichier** : `ops/production/deploy.sh` (et `ops/deploy.sh`)

**Modification** :
```bash
# AVANT : Décision intelligente (cache ou no-cache)
if [ "$NEED_NO_CACHE_BUILD" = true ] || needs_no_cache_build; then
    force_rebuild_without_cache
else
    docker_compose_build  # Avec cache
fi

# APRÈS : FORCÉ 100% DU TEMPS
log "🔨 Build SANS CACHE (FORCÉ - 100% du temps pour éviter problèmes de cache)..."
force_rebuild_without_cache "$COMPOSE_FILE" "$CONTAINER_NAME"
```

**Raison** :
- ✅ Garantit que le nouveau `Gemfile` (avec `sqlite3`) est inclus
- ✅ Garantit que `database.yml` (avec SQLite config) est inclus
- ✅ Garantit que toutes les migrations sont à jour
- ⚠️ Plus lent (5-10 minutes) mais **fiable à 100%**

### 2. Migrations SQLite dans `docker-entrypoint`

**Fichier** : `bin/docker-entrypoint`

**Modification** :
```bash
# AVANT : Seulement PostgreSQL
if [ "${@: -2:1}" == "./bin/rails" ] && [ "${@: -1:1}" == "server" ]; then
  ./bin/rails db:prepare || ./bin/rails db:migrate
fi

# APRÈS : PostgreSQL + SQLite Queue
if [ "${@: -2:1}" == "./bin/rails" ] && [ "${@: -1:1}" == "server" ]; then
  ./bin/rails db:prepare || ./bin/rails db:migrate
  
  # Préparer la queue SQLite AVANT que Solid Queue démarre
  mkdir -p storage
  ./bin/rails db:migrate:queue || echo "Warning: queue may not be configured yet"
fi
```

**Raison** :
- ✅ Les migrations SQLite sont appliquées **AVANT** que Solid Queue démarre
- ✅ Évite que le conteneur crash au démarrage
- ✅ Non bloquant si la queue n'est pas encore configurée

### 3. Amélioration `verify_migrations_synced()`

**Fichier** : `ops/lib/database/migrations.sh`

**Modification** :
- Gère le cas où le conteneur n'est pas running
- Utilise `docker run` avec l'image si le conteneur est arrêté
- Non bloquant si le conteneur n'est pas running (vérification après démarrage)

### 4. Gestion du Conteneur qui S'arrête

**Fichier** : `ops/production/deploy.sh`

**Modifications** :
- Vérification que le conteneur est running avant les migrations
- Redémarrage automatique si le conteneur s'arrête après les migrations
- Messages d'erreur clairs avec logs

---

## 📋 Ordre d'Exécution Corrigé

### Nouvel Ordre (Avec Corrections)

1. **Rebuild `--no-cache`** (FORCÉ 100% du temps)
   - Inclut le nouveau `Gemfile` avec `sqlite3`
   - Inclut `database.yml` avec configuration SQLite
   - Inclut toutes les migrations

2. **Démarrage des conteneurs**
   - PostgreSQL démarre
   - Application démarre

3. **`docker-entrypoint` s'exécute automatiquement**
   - Applique `db:migrate` (PostgreSQL)
   - Applique `db:migrate:queue` (SQLite) **AVANT** que Solid Queue démarre
   - Solid Queue peut maintenant démarrer correctement

4. **Vérification migrations** (si conteneur running)
   - Vérifie que les migrations sont synchronisées
   - Gère le cas où le conteneur n'est pas running

5. **Migrations supplémentaires** (si nécessaire)
   - `db:migrate` (PostgreSQL) - migrations en attente
   - `db:migrate:queue` (SQLite) - migrations en attente

---

## 🔍 Vérifications Post-Déploiement

### 1. Vérifier que le Conteneur Reste Running

```bash
# Vérifier l'état du conteneur
docker ps | grep grenoble-roller-staging

# Doit afficher "Up X minutes" (pas "Exited")
```

### 2. Vérifier les Logs

```bash
# Vérifier les logs du conteneur
docker logs grenoble-roller-staging | tail -50

# Chercher :
# - "Preparing SQLite queue database" ✅
# - "Migrations de la queue SQLite appliquées" ✅
# - Pas d'erreur "uninitialized constant SolidQueue" ✅
```

### 3. Vérifier que Solid Queue Fonctionne

```bash
# Vérifier que Solid Queue peut se connecter
docker exec grenoble-roller-staging bin/rails runner "puts SolidQueue::Job.count"

# Doit retourner : 0 (pas d'erreur)
```

### 4. Vérifier le Fichier SQLite

```bash
# Vérifier que le fichier SQLite existe
docker exec grenoble-roller-staging ls -la /rails/storage/solid_queue.sqlite3

# Doit afficher le fichier avec une taille > 0
```

---

## ⚠️ Points d'Attention

### 1. Temps de Build

**Avant** : 1-2 minutes (avec cache)  
**Après** : 5-10 minutes (sans cache)

**Compromis** : Plus lent mais **fiable à 100%**, évite tous les problèmes de cache.

### 2. Ordre Critique

**IMPORTANT** : Les migrations SQLite doivent être appliquées **AVANT** que Solid Queue démarre.

**Solution** : `docker-entrypoint` applique automatiquement les migrations SQLite au démarrage du serveur Rails.

### 3. Gestion des Erreurs

- Si `db:migrate:queue` échoue dans `docker-entrypoint`, c'est **non bloquant**
- Le script de déploiement réessaiera les migrations SQLite après le démarrage
- Si le conteneur s'arrête, il sera redémarré automatiquement

---

## ✅ Checklist de Vérification

- [x] Rebuild `--no-cache` forcé 100% du temps
- [x] Migrations SQLite dans `docker-entrypoint`
- [x] Amélioration `verify_migrations_synced()` pour gérer conteneur non running
- [x] Gestion redémarrage automatique si conteneur s'arrête
- [x] Messages d'erreur clairs avec logs
- [x] Relance automatique `compose up -d` après échecs
- [x] Vérification services après `force_rebuild_without_cache`
- [x] Points de relance multiples dans `deploy.sh`
- [ ] Tester le déploiement complet
- [ ] Vérifier que le conteneur reste running
- [ ] Vérifier que Solid Queue fonctionne

---

## 📚 Références

- [Solid Queue GitHub](https://github.com/rails/solid_queue)
- [Rails 8 Multi-Database Guide](https://guides.rubyonrails.org/active_record_multiple_databases.html)
- Document : `docs/04-rails/mailing/troubleshooting/solid-queue-deployment-fix.md` (ce fichier)

---

**Date de mise à jour** : 2025-12-30 (ajout relance automatique `compose up -d`)  
**Statut** : ✅ **CORRECTIONS APPLIQUÉES + SÉCURITÉS AJOUTÉES**
