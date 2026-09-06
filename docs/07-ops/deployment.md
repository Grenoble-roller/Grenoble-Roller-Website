# 🚀 Déploiement Automatique - Watchdog

**Dernière mise à jour** : 2026-08-14


## 📋 Vue d'ensemble

Système de déploiement automatique **100% local** qui surveille les mises à jour Git et déploie automatiquement.

---

## 🏗️ Architecture

```
Git Push → GitHub
    ↓
Script Watchdog (cron toutes les 5 min)
    ↓
Détecte nouvelle version
    ↓
Script Deploy :
  1. Backup DB + volumes
  2. git pull
  3. docker compose build
  4. docker compose up -d
  5. rails db:migrate
  6. Health check
  7. Si OK → Succès
  8. Si échec → Rollback auto
```

---

## 📁 Structure

```
ops/scripts/
├── deploy.sh      # Script de déploiement principal
└── watchdog.sh    # Script de surveillance (appelé par cron)

/backups/
├── staging/       # Backups DB + volumes staging
└── production/    # Backups DB + volumes production

/var/log/grenoble-roller/
├── deploy-staging.log
└── deploy-production.log
```

---

## 🔧 Configuration par machine

### Machine DEV

**1. Accès Git** :
```bash
ssh-keygen -t ed25519 -f ~/.ssh/github_deploy -N ""
cat ~/.ssh/github_deploy.pub
# Ajouter cette clé dans GitHub > Settings > Deploy keys
git config --global core.sshCommand "ssh -i ~/.ssh/github_deploy -F /dev/null"
```

**2. Cron** :
```bash
# Dev : toutes les 5 minutes
*/5 * * * * /app/grenoble-roller/ops/scripts/watchdog-dev.sh
```

**3. Test manuel** :
```bash
./ops/scripts/deploy-dev.sh
```

---

### Machine STAGING

**1. Accès Git** (même procédure que dev)

**2. Cron** :
```bash
# Staging : toutes les 5 minutes
*/5 * * * * /app/grenoble-roller/ops/scripts/watchdog-staging.sh
```

**3. Test manuel** :
```bash
./ops/scripts/deploy-staging.sh
```

---

### Machine PRODUCTION

**1. Accès Git** (même procédure que dev)

**2. Cron** :
```bash
# Production : toutes les 10 minutes
*/10 * * * * /app/grenoble-roller/ops/scripts/watchdog-production.sh
```

**3. Test manuel** :
```bash
./ops/scripts/deploy-production.sh
```

---

### Variables d'environnement (optionnel, sur chaque machine)

Créer `.env.server` sur chaque serveur :
```bash
SLACK_WEBHOOK=https://hooks.slack.com/services/...
BACKUP_RETENTION_DAYS=7
```

---

## 📊 Logs

### Emplacement

- **Dev** : `/var/log/grenoble-roller/deploy-dev.log`
- **Staging** : `/var/log/grenoble-roller/deploy-staging.log`
- **Production** : `/var/log/grenoble-roller/deploy-production.log`

### Format

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🚀 DEPLOYMENT START - staging - 2025-01-20 10:30:00
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
[2025-01-20 10:30:01] 📥 Vérification des mises à jour...
[2025-01-20 10:30:02] 🆕 Nouvelle version détectée...
[2025-01-20 10:30:03] 📦 Backup base de données...
...
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
✅ DEPLOYMENT SUCCESS
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

---

## 🧪 Tests

### Test manuel

**Sur chaque machine** :
```bash
# Dev
./ops/scripts/deploy-dev.sh
tail -f /var/log/grenoble-roller/deploy-dev.log

# Staging
./ops/scripts/deploy-staging.sh
tail -f /var/log/grenoble-roller/deploy-staging.log

# Production
./ops/scripts/deploy-production.sh
tail -f /var/log/grenoble-roller/deploy-production.log
```

### Test du watchdog

```bash
# Exécuter manuellement sur chaque machine
./ops/scripts/watchdog-dev.sh
./ops/scripts/watchdog-staging.sh
./ops/scripts/watchdog-production.sh
```

---

## 🚨 Troubleshooting

### Le déploiement ne se déclenche pas

**Vérifier** :
- Le cron tourne : `crontab -l`
- Les logs du cron : `/var/log/cron` ou `journalctl -u cron`
- L'accès Git fonctionne : `git fetch origin`

### Le build échoue

**Vérifier** :
- Docker fonctionne : `docker ps`
- Espace disque : `df -h`
- Logs Docker : `docker logs grenoble-roller-staging`

### Health check échoue

**Vérifier** :
- Le conteneur tourne : `docker ps | grep staging`
- L'application répond : `curl http://localhost:3001/up`
- Les logs de l'app : `docker logs grenoble-roller-staging`

### Rollback automatique

Si le déploiement échoue, le rollback est automatique :
- Retour au commit précédent
- Rebuild avec l'ancienne version
- Restauration de la DB si nécessaire

---

## 📦 Backups

### Emplacement

- **Dev** : `/backups/dev/`
- **Staging** : `/backups/staging/`
- **Production** : `/backups/production/`

### Rétention

- **20 derniers backups** conservés automatiquement
- Format : `db_YYYYMMDD_HHMMSS.sql` et `volumes_YYYYMMDD_HHMMSS.tar.gz`

### Restauration manuelle

```bash
# Restaurer la DB
cat /backups/staging/db_20250120_103000.sql | \
  docker exec -i grenoble-roller-db-staging psql -U postgres grenoble_roller_production
```

---

## 🔔 Notifications (optionnel)

### Slack

Configurer dans `.env.server` :
```bash
SLACK_WEBHOOK=https://hooks.slack.com/services/YOUR/WEBHOOK
```

Notifications envoyées :
- ✅ Déploiement réussi
- ❌ Déploiement échoué (rollback)

---

## ✅ Avantages

- ✅ **100% local** : Pas de SSH depuis GitHub, pas de registry
- ✅ **Simple** : Scripts bash uniquement
- ✅ **Backup automatique** : DB + volumes avant chaque déploiement
- ✅ **Rollback automatique** : En cas d'échec
- ✅ **Health check** : Vérification avant validation
- ✅ **Logs détaillés** : Tout est tracé
- ✅ **Pas de port à exposer** : Tout est local

---

**Version** : 1.0  
**Date** : 2025-01-20

