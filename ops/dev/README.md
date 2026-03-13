# 🚀 Scripts de déploiement DEV

Scripts dédiés à l'environnement de développement.

## 📋 Fichiers

- **`deploy.sh`** : Script de déploiement automatique DEV
- **`watchdog.sh`** : Script de surveillance (appelé par cron)

## ✨ Fonctionnalités automatiques

- ✅ **Création automatique des dossiers** : `backups/dev` et `logs/`
- ✅ **Vérification de branche** : Vérifie et passe automatiquement sur `Dev`
- ✅ **Vérification accès GitHub** : Détecte si SSH/HTTPS est configuré
- ✅ **Pas de rollback** : En dev, les erreurs restent pour debug

## 🚀 Utilisation

### Test manuel

```bash
# Depuis la racine du projet
./ops/dev/deploy.sh
```

### Automatisation (cron)

```bash
# Toutes les 5 minutes
*/5 * * * * cd /home/flowtech/Dev-Grenoble-Roller-Project && ./ops/dev/watchdog.sh
```

## 📊 Logs

- **Emplacement** : `logs/deploy-dev.log` (dans le projet)
- **Backups** : `backups/dev/` (dans le projet)

## ⚙️ Prérequis

1. **Accès GitHub** (SSH ou HTTPS) :
   ```bash
   # Vérifier l'accès
   git fetch origin
   
   # Si erreur, configurer SSH :
   ssh-keygen -t ed25519 -f ~/.ssh/github_deploy -N ""
   cat ~/.ssh/github_deploy.pub
   # Ajouter dans GitHub > Settings > Deploy keys
   git config --global core.sshCommand "ssh -i ~/.ssh/github_deploy -F /dev/null"
   ```

2. **Docker** : Les conteneurs doivent être accessibles

## 🔍 Vérification rapide

```bash
# Vérifier l'accès GitHub
git fetch origin

# Vérifier la branche
git branch

# Tester le script
./ops/dev/deploy.sh
```

---

**C'est tout !** Le script gère le reste automatiquement.

