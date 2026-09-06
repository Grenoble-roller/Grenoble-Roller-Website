# ⏰ Gestion Automatique du Crontab

**Dernière mise à jour** : 2026-08-14


> ⚠️ **SUPERSÉDÉ (2026-08-14)** : Le cron hôte/whenever décrit ci-dessous est **remplacé par Solid Queue**.
> Tous les jobs récurrents sont désormais gérés via [`config/recurring.yml`](../../config/recurring.yml)
> (chargé par l'app — rappels événements, sync HelloAsso, adhésions expirées, rappels renouvellement,
> retour rollers, expiration panier) et monitorés via Mission Control (`/admin-panel/jobs`).
> Voir [`docs/04-rails/background-jobs/CRON.md`](../04-rails/background-jobs/CRON.md) et
> [`docs/04-rails/mailing/README.md`](../04-rails/mailing/README.md) pour la documentation à jour.
> `config/schedule.rb` et `config/crontab` sont conservés **pour référence uniquement** (supercronic déprécié).

## 📋 Vue d'ensemble

Le système de rappels et de tâches planifiées utilisait **whenever** pour générer et installer automatiquement le crontab sur l'hôte (machine physique), **pas dans le container Docker**. Ce document est conservé comme historique de l'ancienne approche.

## 🎯 Pourquoi sur l'hôte et pas dans le container ?

### ✅ Avantages du cron sur l'hôte

1. **Cohérence avec l'architecture existante**
   - Les watchdogs (`ops/*/watchdog.sh`) tournent déjà via cron sur l'hôte
   - Même approche = maintenance simplifiée

2. **Simplicité**
   - Pas besoin de modifier les Dockerfiles
   - Pas besoin d'un service cron dans le container
   - Installation automatique lors du déploiement

3. **Fiabilité**
   - Le cron sur l'hôte continue de fonctionner même si le container redémarre
   - Pas de dépendance au cycle de vie du container

4. **Performance**
   - Pas de surcharge dans le container web
   - Isolation des tâches planifiées

### ❌ Pourquoi pas dans le container ?

- Nécessite un service cron dans chaque container
- Plus complexe à maintenir
- Risque de duplication si plusieurs containers
- Moins portable entre environnements

## 🚀 Installation Automatique

### Lors du déploiement

Le crontab est **automatiquement installé/mis à jour** lors de chaque déploiement via `ops/deploy.sh` :

```bash
# Le script de déploiement appelle automatiquement :
install_crontab
```

**Emplacement dans le workflow** :
1. ✅ Build Docker
2. ✅ Migrations
3. ✅ Health checks
4. ✅ **Installation crontab** ← Ici
5. ✅ Validation finale

### Installation manuelle

Si besoin d'installer manuellement :

```bash
# Depuis la racine du projet
./ops/scripts/update-crontab.sh production
# ou
./ops/scripts/update-crontab.sh staging
```

### Via Rake task (depuis le container)

```bash
# Dans le container
docker exec grenoble-roller-prod bin/rails cron:update
```

## 📝 Configuration

Le crontab est généré depuis `config/schedule.rb` :

```ruby
# Job de rappel la veille à 19h pour les événements du lendemain
every 1.day, at: "7:00 pm" do
  runner "EventReminderJob.perform_now"
end
```

**Tâches configurées** :
- ⏰ Rappels événements : Tous les jours à 19h
- 💰 Sync HelloAsso : Toutes les 5 minutes
- 📅 Adhésions expirées : Tous les jours à minuit
- 📧 Rappels renouvellement : Tous les jours à 9h
- 👶 Autorisations parentales : Tous les lundis à 10h
- 🏥 Certificats médicaux : Tous les lundis à 10h30

## 🔍 Vérification

### Voir le crontab généré

```bash
# Depuis l'hôte
cd /chemin/vers/projet
bundle exec whenever
```

### Voir le crontab installé

```bash
# Sur l'hôte
crontab -l
```

### Vérifier les logs

Les logs des tâches cron sont dans `log/cron.log` (configuré dans `schedule.rb`).

## 🛠️ Maintenance

### Mettre à jour le crontab

Le crontab est automatiquement mis à jour lors de chaque déploiement. Si besoin manuel :

```bash
./ops/scripts/update-crontab.sh production
```

### Supprimer le crontab

```bash
# Depuis la racine du projet
bundle exec whenever --clear-crontab
```

### Modifier les tâches

1. Modifier `config/schedule.rb`
2. Commit et push
3. Déployer (le crontab sera mis à jour automatiquement)

## 🐛 Troubleshooting

### "bundle n'est pas disponible"

Le cron doit être installé sur l'hôte, pas dans le container. Vérifier que :
- Ruby et Bundler sont installés sur l'hôte
- Le Gemfile est accessible depuis l'hôte
- `bundle install` a été exécuté sur l'hôte

### "Crontab non installé après déploiement"

Vérifier les logs de déploiement :
```bash
tail -f logs/deploy-production.log | grep -i cron
```

Si l'installation échoue, le déploiement continue (warning seulement) pour ne pas bloquer.

### "Les rappels ne sont pas envoyés"

1. Vérifier que le crontab est installé : `crontab -l`
2. Vérifier les logs : `tail -f log/cron.log`
3. Tester manuellement : `docker exec grenoble-roller-prod bin/rails runner "EventReminderJob.perform_now"`

## 📚 Références

- [Whenever Gem](https://github.com/javan/whenever)
- [Cron Documentation](https://manpages.ubuntu.com/manpages/jammy/man5/crontab.5.html)
- [Docker Compose Best Practices](https://docs.docker.com/compose/production/)

## ✅ Checklist Déploiement

- [ ] Le crontab est installé automatiquement lors du déploiement
- [ ] Les logs sont dans `log/cron.log`
- [ ] Les tâches sont visibles avec `crontab -l`
- [ ] Les rappels fonctionnent (tester avec un événement du lendemain)

