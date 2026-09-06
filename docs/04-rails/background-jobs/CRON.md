# ⏰ Système Cron - Documentation Complète

**Date** : 2025-12-22  
**Dernière mise à jour** : 2026-08-14  
**Statut** : ✅ **Solid Queue actif** | ⚠️ Supercronic déprécié (migration terminée)  
**Version** : 2.0

---

## 📋 Vue d'Ensemble

Ce document décrit le système de tâches planifiées (jobs récurrents) de l'application Grenoble Roller, maintenant basé sur **Solid Queue** (Rails 8) avec `config/recurring.yml`.

### Architecture Actuelle (2025-01-13)

- **Solid Queue** : Gère tous les jobs récurrents via `config/recurring.yml`
- **Configuration** : `config/recurring.yml` (YAML, chargé automatiquement)
- **Monitoring** : Mission Control Jobs (`/admin-panel/jobs`)
- **Base de données** : PostgreSQL (tables `solid_queue_recurring_tasks`, `solid_queue_recurring_executions`)
- **Plugin Puma** : Solid Queue intégré dans Puma (`SOLID_QUEUE_IN_PUMA: true`)

### Architecture Ancienne (Dépréciée)

- ⚠️ **Supercronic** : Déprécié (migration terminée)
- ⚠️ **Whenever** : Déprécié (`config/schedule.rb` conservé pour référence)
- ⚠️ **Crontab** : Déprécié (`config/crontab` conservé pour référence)

---

## 📊 Tâches Cron Actuelles

| Tâche | Fréquence | Job | Utilité | Status |
|-------|-----------|-----|---------|--------|
| **Sync HelloAsso** | Toutes les 5 min | `SyncHelloAssoPaymentsJob` | Synchroniser les paiements HelloAsso | ✅ Actif (SolidQueue) |
| **Rappels événements** | Quotidien 19h | `EventReminderJob` | Rappels 24h avant événements | ✅ Actif (SolidQueue) |
| **Adhésions expirées** | Quotidien 00:00 | `UpdateExpiredMembershipsJob` | Marquer adhésions expirées | ✅ Actif (SolidQueue) |
| **Rappels renouvellement** | Quotidien 9h | `SendRenewalRemindersJob` | Rappels 30 jours avant expiration | ✅ Actif (SolidQueue) |
| **Nettoyage SolidQueue** | Toutes les heures | `clear_solid_queue_finished_jobs` | Nettoyer les jobs terminés | ✅ Actif (SolidQueue) |
| **Rapport initiation** | Sur demande | `InitiationParticipantsReportJob` | Rapport participants (créé automatiquement) | ✅ Actif |

### Détails des Tâches

#### 1. Sync HelloAsso Payments (`SyncHelloAssoPaymentsJob`)

**Fichier** : [`app/jobs/sync_hello_asso_payments_job.rb`](../../app/jobs/sync_hello_asso_payments_job.rb)  
**Fréquence** : Toutes les 5 minutes  
**Utilité** : Synchroniser les paiements HelloAsso depuis leur API pour activer automatiquement les adhésions payées.

**Configuration** (`config/recurring.yml`) :
```yaml
production:
  sync_helloasso_payments:
    class: SyncHelloAssoPaymentsJob
    queue: default
    schedule: every 5 minutes
```

**Caractéristiques** :
- Limite de concurrence : 1 instance à la fois (`limits_concurrency to: 1`)
- Traite uniquement les paiements des dernières 24h
- Gestion d'erreurs avec Sentry

---

#### 2. Rappels Événements (`EventReminderJob`)

**Fichier** : [`app/jobs/event_reminder_job.rb`](../../app/jobs/event_reminder_job.rb)  
**Fréquence** : Tous les jours à 19h  
**Utilité** : Envoyer des rappels par email 24h avant chaque événement aux participants qui ont coché "rappels".

**Configuration** (`config/recurring.yml`) :
```yaml
production:
  event_reminder:
    class: EventReminderJob
    queue: default
    schedule: every day at 7:00pm
```

**Filtres appliqués** :
- `wants_reminder: true` (préférence par inscription)
- Pour initiations : `wants_initiation_mail: true` (préférence globale utilisateur)
- Attendances actives uniquement (scope `.active`)
- Événements publiés et à venir uniquement
- Événements du lendemain uniquement

**Mailer** : `EventMailer.event_reminder(attendance)`

**Documentation complète** : Voir [`docs/04-rails/mailing/README.md`](../mailing/README.md#event_reminder)

---

#### 3. Rapport Participants Initiation (`InitiationParticipantsReportJob`)

**Fichier** : [`app/jobs/initiation_participants_report_job.rb`](../../app/jobs/initiation_participants_report_job.rb)  
**Fréquence** : Tous les jours à 7h (production uniquement)  
**Utilité** : Envoyer un rapport à `contact@grenoble-roller.org` avec la liste des participants et le matériel demandé pour chaque initiation du jour.

**Configuration** :
```ruby
every 1.day, at: "7:00 am" do
  runner 'InitiationParticipantsReportJob.perform_now'
end
```

**Note** : Timing à 7h le jour même car les personnes peuvent s'inscrire jusqu'à la dernière minute.

**Mailer** : `EventMailer.initiation_participants_report(initiation)`

**Documentation complète** : Voir [`docs/04-rails/mailing/README.md`](../mailing/README.md#initiation_participants_report)

---

#### 4. Adhésions Expirées (`memberships:update_expired`)

**Fichier** : [`lib/tasks/memberships.rake`](../../lib/tasks/memberships.rake)  
**Fréquence** : Tous les jours à minuit (00:00)  
**Utilité** : Marquer comme expirées les adhésions dont la date d'expiration est passée et envoyer un email de notification.

**Configuration** :
```ruby
every 1.day, at: "12:00 am" do
  runner 'Rails.application.load_tasks; Rake::Task["memberships:update_expired"].invoke'
end
```

**Actions** :
- Met à jour `status: 'expired'` pour les adhésions expirées
- Envoie `MembershipMailer.expired(membership)` pour chaque adhésion expirée

**Mailer** : `MembershipMailer.expired(membership)`

---

#### 5. Rappels Renouvellement (`memberships:send_renewal_reminders`)

**Fichier** : [`lib/tasks/memberships.rake`](../../lib/tasks/memberships.rake)  
**Fréquence** : Tous les jours à 9h  
**Utilité** : Envoyer des rappels aux membres dont l'adhésion expire dans 30 jours.

**Configuration** :
```ruby
every 1.day, at: "9:00 am" do
  runner 'Rails.application.load_tasks; Rake::Task["memberships:send_renewal_reminders"].invoke'
end
```

**Actions** :
- Filtre les adhésions expirant dans 30 jours
- Envoie `MembershipMailer.renewal_reminder(membership)` pour chaque adhésion

**Mailer** : `MembershipMailer.renewal_reminder(membership)`

---

## 🛠️ Configuration

### Fichier `config/schedule.rb`

Le fichier [`config/schedule.rb`](../../config/schedule.rb) définit toutes les tâches cron en utilisant la syntaxe DSL de **Whenever**.

**Syntaxe importante** :

```ruby
# ❌ ERREUR : Rails n'est pas chargé lors de la génération du crontab
every 1.day, at: "7:00 am" do
  runner "InitiationParticipantsReportJob.perform_now" if Rails.env.production?
end

# ✅ CORRECT : Vérification dans le job lui-même
every 1.day, at: "7:00 am" do
  runner 'InitiationParticipantsReportJob.perform_now'
end
```

**Pour les tâches Rake** :

```ruby
# ❌ ERREUR : Rake::Task n'est pas disponible sans chargement explicite
every 5.minutes do
  runner 'Rake::Task["helloasso:sync_payments"].invoke'
end

# ✅ CORRECT : Charger explicitement les tâches Rake
every 5.minutes do
  runner 'Rails.application.load_tasks; Rake::Task["helloasso:sync_payments"].invoke'
end
```

### Génération du Crontab

Le crontab est généré automatiquement lors du déploiement via [`ops/lib/deployment/cron.sh`](../../ops/lib/deployment/cron.sh) :

```bash
# Génération depuis le conteneur
bundle exec whenever --set 'environment=production' > config/crontab
```

**Emplacement** : `/rails/config/crontab` dans le conteneur (lu par Supercronic)

### Supercronic

**Supercronic** est un daemon cron-like conçu pour les conteneurs Docker. Il lit le fichier `/rails/config/crontab` et exécute les tâches selon la planification.

**Installation** : Déjà présent dans le Dockerfile (package système)

**Démarrage** : Démarre automatiquement avec le conteneur (voir `bin/docker-entrypoint`)

---

## 🚀 Déploiement

### Installation Automatique

Le crontab est **automatiquement installé/mis à jour** lors de chaque déploiement :

1. Build Docker
2. Migrations
3. Health checks
4. **Installation crontab** ← Ici
5. Validation finale

**Script** : [`ops/lib/deployment/cron.sh`](../../ops/lib/deployment/cron.sh) - fonction `install_crontab()`

### Installation Manuelle

Si besoin d'installer manuellement :

```bash
# Depuis la racine du projet
./ops/scripts/update-crontab.sh production
# ou
./ops/scripts/update-crontab.sh staging
```

---

## 🔍 Vérification et Dépannage

### Voir le crontab généré

```bash
# Depuis le conteneur
docker exec grenoble-roller-staging bundle exec whenever --set 'environment=staging'
```

### Voir le crontab installé

```bash
# Depuis le conteneur
docker exec grenoble-roller-staging cat /rails/config/crontab
```

### Vérifier que Supercronic tourne

```bash
# Vérifier les processus
docker exec grenoble-roller-staging ps aux | grep supercronic

# Vérifier les logs
docker exec grenoble-roller-staging tail -f log/cron.log
```

### Tester une tâche manuellement

```bash
# Tester EventReminderJob
docker exec grenoble-roller-staging bundle exec rails runner "EventReminderJob.perform_now"

# Tester une tâche Rake
docker exec grenoble-roller-staging bundle exec rails runner "Rails.application.load_tasks; Rake::Task['helloasso:sync_payments'].invoke"
```

### Problèmes Courants

#### ❌ "Échec de la génération du crontab"

**Cause** : Erreur dans `config/schedule.rb` (utilisation de `Rails.env` ou `Rake::Task` sans chargement)

**Solution** : Vérifier la syntaxe dans `config/schedule.rb` (voir section "Configuration")

#### ❌ "Supercronic ne tourne pas"

**Cause** : Supercronic n'est pas démarré ou le fichier `config/crontab` est absent/invalide

**Solution** :
```bash
# Vérifier que le conteneur tourne
docker ps | grep grenoble-roller

# Vérifier que le crontab existe
docker exec grenoble-roller-staging test -f /rails/config/crontab && echo "OK" || echo "Manquant"

# Relancer le déploiement
./ops/staging/deploy.sh
```

#### ❌ "Les emails automatiques ne sont pas envoyés"

**Cause** : Jobs cron ne s'exécutent pas ou erreurs dans les jobs

**Solution** :
1. Vérifier les logs : `docker exec grenoble-roller-staging tail -f log/cron.log`
2. Vérifier que Supercronic tourne (voir ci-dessus)
3. Tester manuellement le job (voir ci-dessus)

---

## ✅ Migration vers Solid Queue - TERMINÉE (2025-01-13)

### Migration Complétée

- ✅ Solid Queue configuré et actif
- ✅ Tous les jobs migrés vers `config/recurring.yml`
- ✅ Mission Control Jobs intégré (`/admin-panel/jobs`)
- ✅ Plugin Puma activé (`SOLID_QUEUE_IN_PUMA: true`)
- ✅ Base de données PostgreSQL configurée

### Configuration Actuelle

**`config/recurring.yml`** (✅ ACTIF) :
```yaml
production:
  clear_solid_queue_finished_jobs:
    command: "SolidQueue::Job.clear_finished_in_batches(sleep_between_batches: 0.3)"
    schedule: every hour at minute 12

  event_reminder:
    class: EventReminderJob
    queue: default
    schedule: every day at 7:00pm

  sync_helloasso_payments:
    class: SyncHelloAssoPaymentsJob
    queue: default
    schedule: every 5 minutes

  update_expired_memberships:
    class: UpdateExpiredMembershipsJob
    queue: default
    schedule: every day at 12:00am

  send_renewal_reminders:
    class: SendRenewalRemindersJob
    queue: default
    schedule: every day at 9:00am
```

**Configuration Solid Queue** :
- `config/environments/production.rb` : `config.active_job.queue_adapter = :solid_queue`
- `config/environments/staging.rb` : `config.active_job.queue_adapter = :solid_queue`
- `config/queue.yml` : Configuration workers/dispatchers
- `config/initializers/solid_queue.rb` : Configuration base de données

**Mission Control** : `/admin-panel/jobs` (dashboard web pour monitoring)

### Supercronic (Déprécié)

⚠️ **Supercronic n'est plus utilisé** :
- `config/schedule.rb` : Conservé pour référence (déprécié)
- `config/crontab` : Conservé pour référence (déprécié)
- `bin/docker-entrypoint` : Supercronic peut être retiré (non utilisé)

---

## 📚 Références

### Fichiers de Configuration

- [`config/recurring.yml`](../../config/recurring.yml) - Configuration Solid Queue (✅ ACTIF)
- [`config/queue.yml`](../../config/queue.yml) - Configuration workers/dispatchers Solid Queue
- [`config/initializers/solid_queue.rb`](../../config/initializers/solid_queue.rb) - Configuration base de données
- [`config/schedule.rb`](../../config/schedule.rb) - Configuration Whenever (⚠️ DÉPRÉCIÉ - conservé pour référence)
- [`config/crontab`](../../config/crontab) - Crontab généré (⚠️ DÉPRÉCIÉ - conservé pour référence)
- [`ops/lib/deployment/cron.sh`](../../ops/lib/deployment/cron.sh) - Script d'installation

### Scripts et Jobs

- [`ops/scripts/update-crontab.sh`](../../ops/scripts/update-crontab.sh) - Installation manuelle crontab
- [`app/jobs/event_reminder_job.rb`](../../app/jobs/event_reminder_job.rb) - EventReminderJob
- [`app/jobs/initiation_participants_report_job.rb`](../../app/jobs/initiation_participants_report_job.rb) - InitiationParticipantsReportJob
- [`lib/tasks/helloasso.rake`](../../lib/tasks/helloasso.rake) - Tâche sync HelloAsso
- [`lib/tasks/memberships.rake`](../../lib/tasks/memberships.rake) - Tâches adhésions

### Documentation

- [`docs/04-rails/mailing/README.md`](../mailing/README.md) - Documentation complète système de mailing
- [`docs/09-product/deployment-cron.md`](../../09-product/deployment-cron.md) - Documentation déploiement cron (ancienne)

### Liens Externes

- [Whenever Gem](https://github.com/javan/whenever) - Documentation Whenever
- [Supercronic](https://github.com/aptible/supercronic) - Documentation Supercronic
- [Solid Queue](https://github.com/rails/solid_queue) - Documentation Solid Queue
- [Mission Control Jobs](https://github.com/rails/mission_control-jobs) - Documentation Mission Control

---

## ✅ Checklist Vérification Solid Queue

- [x] Solid Queue configuré (`config.active_job.queue_adapter = :solid_queue`)
- [x] `config/recurring.yml` créé avec tous les jobs
- [x] Mission Control Jobs intégré (`/admin-panel/jobs`)
- [x] Plugin Puma activé (`SOLID_QUEUE_IN_PUMA: true`)
- [ ] Vérifier que les jobs récurrents sont chargés : `SolidQueue::RecurringTask.count` (doit retourner 5)
- [ ] Vérifier Mission Control dashboard : `/admin-panel/jobs`
- [ ] Tester manuellement un job : `EventReminderJob.perform_now`
- [ ] Vérifier les logs Solid Queue dans les logs Rails

---

**Retour** : [README racine](../../../README.md)
