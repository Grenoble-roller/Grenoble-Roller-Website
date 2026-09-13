# 📧 Système de Mailing Automatique - Documentation Complète

**Date** : 2025-12-20  
**Dernière mise à jour** : 2025-01-13  
**Statut** : ✅ Documentation complète + ✅ Corrections critiques implémentées (Points 1, 2, 11) + ✅ **SolidQueue actif** - Tous les jobs récurrents migrés et fonctionnels  
**Version** : 2.5

---

## 📋 Vue d'Ensemble

Ce document décrit **l'ensemble du système de mailing automatique** de l'application Grenoble Roller, incluant :
- Les mailers et leurs méthodes
- Les jobs automatiques (rappels, renouvellements)
- Les préférences utilisateur
- La configuration SMTP
- Les templates et leur structure
- Les tests et la sécurité

---

## 🏗️ Architecture Générale

### Mailers Disponibles

| Mailer | Nombre d'emails | Domaine | Status |
|--------|----------------|---------|--------|
| **EventMailer** | 5 | Événements & Initiations | ✅ Complet |
| **OrderMailer** | 7 | E-commerce (Commandes) | ✅ Complet |
| **MembershipMailer** | 4 | Adhésions | ✅ Complet |
| **UserMailer** | 1 | Utilisateurs | ✅ Complet |
| **DeviseMailer** | 1 | Authentification | ✅ Complet |
| **TOTAL** | **18** | - | ✅ **100%** |

### Jobs Automatiques

| Job | Fréquence | Domaine | Système | Status |
|-----|-----------|---------|---------|--------|
| **EventReminderJob** | Quotidien (19h) | Rappels événements | SolidQueue recurring.yml | ✅ **ACTIF** (config/recurring.yml) |
| **SyncHelloAssoPaymentsJob** | Toutes les 5 min | Paiements | SolidQueue recurring.yml | ✅ **ACTIF** (config/recurring.yml) |
| **UpdateExpiredMembershipsJob** | Quotidien (00h) | Adhésions expirées | SolidQueue recurring.yml | ✅ **ACTIF** (config/recurring.yml) |
| **SendRenewalRemindersJob** | Quotidien (09h) | Rappels renouvellement | SolidQueue recurring.yml | ✅ **ACTIF** (config/recurring.yml) |
| **InitiationParticipantsReportJob** | Sur demande | Rapport participants | SolidQueue (créé automatiquement) | ✅ **ACTIF** (créé à la publication) |
| **clear_solid_queue_finished_jobs** | Toutes les heures | Nettoyage SolidQueue | SolidQueue recurring.yml | ✅ **ACTIF** (config/recurring.yml) |

**✅ SYSTÈME VÉRIFIÉ** : Tous les points "À VÉRIFIER" ont été vérifiés avec tous les liens vers fichiers, variables et logiques.

**🚨 AUDIT CRITIQUE** : 14 points identifiés (3 critiques ✅ TERMINÉS, 1 🚨 CRITIQUE URGENT, 5 à vérifier, 6 améliorations). Voir **Section 12** pour détails complets et **Section 20** pour plan d'action priorisé.

**✅ CORRECTIONS IMPLÉMENTÉES** :
- ✅ Point 1 : Rake tasks `deliver_now` → `deliver_later` (TERMINÉ)
- ✅ Point 2 : Flags de suivi ajoutés + code modifié (TERMINÉ)
- ✅ Point 11 : Timezone configuré `Europe/Paris` (TERMINÉ)
- ✅ Bonus : Cohérence `update_column`, `Rails.logger`, monitoring Sentry (TERMINÉ)

**✅ SolidQueue configuré pour jobs récurrents** :
- ✅ **Point 3** : **SolidQueue** gère maintenant TOUS les jobs récurrents via `config/recurring.yml`
- ✅ `EventReminderJob` configuré dans `config/recurring.yml` (19h quotidien)
- ✅ `SyncHelloAssoPaymentsJob` configuré dans `config/recurring.yml` (toutes les 5 minutes)
- ✅ `UpdateExpiredMembershipsJob` configuré dans `config/recurring.yml` (minuit quotidien)
- ✅ `SendRenewalRemindersJob` configuré dans `config/recurring.yml` (9h quotidien)
- ✅ `clear_solid_queue_finished_jobs` configuré dans `config/recurring.yml` (toutes les heures)
- ✅ **Migration terminée** : Tous les jobs sont maintenant dans Solid Queue, Supercronic est déprécié
- **Voir Section 12.3** pour architecture complète et [`docs/04-rails/background-jobs/CRON.md`](../background-jobs/CRON.md) pour documentation complète

---

## 🚨 Résumé Rapide - Points Critiques

| Priorité | Point | Fichier | Action | Section |
|----------|-------|---------|--------|---------|
| 🔴 **CRITIQUE** | Rake tasks `deliver_now` | [`lib/tasks/memberships.rake`](../lib/tasks/memberships.rake) | Changer en `deliver_later` | 12.1 |
| 🔴 **CRITIQUE** | Flags de suivi manquants | [`db/schema.rb`](../db/schema.rb) | Ajouter 3 migrations | 12.2 |
| ✅ **RÉSOLU** | Architecture SolidQueue/Supercronic | [`config/recurring.yml`](../config/recurring.yml) | ✅ SolidQueue utilise recurring.yml | 12.3 |
| 🟡 **IMPORTANT** | Scope `active` inclut `no_show` | [`app/models/attendance.rb`](../app/models/attendance.rb) | Clarifier règle métier | 12.5 |
| 🟡 **IMPORTANT** | Timezone non configuré | [`config/application.rb`](../config/application.rb) | Configurer `Europe/Paris` | 12.11 |

**Voir Section 12** pour détails complets de chaque point critique.

---

## 📧 1. EventMailer - Emails Événements & Initiations

**Fichier** : [`app/mailers/event_mailer.rb`](../app/mailers/event_mailer.rb)

### 1.1. Méthodes Disponibles

#### ✅ `attendance_confirmed(attendance)`
**Sujet** : `✅ Inscription confirmée : [Titre]` ou `✅ Inscription confirmée - Initiation roller samedi [Date]`

**Fichier mailer** : [`app/mailers/event_mailer.rb`](../app/mailers/event_mailer.rb) (lignes 3-19)

**Déclencheur** :
- Inscription à un événement ou initiation
- **Appels dans le code** :
  - [`app/controllers/events/attendances_controller.rb`](../app/controllers/events/attendances_controller.rb) (ligne 56) - `EventMailer.attendance_confirmed(attendance).deliver_later`
  - [`app/controllers/initiations/attendances_controller.rb`](../app/controllers/initiations/attendances_controller.rb) (lignes 68, 223) - `EventMailer.attendance_confirmed(attendance).deliver_later if current_user.wants_initiation_mail?`
  - [`app/controllers/events/waitlist_entries_controller.rb`](../app/controllers/events/waitlist_entries_controller.rb) (ligne 117) - `EventMailer.attendance_confirmed(pending_attendance.reload).deliver_later if current_user.wants_events_mail?`
  - [`app/controllers/initiations/waitlist_entries_controller.rb`](../app/controllers/initiations/waitlist_entries_controller.rb) (ligne 118) - `EventMailer.attendance_confirmed(pending_attendance.reload).deliver_later if current_user.wants_initiation_mail?`

**Templates** :
- HTML : [`app/views/event_mailer/attendance_confirmed.html.erb`](../app/views/event_mailer/attendance_confirmed.html.erb)
- Text : [`app/views/event_mailer/attendance_confirmed.text.erb`](../app/views/event_mailer/attendance_confirmed.text.erb)

**Variables disponibles** :
- `@attendance` : Objet [`Attendance`](../app/models/attendance.rb)
- `@event` : Événement concerné (via `attendance.event`)
- `@user` : Utilisateur participant (via `attendance.user`)
- `@is_initiation` : Boolean (initiation ou événement général) - calculé ligne 7 : `@event.is_a?(Event::Initiation)`

**Logique conditionnelle** :
- Pour initiations : vérifie `current_user.wants_initiation_mail?` avant envoi (voir [`app/controllers/initiations/attendances_controller.rb`](../app/controllers/initiations/attendances_controller.rb) ligne 222)
- Pour événements généraux : vérifie `current_user.wants_events_mail?` avant envoi (voir [`app/controllers/events/waitlist_entries_controller.rb`](../app/controllers/events/waitlist_entries_controller.rb) ligne 117)

**Contenu** :
- Détails de l'événement (titre, date, lieu, horaire)
- Informations pratiques (route, prix, places)
- Lien vers la page de l'événement
- Rappel possibilité d'annulation

**Références** :
- Documentation : [`docs/06-events/event-reminder-job.md`](../../06-events/event-reminder-job.md)

---

#### ✅ `attendance_cancelled(user, event)`
**Sujet** : `❌ Désinscription confirmée : [Titre]` ou `❌ Désinscription confirmée - Initiation roller samedi [Date]`

**Fichier mailer** : [`app/mailers/event_mailer.rb`](../app/mailers/event_mailer.rb) (lignes 22-37)

**Déclencheur** :
- Désinscription d'un événement ou initiation
- **Appels dans le code** :
  - [`app/controllers/events/attendances_controller.rb`](../app/controllers/events/attendances_controller.rb) (ligne 98) - `EventMailer.attendance_cancelled(current_user, @event).deliver_later` (conditionné par `wants_events_mail` et `attendance.for_parent?`)
  - [`app/controllers/initiations/attendances_controller.rb`](../app/controllers/initiations/attendances_controller.rb) (ligne 277) - `EventMailer.attendance_cancelled(current_user, @initiation).deliver_later` (conditionné par `wants_initiation_mail` et `attendance.for_parent?`)

**Templates** :
- HTML : [`app/views/event_mailer/attendance_cancelled.html.erb`](../app/views/event_mailer/attendance_cancelled.html.erb)
- Text : [`app/views/event_mailer/attendance_cancelled.text.erb`](../app/views/event_mailer/attendance_cancelled.text.erb)

**Variables disponibles** :
- `@user` : Utilisateur (paramètre `user`)
- `@event` : Événement concerné (paramètre `event`)
- `@is_initiation` : Boolean - calculé ligne 25 : `@event.is_a?(Event::Initiation)`

**Logique conditionnelle** :
- Pour initiations : vérifie `wants_initiation_mail` ET `attendance.for_parent?` avant envoi (voir [`app/controllers/initiations/attendances_controller.rb`](../app/controllers/initiations/attendances_controller.rb) lignes 273-277)
- Pour événements généraux : vérifie `wants_events_mail` ET `attendance.for_parent?` avant envoi (voir [`app/controllers/events/attendances_controller.rb`](../app/controllers/events/attendances_controller.rb) lignes 93-98)
- **Note** : Les emails d'annulation ne sont envoyés QUE pour les parents (`for_parent?`), pas pour les enfants

**Contenu** :
- Confirmation de désinscription
- Détails de l'événement
- Lien vers la page de l'événement
- Rappel possibilité de se réinscrire

---

#### ✅ `event_reminder(attendance)`
**Sujet** : `📅 Rappel : [Titre] demain !` ou `📅 Rappel : Initiation roller demain samedi [Date]`

**Fichier mailer** : [`app/mailers/event_mailer.rb`](../app/mailers/event_mailer.rb) (lignes 40-56)

**Déclencheur** :
- **Job automatique** : [`EventReminderJob`](../app/jobs/event_reminder_job.rb) (tous les jours à **19h00**)
- **Appel dans le code** : [`app/jobs/event_reminder_job.rb`](../app/jobs/event_reminder_job.rb) (ligne 36) - `EventMailer.event_reminder(attendance).deliver_later`
- Envoie un rappel la veille (à 19h) pour les **événements ET initiations** du lendemain
- **Participants concernés** : Parents ET enfants qui ont demandé des rappels (`wants_reminder: true`)

**Templates** :
- HTML : [`app/views/event_mailer/event_reminder.html.erb`](../app/views/event_mailer/event_reminder.html.erb)
- Text : [`app/views/event_mailer/event_reminder.text.erb`](../app/views/event_mailer/event_reminder.text.erb)

**Variables disponibles** :
- `@attendance` : Objet [`Attendance`](../app/models/attendance.rb) (paramètre `attendance`)
- `@event` : Événement concerné (via `attendance.event`, ligne 42)
- `@user` : Utilisateur participant (via `attendance.user`, ligne 43)
- `@is_initiation` : Boolean - calculé ligne 44 : `@event.is_a?(Event::Initiation)`

**Filtres appliqués dans EventReminderJob** :
- ✅ `wants_reminder: true` (préférence par inscription) - voir [`app/jobs/event_reminder_job.rb`](../app/jobs/event_reminder_job.rb) ligne 22
- ✅ Pour initiations : `wants_initiation_mail: true` (préférence globale utilisateur) - voir [`app/jobs/event_reminder_job.rb`](../app/jobs/event_reminder_job.rb) lignes 28-30
- ✅ Attendances actives uniquement (scope `.active` exclut `canceled` mais **INCLUT `no_show`**) - voir [`app/jobs/event_reminder_job.rb`](../app/jobs/event_reminder_job.rb) ligne 21
  - ⚠️ **À VÉRIFIER** : Le scope `active` inclut `no_show` - est-ce voulu ? Voir Section 12.5
- ✅ Événements publiés uniquement (scope `.published`) - voir [`app/jobs/event_reminder_job.rb`](../app/jobs/event_reminder_job.rb) ligne 13
- ✅ Événements à venir uniquement (scope `.upcoming`) - voir [`app/jobs/event_reminder_job.rb`](../app/jobs/event_reminder_job.rb) ligne 14
- ✅ Événements du lendemain uniquement (filtre `start_at: tomorrow_start..tomorrow_end`) - voir [`app/jobs/event_reminder_job.rb`](../app/jobs/event_reminder_job.rb) lignes 9-10, 15
- ✅ Utilisateur avec email valide - voir [`app/jobs/event_reminder_job.rb`](../app/jobs/event_reminder_job.rb) ligne 26

**Logique de filtrage** :
- Le job filtre les attendances avec `wants_reminder: true` (champ dans [`app/models/attendance.rb`](../app/models/attendance.rb) ligne 73 du schema)
- **Parents ET enfants** : Le job traite toutes les attendances (parents avec `child_membership_id: nil` ET enfants avec `child_membership_id: present`)
- Chaque attendance a son propre flag `wants_reminder`, donc :
  - Si un parent s'inscrit et coche "rappels" → il recevra un email
  - Si un enfant est inscrit et le parent coche "rappels" pour cet enfant → l'attendance de l'enfant recevra un email
- Pour les initiations, vérifie aussi `user.wants_initiation_mail?` (préférence globale utilisateur - voir [`app/models/user.rb`](../app/models/user.rb), migration [`db/migrate/20251201020755_add_email_preferences_to_users.rb`](../db/migrate/20251201020755_add_email_preferences_to_users.rb))
- **Note importante** : Le champ `is_volunteer` n'est **PAS** utilisé dans le filtrage - bénévoles et participants reçoivent le même email s'ils ont coché "rappels"

**Références** :
- Job : [`app/jobs/event_reminder_job.rb`](../app/jobs/event_reminder_job.rb)
- Modèle Attendance : [`app/models/attendance.rb`](../app/models/attendance.rb) (scope `.active` ligne 45, champ `wants_reminder` ligne 73)
- Modèle User : [`app/models/user.rb`](../app/models/user.rb) (méthode `wants_initiation_mail?`)
- Documentation complète : [`docs/06-events/event-reminder-job.md`](../../06-events/event-reminder-job.md)

---

#### ✅ `event_rejected(event)`
**Sujet** : `❌ Votre événement "[Titre]" a été refusé` ou `❌ Votre initiation a été refusée`

**Fichier mailer** : [`app/mailers/event_mailer.rb`](../app/mailers/event_mailer.rb) (lignes 59-74)

**Déclencheur** :
- Refus d'un événement par un modérateur/admin
- **Appel dans le code** : [`app/controllers/events_controller.rb`](../app/controllers/events_controller.rb) (ligne 237) - `EventMailer.event_rejected(@event).deliver_later`
- Action `reject` dans [`app/controllers/events_controller.rb`](../app/controllers/events_controller.rb)

**Templates** :
- HTML : [`app/views/event_mailer/event_rejected.html.erb`](../app/views/event_mailer/event_rejected.html.erb)
- Text : [`app/views/event_mailer/event_rejected.text.erb`](../app/views/event_mailer/event_rejected.text.erb)

**Variables disponibles** :
- `@event` : Événement refusé (paramètre `event`)
- `@creator` : Créateur de l'événement (via `event.creator_user`, ligne 61)
- `@is_initiation` : Boolean - calculé ligne 62 : `@event.is_a?(Event::Initiation)`

**Contenu** :
- Notification de refus
- Raison du refus (si disponible)
- Instructions pour modification

**Références** :
- Controller : [`app/controllers/events_controller.rb`](../app/controllers/events_controller.rb) (action `reject`)

---

#### ✅ `waitlist_spot_available(waitlist_entry)`
**Sujet** : `🎉 Place disponible : [Titre]` ou `🎉 Place disponible - Initiation roller samedi [Date]`

**Fichier mailer** : [`app/mailers/event_mailer.rb`](../app/mailers/event_mailer.rb) (lignes 77-95)

**Déclencheur** :
- Une place se libère dans un événement complet
- **Appel dans le code** : [`app/models/waitlist_entry.rb`](../app/models/waitlist_entry.rb) (ligne 231) - `EventMailer.waitlist_spot_available(self).deliver_now`
- Méthode `send_notification_email` dans [`app/models/waitlist_entry.rb`](../app/models/waitlist_entry.rb) (lignes 229-234)
- **Note importante** : Utilise `deliver_now` (pas `deliver_later`) car notification time-sensitive (24h pour confirmer)

**Templates** :
- HTML : [`app/views/event_mailer/waitlist_spot_available.html.erb`](../app/views/event_mailer/waitlist_spot_available.html.erb)
- Text : [`app/views/event_mailer/waitlist_spot_available.text.erb`](../app/views/event_mailer/waitlist_spot_available.text.erb)

**Variables disponibles** :
- `@waitlist_entry` : Entrée liste d'attente (paramètre `waitlist_entry`)
- `@event` : Événement concerné (via `waitlist_entry.event`, ligne 79)
- `@user` : Utilisateur en liste d'attente (via `waitlist_entry.user`, ligne 80)
- `@is_initiation` : Boolean - calculé ligne 81 : `@event.is_a?(Event::Initiation)`
- `@participant_name` : Nom du participant (parent ou enfant) - via `waitlist_entry.participant_name`, ligne 82
- `@expiration_time` : Date limite de confirmation (24h) - calculé ligne 83 : `waitlist_entry.notified_at + 24.hours`

**Logique de notification** :
- Appelé depuis `WaitlistEntry.notify_next_in_queue` (méthode de classe dans [`app/models/waitlist_entry.rb`](../app/models/waitlist_entry.rb))
- Déclenché automatiquement quand une place se libère (voir [`app/models/attendance.rb`](../app/models/attendance.rb) lignes 295-312, callback `notify_waitlist_if_needed`)

**Contenu** :
- Notification place disponible
- Lien pour confirmer l'inscription
- Date limite (24h pour confirmer)
- Instructions

**Références** :
- Modèle WaitlistEntry : [`app/models/waitlist_entry.rb`](../app/models/waitlist_entry.rb) (méthode `send_notification_email` ligne 229)
- Modèle Attendance : [`app/models/attendance.rb`](../app/models/attendance.rb) (callback `notify_waitlist_if_needed` ligne 295)
- Documentation waitlist : [`docs/06-events/waitlist-system.md`](../../06-events/waitlist-system.md)

---

#### ✅ `initiation_participants_report(initiation)` - IMPLÉMENTÉ

**Sujet** : `Rapport participants - Initiation [Date]`

**Fichier mailer** : [`app/mailers/event_mailer.rb`](../app/mailers/event_mailer.rb) (lignes 97-115) ✅ **IMPLÉMENTÉ**

**Déclencheur** :
- **Job automatique** : [`InitiationParticipantsReportJob`](../app/jobs/initiation_participants_report_job.rb) (tous les jours à 7h, uniquement en production)
- **Appel dans le code** : [`app/jobs/initiation_participants_report_job.rb`](../app/jobs/initiation_participants_report_job.rb) (ligne 31) ✅ **IMPLÉMENTÉ** - `EventMailer.initiation_participants_report(initiation).deliver_later`
- Envoie un rapport le matin à 7h pour chaque initiation du jour

**Templates** :
- HTML : [`app/views/event_mailer/initiation_participants_report.html.erb`](../app/views/event_mailer/initiation_participants_report.html.erb) ✅ **CRÉÉ**
- Text : [`app/views/event_mailer/initiation_participants_report.text.erb`](../app/views/event_mailer/initiation_participants_report.text.erb) ✅ **CRÉÉ**

**Variables disponibles** :
- `@initiation` : Objet [`Event::Initiation`](../app/models/event/initiation.rb) (paramètre `initiation`)
- `@participants` : Liste des participants actifs (non bénévoles, non annulés) - via `initiation.attendances.active.participants.includes(:user, :child_membership)`
- `@participants_with_equipment` : Participants qui demandent du matériel - filtré depuis `@participants` avec `needs_equipment? && roller_size.present?`

**Logique** :
- Destinataire : `contact@grenoble-roller.org` (hardcodé dans le mailer)
- Uniquement en production (vérification dans le job)
- Uniquement les jours où il y a une initiation (filtre dans le job)
- Liste tous les participants avec leur nom, email, type (adulte/enfant), matériel demandé, pointure

**Contenu** :
- Détails de l'initiation (titre, date, lieu)
- Tableau des participants (nom, email, type, matériel, pointure)
- Résumé du matériel demandé par pointure

**Références** :
- Job : [`app/jobs/initiation_participants_report_job.rb`](../app/jobs/initiation_participants_report_job.rb) ✅ **IMPLÉMENTÉ**
- Mailer : [`app/mailers/event_mailer.rb`](../app/mailers/event_mailer.rb) (méthode `initiation_participants_report` lignes 97-115) ✅ **IMPLÉMENTÉ**
- Voir Section 7.5 pour détails complets de l'implémentation

---

### 1.2. Job Automatique : EventReminderJob

**Fichier** : [`app/jobs/event_reminder_job.rb`](../app/jobs/event_reminder_job.rb)

#### Logique Métier

**Code complet** : [`app/jobs/event_reminder_job.rb`](../app/jobs/event_reminder_job.rb) (lignes 7-37)

```ruby
# 1. Calcul fenêtre temporelle "demain"
tomorrow_start = Time.zone.now.beginning_of_day + 1.day  # Ligne 9
tomorrow_end = tomorrow_start.end_of_day                  # Ligne 10

# 2. Récupération événements publiés du lendemain
events = Event.published                                    # Ligne 13 - scope défini dans Event model
              .upcoming                                     # Ligne 14 - scope défini dans Event model
              .where(start_at: tomorrow_start..tomorrow_end) # Ligne 15 - filtre temporel

# 3. Pour chaque événement
events.find_each do |event|                                # Ligne 17
  is_initiation = event.is_a?(Event::Initiation)          # Ligne 18
  
  # 4. Récupération participants actifs avec rappel activé
  event.attendances.active                                  # Ligne 21 - scope défini dans Attendance model (ligne 45)
       .where(wants_reminder: true)                         # Ligne 22 - filtre préférence (champ dans schema ligne 73)
       .includes(:user, :event)                              # Ligne 23 - eager loading pour performance
       .find_each do |attendance|                          # Ligne 24
    # 5. Vérifications
    next unless attendance.user&.email.present?            # Ligne 26 - vérification email valide
    
    # 6. Pour initiations : vérifier préférence globale
    if is_initiation && !attendance.user.wants_initiation_mail?  # Lignes 28-30
      next # Skip si l'utilisateur a désactivé les emails d'initiations
    end
    
    # 7. Envoi email
    EventMailer.event_reminder(attendance).deliver_later   # Ligne 34
  end
end
```

**Références des scopes utilisés** :
- `Event.published` : Scope défini dans [`app/models/event.rb`](../app/models/event.rb) (ligne 96 : `.where(status: "published")`)
- `Event.upcoming` : Scope défini dans [`app/models/event.rb`](../app/models/event.rb) (ligne 94 : `.where("start_at > ?", Time.current)`)
- `Attendance.active` : Scope défini dans [`app/models/attendance.rb`](../app/models/attendance.rb) (ligne 45 : `.where.not(status: "canceled")`)

#### Configuration Cron

**✅ SYSTÈME ACTIF : Solid Queue** (Rails 8)

**Configuration** : [`config/recurring.yml`](../../config/recurring.yml)

```yaml
production:
  event_reminder:
    class: EventReminderJob
    queue: default
    schedule: every day at 7:00pm
```

**Exécution** : Solid Queue charge automatiquement `config/recurring.yml` au démarrage et exécute les jobs selon leur schedule.

**⚠️ Supercronic déprécié** :
- [`config/schedule.rb`](../../config/schedule.rb) : Conservé pour référence uniquement
- [`config/crontab`](../../config/crontab) : Conservé pour référence uniquement
- Migration terminée vers Solid Queue

**✅ VÉRIFICATION - Si les rappels ne fonctionnent pas** :

1. **Vérifier que les jobs récurrents sont chargés** :
```bash
docker exec grenoble-roller-production bin/rails runner "puts SolidQueue::RecurringTask.count"
# Doit retourner 5 (nombre de jobs configurés)
```

2. **Vérifier les jobs récurrents enregistrés** :
```bash
docker exec grenoble-roller-production bin/rails runner "SolidQueue::RecurringTask.all.each { |t| puts \"#{t.key}: #{t.schedule}\" }"
```

3. **Tester manuellement le job** :
```bash
docker exec grenoble-roller-production bin/rails runner "EventReminderJob.perform_now"
```

4. **Vérifier les logs Solid Queue** :
```bash
# Logs de l'application (Solid Queue est intégré dans Puma)
docker logs grenoble-roller-production | grep -i "EventReminderJob"
```

**Références** :
- Documentation jobs récurrents : [`docs/04-rails/background-jobs/CRON.md`](../background-jobs/CRON.md)
- Script installation : [`ops/lib/deployment/cron.sh`](../../ops/lib/deployment/cron.sh)
- Docker entrypoint : [`bin/docker-entrypoint`](../../bin/docker-entrypoint)
- Documentation déploiement : [`docs/09-product/deployment-cron.md`](../../09-product/deployment-cron.md)

#### Préférences Utilisateur

**Champ `wants_reminder` (Attendance)** :
- **Type** : Boolean
- **Défaut** : `false` (voir [`db/schema.rb`](../db/schema.rb) table `attendances` ligne 73 : `default: false, null: false`)
- **Usage** : Préférence par inscription (chaque inscription peut avoir sa propre préférence)
- **Modèle** : [`app/models/attendance.rb`](../app/models/attendance.rb)
- **Migration** : Champ présent dans le schema (voir [`db/schema.rb`](../db/schema.rb) ligne 73)
- **Formulaire** : Case à cocher dans [`app/views/shared/_registration_form_fields.html.erb`](../app/views/shared/_registration_form_fields.html.erb) (ligne 616) - coché par défaut (`checked: true`)
- **Utilisation** :
  - Filtré dans [`EventReminderJob`](../app/jobs/event_reminder_job.rb) (ligne 22) : `.where(wants_reminder: true)`
  - Peut être modifié via action `toggle_reminder` dans [`app/controllers/events/attendances_controller.rb`](../app/controllers/events/attendances_controller.rb) (lignes 110-132) et [`app/controllers/initiations/attendances_controller.rb`](../app/controllers/initiations/attendances_controller.rb) (lignes 289-311)

**Champ `wants_initiation_mail` (User)** :
- **Type** : Boolean
- **Défaut** : `true` (voir [`db/migrate/20251201020755_add_email_preferences_to_users.rb`](../db/migrate/20251201020755_add_email_preferences_to_users.rb) ligne 3 : `default: true, null: false`)
- **Usage** : Préférence globale pour les initiations uniquement
- **Modèle** : [`app/models/user.rb`](../app/models/user.rb)
- **Migration** : [`db/migrate/20251201020755_add_email_preferences_to_users.rb`](../db/migrate/20251201020755_add_email_preferences_to_users.rb) (ligne 3)
- **Schema** : [`db/schema.rb`](../db/schema.rb) table `users` (champ `wants_initiation_mail`)
- **Formulaire** : Case à cocher dans [`app/views/devise/registrations/edit.html.erb`](../app/views/devise/registrations/edit.html.erb) (ligne 191) - "Emails initiations et randos"
- **Application** : Uniquement pour `Event::Initiation`
- **Utilisation** :
  - Filtré dans [`EventReminderJob`](../app/jobs/event_reminder_job.rb) (lignes 28-30) : `if is_initiation && !attendance.user.wants_initiation_mail?`
  - Filtré dans [`app/controllers/initiations/attendances_controller.rb`](../app/controllers/initiations/attendances_controller.rb) (lignes 68, 222) : `if current_user.wants_initiation_mail?`
  - Filtré dans [`app/controllers/initiations/waitlist_entries_controller.rb`](../app/controllers/initiations/waitlist_entries_controller.rb) (ligne 118) : `if current_user.wants_initiation_mail?`

#### Tests

**Fichier** : [`spec/jobs/event_reminder_job_spec.rb`](../spec/jobs/event_reminder_job_spec.rb)

**Scénarios testés** (voir [`spec/jobs/event_reminder_job_spec.rb`](../spec/jobs/event_reminder_job_spec.rb)) :
- ✅ Envoie rappels pour événements du lendemain
- ✅ Ne envoie pas si `wants_reminder = false` (champ dans [`app/models/attendance.rb`](../app/models/attendance.rb))
- ✅ Ne envoie pas si événement pas published (scope `Event.published` dans [`app/models/event.rb`](../app/models/event.rb) ligne 96)
- ✅ Ne envoie pas si pas d'email utilisateur (vérification ligne 26 dans [`app/jobs/event_reminder_job.rb`](../app/jobs/event_reminder_job.rb))
- ✅ Pour initiations : respecte `wants_initiation_mail` (filtre lignes 28-30 dans [`app/jobs/event_reminder_job.rb`](../app/jobs/event_reminder_job.rb))
- ✅ N'envoie pas si événement passé (scope `Event.upcoming` dans [`app/models/event.rb`](../app/models/event.rb) ligne 94)
- ✅ N'envoie pas si événement pas demain (filtre temporel lignes 9-10, 15 dans [`app/jobs/event_reminder_job.rb`](../app/jobs/event_reminder_job.rb))
- ✅ Traite uniquement attendances actives (scope `Attendance.active` dans [`app/models/attendance.rb`](../app/models/attendance.rb) ligne 45)

**Exécution** :
```bash
bundle exec rspec spec/jobs/event_reminder_job_spec.rb
```

#### Utilisation Manuelle

```ruby
# Rails console
EventReminderJob.perform_now

# Terminal
bundle exec rails runner "EventReminderJob.perform_now"
```

---

### 1.3. ✅ Rappels Bénévoles - Vérifié

**Statut** : ✅ **VÉRIFIÉ**

**Résultat** : Les bénévoles reçoivent le **même email** que les participants.

**Code actuel** :
- `EventReminderJob` filtre par `wants_reminder: true` et `wants_initiation_mail` (pour initiations)
- **Aucune distinction** entre bénévoles (`is_volunteer: true`) et participants dans le job
- Les bénévoles avec `wants_reminder: true` reçoivent exactement le même email `event_reminder` que les participants
- Le champ `is_volunteer` n'est **pas utilisé** dans `EventReminderJob`

**Fichier vérifié** : [`app/jobs/event_reminder_job.rb`](../app/jobs/event_reminder_job.rb) (lignes 20-34)

**Conclusion** :
- ✅ **Comportement actuel** : Bénévoles = même rappel que participants
- ⚠️ **Recommandation** : Si besoin de rappels spécifiques bénévoles, créer `volunteer_reminder(attendance)` dans `EventMailer` et adapter `EventReminderJob`

**Références** :
- Modèle Attendance : [`app/models/attendance.rb`](../app/models/attendance.rb) (champ `is_volunteer`)
- EventReminderJob : [`app/jobs/event_reminder_job.rb`](../app/jobs/event_reminder_job.rb)

---

## 📦 2. OrderMailer - Emails Commandes

**Fichier** : [`app/mailers/order_mailer.rb`](../app/mailers/order_mailer.rb)

### 2.1. Méthodes Disponibles

#### ✅ `order_confirmation(order)`
**Sujet** : `✅ Commande #X - Confirmation de commande`

**Fichier mailer** : [`app/mailers/order_mailer.rb`](../app/mailers/order_mailer.rb) (lignes 5-13)

**Déclencheur** :
- Création d'une commande (statut `pending`)
- **Appel dans le code** : [`app/controllers/orders_controller.rb`](../app/controllers/orders_controller.rb) (ligne 76) - `OrderMailer.order_confirmation(order).deliver_later`

**Templates** :
- HTML : [`app/views/order_mailer/order_confirmation.html.erb`](../app/views/order_mailer/order_confirmation.html.erb)
- Text : [`app/views/order_mailer/order_confirmation.text.erb`](../app/views/order_mailer/order_confirmation.text.erb)

**Variables disponibles** :
- `@order` : Objet [`Order`](../app/models/order.rb) (paramètre `order`)
- `@user` : Utilisateur (via `order.user`, ligne 7)

---

#### ✅ `order_paid(order)`
**Sujet** : `💳 Commande #X - Paiement confirmé`

**Fichier mailer** : [`app/mailers/order_mailer.rb`](../app/mailers/order_mailer.rb) (lignes 16-24)

**Déclencheur** :
- Statut commande passe à `paid` / `payé`
- **Appel dans le code** : [`app/models/order.rb`](../app/models/order.rb) (ligne 66) - `OrderMailer.order_paid(self).deliver_later`
- Callback `after_update :notify_status_change` dans [`app/models/order.rb`](../app/models/order.rb) (ligne 20)
- Méthode `notify_status_change` dans [`app/models/order.rb`](../app/models/order.rb) (lignes 57-78)

**Templates** :
- HTML : [`app/views/order_mailer/order_paid.html.erb`](../app/views/order_mailer/order_paid.html.erb)
- Text : [`app/views/order_mailer/order_paid.text.erb`](../app/views/order_mailer/order_paid.text.erb)

**Variables disponibles** :
- `@order` : Objet [`Order`](../app/models/order.rb) (paramètre `order`)
- `@user` : Utilisateur (via `order.user`, ligne 18)

**Logique** :
- Déclenché automatiquement quand le statut change vers `paid` ou `payé` (voir [`app/models/order.rb`](../app/models/order.rb) ligne 65)
- Peut aussi être déclenché via [`HelloassoService`](../app/services/helloasso_service.rb) lors de la synchronisation des paiements

---

#### ✅ `order_cancelled(order)`
**Sujet** : `❌ Commande #X - Commande annulée`

**Fichier mailer** : [`app/mailers/order_mailer.rb`](../app/mailers/order_mailer.rb) (lignes 27-35)

**Déclencheur** :
- Statut commande passe à `cancelled` / `annulé`
- **Appel dans le code** : [`app/models/order.rb`](../app/models/order.rb) (ligne 68) - `OrderMailer.order_cancelled(self).deliver_later`
- Callback `after_update :notify_status_change` dans [`app/models/order.rb`](../app/models/order.rb) (ligne 20)

**Templates** :
- HTML : [`app/views/order_mailer/order_cancelled.html.erb`](../app/views/order_mailer/order_cancelled.html.erb)
- Text : [`app/views/order_mailer/order_cancelled.text.erb`](../app/views/order_mailer/order_cancelled.text.erb)

**Variables disponibles** :
- `@order` : Objet [`Order`](../app/models/order.rb) (paramètre `order`)
- `@user` : Utilisateur (via `order.user`, ligne 29)

**Logique** :
- Déclenché automatiquement quand le statut change vers `cancelled` ou `annulé` (voir [`app/models/order.rb`](../app/models/order.rb) ligne 67)
- Le stock est restauré automatiquement via callback `restore_stock_if_canceled` (voir [`app/models/order.rb`](../app/models/order.rb) lignes 32-54)

---

#### ✅ `order_preparation(order)`
**Sujet** : `⚙️ Commande #X - En préparation`

**Fichier mailer** : [`app/mailers/order_mailer.rb`](../app/mailers/order_mailer.rb) (lignes 38-46)

**Déclencheur** :
- Statut commande passe à `preparation` / `en préparation` / `preparing`
- **Appel dans le code** : [`app/models/order.rb`](../app/models/order.rb) (ligne 70) - `OrderMailer.order_preparation(self).deliver_later`
- Callback `after_update :notify_status_change` dans [`app/models/order.rb`](../app/models/order.rb) (ligne 20)

**Templates** :
- HTML : [`app/views/order_mailer/order_preparation.html.erb`](../app/views/order_mailer/order_preparation.html.erb)
- Text : [`app/views/order_mailer/order_preparation.text.erb`](../app/views/order_mailer/order_preparation.text.erb)

**Variables disponibles** :
- `@order` : Objet [`Order`](../app/models/order.rb) (paramètre `order`)
- `@user` : Utilisateur (via `order.user`, ligne 40)

---

#### ✅ `order_shipped(order)`
**Sujet** : `📦 Commande #X - Expédiée`

**Fichier mailer** : [`app/mailers/order_mailer.rb`](../app/mailers/order_mailer.rb) (lignes 49-57)

**Déclencheur** :
- Statut commande passe à `shipped` / `envoyé` / `expédié`
- **Appel dans le code** : [`app/models/order.rb`](../app/models/order.rb) (ligne 72) - `OrderMailer.order_shipped(self).deliver_later`
- Callback `after_update :notify_status_change` dans [`app/models/order.rb`](../app/models/order.rb) (ligne 20)

**Templates** :
- HTML : [`app/views/order_mailer/order_shipped.html.erb`](../app/views/order_mailer/order_shipped.html.erb)
- Text : [`app/views/order_mailer/order_shipped.text.erb`](../app/views/order_mailer/order_shipped.text.erb)

**Variables disponibles** :
- `@order` : Objet [`Order`](../app/models/order.rb) (paramètre `order`)
- `@user` : Utilisateur (via `order.user`, ligne 51)

---

#### ✅ `refund_requested(order)`
**Sujet** : `🔄 Commande #X - Demande de remboursement en cours`

**Fichier mailer** : [`app/mailers/order_mailer.rb`](../app/mailers/order_mailer.rb) (lignes 60-68)

**Déclencheur** :
- Statut commande passe à `refund_requested` / `remboursement_demandé`
- **Appel dans le code** : [`app/models/order.rb`](../app/models/order.rb) (ligne 74) - `OrderMailer.refund_requested(self).deliver_later`
- Callback `after_update :notify_status_change` dans [`app/models/order.rb`](../app/models/order.rb) (ligne 20)

**Templates** :
- HTML : [`app/views/order_mailer/refund_requested.html.erb`](../app/views/order_mailer/refund_requested.html.erb)
- Text : [`app/views/order_mailer/refund_requested.text.erb`](../app/views/order_mailer/refund_requested.text.erb)

**Variables disponibles** :
- `@order` : Objet [`Order`](../app/models/order.rb) (paramètre `order`)
- `@user` : Utilisateur (via `order.user`, ligne 62)

---

#### ✅ `refund_confirmed(order)`
**Sujet** : `✅ Commande #X - Remboursement confirmé`

**Fichier mailer** : [`app/mailers/order_mailer.rb`](../app/mailers/order_mailer.rb) (lignes 71-79)

**Déclencheur** :
- Statut commande passe à `refunded` / `remboursé`
- **Appel dans le code** : [`app/models/order.rb`](../app/models/order.rb) (ligne 76) - `OrderMailer.refund_confirmed(self).deliver_later`
- Callback `after_update :notify_status_change` dans [`app/models/order.rb`](../app/models/order.rb) (ligne 20)

**Templates** :
- HTML : [`app/views/order_mailer/refund_confirmed.html.erb`](../app/views/order_mailer/refund_confirmed.html.erb)
- Text : [`app/views/order_mailer/refund_confirmed.text.erb`](../app/views/order_mailer/refund_confirmed.text.erb)

**Variables disponibles** :
- `@order` : Objet [`Order`](../app/models/order.rb) (paramètre `order`)
- `@user` : Utilisateur (via `order.user`, ligne 73)

---

### 2.2. Workflow Complet

```
Création commande (pending)
    ↓
Email: order_confirmation ✅
    ↓
Paiement HelloAsso
    ↓
Statut → paid
    ↓
Email: order_paid ✅
    ↓
Admin → preparation
    ↓
Email: order_preparation ✅
    ↓
Admin → shipped
    ↓
Email: order_shipped ✅
```

**Références** :
- Documentation complète : [`docs/09-product/orders-workflow-emails.md`](../../09-product/orders-workflow-emails.md)
- Modèle Order : [`app/models/order.rb`](../app/models/order.rb) (callback `notify_status_change` ligne 20, méthode `notify_status_change` lignes 57-78)
- Controller Orders : [`app/controllers/orders_controller.rb`](../app/controllers/orders_controller.rb) (action `create` ligne 76)
- Service HelloAsso : [`app/services/helloasso_service.rb`](../app/services/helloasso_service.rb) (synchronisation statuts paiement)

---

## 👤 3. MembershipMailer - Emails Adhésions

**Fichier** : [`app/mailers/membership_mailer.rb`](../app/mailers/membership_mailer.rb)

### 3.1. Méthodes Disponibles

#### ✅ `activated(membership)`
**Sujet** : `✅ Adhésion Saison [X] - Bienvenue !`

**Fichier mailer** : [`app/mailers/membership_mailer.rb`](../app/mailers/membership_mailer.rb) (lignes 5-13)

**Déclencheur** :
- Adhésion activée (paiement confirmé, statut passe de `pending` à `active`)
- **Appel dans le code** : [`app/models/membership.rb`](../app/models/membership.rb) (ligne 187) - `MembershipMailer.activated(self).deliver_later`
- Callback `activate_if_paid` dans [`app/models/membership.rb`](../app/models/membership.rb) (lignes 184-189)
- Peut aussi être déclenché via [`HelloassoService`](../app/services/helloasso_service.rb) lors de la synchronisation des paiements

**Templates** :
- HTML : [`app/views/membership_mailer/activated.html.erb`](../app/views/membership_mailer/activated.html.erb)
- Text : [`app/views/membership_mailer/activated.text.erb`](../app/views/membership_mailer/activated.text.erb)

**Variables disponibles** :
- `@membership` : Objet [`Membership`](../app/models/membership.rb) (paramètre `membership`)
- `@user` : Utilisateur propriétaire (via `membership.user`, ligne 7)
- `@membership.season` : Saison (ex: "2024-2025") - champ dans [`db/schema.rb`](../db/schema.rb) table `memberships`
- `@membership.start_date`, `@membership.end_date` : Dates - champs dans [`db/schema.rb`](../db/schema.rb) table `memberships`
- `@membership.category` : Type (enum : `standard` ou `with_ffrs`) - voir [`app/models/membership.rb`](../app/models/membership.rb) lignes 18-21
- `@membership.is_child_membership` : Boolean (adulte ou enfant) - champ dans [`db/schema.rb`](../db/schema.rb) table `memberships`

**Logique** :
- Déclenché automatiquement quand le statut passe de `pending` à `active` (voir [`app/models/membership.rb`](../app/models/membership.rb) lignes 186-187)

---

#### ✅ `expired(membership)`
**Sujet** : `⏰ Adhésion Saison [X] - Expirée`

**Fichier mailer** : [`app/mailers/membership_mailer.rb`](../app/mailers/membership_mailer.rb) (lignes 16-24)

**Déclencheur** :
- ✅ **Job Solid Queue** : `UpdateExpiredMembershipsJob` exécuté quotidiennement à minuit
- **Fichier job** : [`app/jobs/update_expired_memberships_job.rb`](../app/jobs/update_expired_memberships_job.rb)
- **Appel dans le code** : `MembershipMailer.expired(membership).deliver_later` (ligne 22 du job)
- ⚠️ **Rake task dépréciée** : [`lib/tasks/memberships.rake`](../lib/tasks/memberships.rake) conservée pour référence uniquement
- **Note** : Utilise `deliver_later` via Solid Queue pour traitement asynchrone avec retry automatique

**Templates** :
- HTML : [`app/views/membership_mailer/expired.html.erb`](../app/views/membership_mailer/expired.html.erb)
- Text : [`app/views/membership_mailer/expired.text.erb`](../app/views/membership_mailer/expired.text.erb)

**Variables disponibles** :
- `@membership` : Objet [`Membership`](../app/models/membership.rb) (paramètre `membership`)
- `@user` : Utilisateur propriétaire (via `membership.user`, ligne 18)
- `@membership.season` : Saison (ex: "2024-2025")

**Configuration cron** :
- ✅ **Solid Queue** : [`config/recurring.yml`](../config/recurring.yml) - **ACTIF**
- ✅ Job configuré : `UpdateExpiredMembershipsJob` (minuit quotidien)
- ⚠️ **Supercronic déprécié** : [`config/schedule.rb`](../config/schedule.rb) conservé pour référence uniquement

**Logique** :
- Filtre les adhésions `active` avec `end_date < Date.current` (voir [`lib/tasks/memberships.rake`](../lib/tasks/memberships.rake) lignes 6-9)
- Met à jour le statut vers `expired` puis envoie l'email (voir [`lib/tasks/memberships.rake`](../lib/tasks/memberships.rake) lignes 10-15)

---

#### ✅ `renewal_reminder(membership)`
**Sujet** : `🔄 Renouvellement d'adhésion - Dans 30 jours`

**Fichier mailer** : [`app/mailers/membership_mailer.rb`](../app/mailers/membership_mailer.rb) (lignes 27-35)

**Déclencheur** :
- ✅ **Job Solid Queue** : `SendRenewalRemindersJob` exécuté quotidiennement à 9h
- **Fichier job** : [`app/jobs/send_renewal_reminders_job.rb`](../app/jobs/send_renewal_reminders_job.rb)
- 30 jours avant expiration (`end_date = 30.days.from_now.to_date`)
- **Appel dans le code** : `MembershipMailer.renewal_reminder(membership).deliver_later` (ligne 18 du job)
- ⚠️ **Rake task dépréciée** : [`lib/tasks/memberships.rake`](../lib/tasks/memberships.rake) conservée pour référence uniquement
- **Note** : Utilise `deliver_later` via Solid Queue pour traitement asynchrone avec retry automatique

**Templates** :
- HTML : [`app/views/membership_mailer/renewal_reminder.html.erb`](../app/views/membership_mailer/renewal_reminder.html.erb)
- Text : [`app/views/membership_mailer/renewal_reminder.text.erb`](../app/views/membership_mailer/renewal_reminder.text.erb)

**Variables disponibles** :
- `@membership` : Objet [`Membership`](../app/models/membership.rb) (paramètre `membership`)
- `@user` : Utilisateur propriétaire (via `membership.user`, ligne 29)

**Configuration cron** :
- ✅ **Solid Queue** : [`config/recurring.yml`](../config/recurring.yml) - **ACTIF**
- ✅ Job configuré : `SendRenewalRemindersJob` (9h quotidien)
- ⚠️ **Supercronic déprécié** : [`config/schedule.rb`](../config/schedule.rb) conservé pour référence uniquement

**Logique** :
- Filtre les adhésions `active` avec `end_date = 30.days.from_now.to_date` (voir [`lib/tasks/memberships.rake`](../lib/tasks/memberships.rake) lignes 26-32)
- **⚠️ Risque de doublons** : Pas de flag `renewal_reminder_sent_at` - peut envoyer plusieurs fois si task exécutée plusieurs fois
- **Recommandation** : Ajouter `renewal_reminder_sent_at` (datetime) dans [`db/schema.rb`](../db/schema.rb) table `memberships` pour éviter doublons

---

#### ✅ `payment_failed(membership)`
**Sujet** : `❌ Paiement adhésion Saison [X] - Échec`

**Fichier mailer** : [`app/mailers/membership_mailer.rb`](../app/mailers/membership_mailer.rb) (lignes 38-46)

**Déclencheur** :
- Échec de paiement HelloAsso (statut `failed`, `refunded`, ou `abandoned`)
- **Appels dans le code** :
  - [`app/services/helloasso_service.rb`](../app/services/helloasso_service.rb) (ligne 424) - `MembershipMailer.payment_failed(payment.membership).deliver_later` (adhésion personnelle)
  - [`app/services/helloasso_service.rb`](../app/services/helloasso_service.rb) (ligne 436) - `MembershipMailer.payment_failed(membership).deliver_later` (adhésions enfants)
- Méthode `sync_payment_status` dans [`app/services/helloasso_service.rb`](../app/services/helloasso_service.rb) (lignes 400-450)
- Déclenché uniquement si `new_status == "failed"` ET `old_status == "pending"` (voir [`app/services/helloasso_service.rb`](../app/services/helloasso_service.rb) lignes 423-425, 434-437)

**Templates** :
- HTML : [`app/views/membership_mailer/payment_failed.html.erb`](../app/views/membership_mailer/payment_failed.html.erb)
- Text : [`app/views/membership_mailer/payment_failed.text.erb`](../app/views/membership_mailer/payment_failed.text.erb)

**Variables disponibles** :
- `@membership` : Objet [`Membership`](../app/models/membership.rb) (paramètre `membership`)
- `@user` : Utilisateur propriétaire (via `membership.user`, ligne 40)
- `@membership.season` : Saison (ex: "2024-2025")

**Logique** :
- Déclenché lors de la synchronisation automatique HelloAsso (polling toutes les 5 minutes)
- Task cron : [`config/schedule.rb`](../config/schedule.rb) (lignes 8-10) - `helloasso:sync_payments` toutes les 5 minutes

---

### 3.2. Cycle de Vie d'une Adhésion

```
1. Création (pending)
   ↓
2. Tentative paiement
   ↓
   ├─→ Succès → activated ✅
   │           ↓
   │     3. Actif (active)
   │           ↓
   │     4. 30 jours avant expiration → renewal_reminder 📧
   │           ↓
   │     5. Expiration → expired 📧
   │
   └─→ Échec → payment_failed ❌
                (peut réessayer)
```

**Références** :
- Documentation complète : [`docs/09-product/membership-mailer-emails.md`](../../09-product/membership-mailer-emails.md)
- Rake tasks : [`lib/tasks/memberships.rake`](../lib/tasks/memberships.rake)
- Modèle Membership : [`app/models/membership.rb`](../app/models/membership.rb) (callback `activate_if_paid` lignes 184-189)
- Service HelloAsso : [`app/services/helloasso_service.rb`](../app/services/helloasso_service.rb) (synchronisation paiements lignes 400-450)

---

## 👋 4. UserMailer - Emails Utilisateurs

**Fichier** : [`app/mailers/user_mailer.rb`](../app/mailers/user_mailer.rb)

### 4.1. Méthodes Disponibles

#### ✅ `welcome_email(user)`
**Sujet** : `🎉 Bienvenue chez Grenoble Roller!`

**Fichier mailer** : [`app/mailers/user_mailer.rb`](../app/mailers/user_mailer.rb) (lignes 4-12)

**Déclencheur** :
- Inscription d'un nouvel utilisateur
- **Appel dans le code** : [`app/models/user.rb`](../app/models/user.rb) (ligne 170) - `UserMailer.welcome_email(self).deliver_later`
- Callback `after_create :send_welcome_email_and_confirmation` dans [`app/models/user.rb`](../app/models/user.rb) (ligne 29)
- Méthode `send_welcome_email_and_confirmation` dans [`app/models/user.rb`](../app/models/user.rb) (lignes 166-171)

**Templates** :
- HTML : [`app/views/user_mailer/welcome_email.html.erb`](../app/views/user_mailer/welcome_email.html.erb)
- Text : [`app/views/user_mailer/welcome_email.text.erb`](../app/views/user_mailer/welcome_email.text.erb)

**Variables disponibles** :
- `@user` : Nouvel utilisateur (paramètre `user`)
- `@events_url` : URL vers la page événements - calculé ligne 6 : `events_url` (helper Rails)

**Logique** :
- Envoyé automatiquement lors de la création d'un utilisateur (voir [`app/models/user.rb`](../app/models/user.rb) ligne 29)
- **Note** : Devise envoie automatiquement l'email de confirmation via `:confirmable` (voir [`app/models/user.rb`](../app/models/user.rb) ligne 169)

**Références** :
- Documentation : [`docs/04-rails/setup/user-mailer-welcome.md`](../setup/user-mailer-welcome.md)
- Modèle User : [`app/models/user.rb`](../app/models/user.rb) (callback ligne 29, méthode `send_welcome_email_and_confirmation` lignes 166-171)

---

## 🔐 5. DeviseMailer - Emails Authentification

**Fichier** : Configuré dans [`config/initializers/devise.rb`](../config/initializers/devise.rb)

### 5.1. Méthodes Disponibles

#### ✅ `confirmation_instructions(user, token)`
**Sujet** : `Confirmez votre adresse email - Grenoble Roller`

**Déclencheur** :
- Inscription ou renvoi email de confirmation
- Automatiquement par Devise

**Templates** :
- HTML : [`app/views/devise/mailer/confirmation_instructions.html.erb`](../app/views/devise/mailer/confirmation_instructions.html.erb)
- Text : [`app/views/devise/mailer/confirmation_instructions.text.erb`](../app/views/devise/mailer/confirmation_instructions.text.erb)

**Caractéristiques** :
- ✅ Design moderne avec gradient header
- ✅ QR code PNG (pièce jointe + inline)
- ✅ Badge expiration visible
- ✅ Lien fallback
- ✅ Mobile-friendly

**Références** :
- Documentation complète : [`docs/04-rails/setup/email-confirmation.md`](../setup/email-confirmation.md)
- Sécurité : [`docs/04-rails/security/email-security-service.md`](../security/email-security-service.md)

---

## ⚙️ 6. Configuration SMTP

### 6.1. ApplicationMailer

**Fichier** : [`app/mailers/application_mailer.rb`](../app/mailers/application_mailer.rb)

```ruby
class ApplicationMailer < ActionMailer::Base
  default from: "Grenoble Roller <no-reply@grenoble-roller.org>"
  layout "mailer"
end
```

**Adresse expéditeur** : `no-reply@grenoble-roller.org`

---

### 6.2. Configuration par Environnement

#### Développement
**Fichier** : [`config/environments/development.rb`](../config/environments/development.rb) (lignes 59-69)

```ruby
config.action_mailer.delivery_method = :smtp  # Ligne 59
config.action_mailer.smtp_settings = {        # Lignes 60-69
  # Utilise les credentials Rails
  user_name: Rails.application.credentials.dig(:smtp, :user_name),  # Ligne 61
  password: Rails.application.credentials.dig(:smtp, :password),    # Ligne 62
  address: Rails.application.credentials.dig(:smtp, :address) || "smtp.ionos.fr",  # Ligne 62
  port: Rails.application.credentials.dig(:smtp, :port) || 465,     # Ligne 63
  domain: Rails.application.credentials.dig(:smtp, :domain) || "grenoble-roller.org",  # Ligne 64
  authentication: :plain,                      # Ligne 65
  enable_starttls_auto: false,                # Ligne 66
  ssl: true,                                  # Ligne 67
  openssl_verify_mode: "peer"                 # Ligne 68
}

config.action_mailer.default_url_options = {   # Lignes 71-74
  host: ENV.fetch("MAILER_HOST", "dev-grenoble-roller.flowtech-lab.org"),
  protocol: ENV.fetch("MAILER_PROTOCOL", "https")
}
```

**Status** : ✅ Configuré (SMTP IONOS)

**Références** :
- Credentials Rails : [`config/credentials.yml.enc`](../config/credentials.yml.enc) (éditer via `bin/rails credentials:edit`)

---

#### Production
**Fichier** : [`config/environments/production.rb`](../config/environments/production.rb) (lignes 69-79)

```ruby
config.action_mailer.delivery_method = :smtp  # Ligne 69
config.action_mailer.smtp_settings = {        # Lignes 70-79
  # Utilise les credentials Rails
  user_name: Rails.application.credentials.dig(:smtp, :user_name),  # Ligne 71
  password: Rails.application.credentials.dig(:smtp, :password),    # Ligne 72
  address: Rails.application.credentials.dig(:smtp, :address) || "smtp.ionos.fr",  # Ligne 73
  port: Rails.application.credentials.dig(:smtp, :port) || 465,     # Ligne 74
  domain: Rails.application.credentials.dig(:smtp, :domain) || "grenoble-roller.org",  # Ligne 75
  authentication: :plain,                      # Ligne 76
  enable_starttls_auto: false,                 # Ligne 77
  ssl: true,                                  # Ligne 78
  openssl_verify_mode: "peer"                 # Ligne 79
}

config.action_mailer.default_url_options = {  # Lignes 63-66
  host: ENV.fetch("MAILER_HOST", "grenoble-roller.org"),
  protocol: ENV.fetch("MAILER_PROTOCOL", "https")
}
```

**Status** : ✅ Configuré (SMTP IONOS)

**Références** :
- Credentials Rails : [`config/credentials.yml.enc`](../config/credentials.yml.enc) (éditer via `bin/rails credentials:edit`)
- Variables d'environnement : [`ops/config/production.env`](../ops/config/production.env) (MAILER_HOST, MAILER_PROTOCOL)

---

#### Test
**Fichier** : [`config/environments/test.rb`](../config/environments/test.rb) (lignes 55-56)

```ruby
config.action_mailer.delivery_method = :test  # Ligne 55
config.action_mailer.default_url_options = { host: "example.com" }  # Ligne 56
```

**Status** : ✅ Configuré (accumulation dans `ActionMailer::Base.deliveries`)

**Note** : En test, les emails ne sont pas réellement envoyés mais accumulés dans `ActionMailer::Base.deliveries` pour les tests RSpec

---

### 6.3. Credentials Rails

**Commande pour éditer** :
```bash
docker compose -f ops/dev/docker-compose.yml run --rm -it -e EDITOR=nano web bin/rails credentials:edit
```

**Structure YAML** :
```yaml
smtp:
  user_name: no-reply@grenoble-roller.org
  password: votre_mot_de_passe_ionos
  address: smtp.ionos.fr
  port: 465
  domain: grenoble-roller.org
```

**Fichier** : [`config/credentials.yml.enc`](../config/credentials.yml.enc) (chiffré, nécessite `RAILS_MASTER_KEY`)

**Références** :
- Documentation credentials : [`docs/04-rails/setup/credentials.md`](../setup/credentials.md)
- Script d'édition : [`bin/edit-credentials`](../bin/edit-credentials)

---

## 🔄 7. Jobs et Tâches Automatiques

### 7.1. EventReminderJob

**Fichier** : [`app/jobs/event_reminder_job.rb`](../app/jobs/event_reminder_job.rb)

**Fréquence** : Tous les jours à **19h00** (7:00pm)

**Configuration** :
- ✅ **SolidQueue** : [`config/recurring.yml`](../config/recurring.yml) - **ACTIF** et utilisé pour EventReminderJob
- ✅ Job configuré dans `config/recurring.yml` (19h quotidien)
- ✅ Exécuté automatiquement par Solid Queue au démarrage de l'application
- ⚠️ **Supercronic déprécié** : [`config/schedule.rb`](../config/schedule.rb) et [`config/crontab`](../config/crontab) conservés pour référence uniquement
- **Voir Section 12.3** pour architecture complète et [`docs/04-rails/background-jobs/CRON.md`](../background-jobs/CRON.md) pour documentation complète

**Fonction** : Envoie des rappels la veille (à 19h) pour les événements et initiations du lendemain

**Types d'événements traités** :
- ✅ **Événements** (Event) : Randos, sorties, etc.
- ✅ **Initiations** (Event::Initiation) : Initiations roller du samedi

**Participants concernés** :
- ✅ **Parents** : Les parents qui se sont inscrits eux-mêmes et ont coché "Je veux recevoir un rappel"
- ✅ **Enfants** : Les enfants inscrits par leurs parents (si le parent a coché "Je veux recevoir un rappel" lors de l'inscription de l'enfant)
- ✅ **Bénévoles** : Les bénévoles qui ont coché "Je veux recevoir un rappel" (même logique que les participants)

**Logique de filtrage** :
1. **Événements** : Trouve tous les événements publiés qui ont lieu demain (voir [`app/jobs/event_reminder_job.rb`](../app/jobs/event_reminder_job.rb) lignes 8-15)
2. **Attendances** : Pour chaque événement, filtre les attendances :
   - ✅ Actives (non annulées) : `.active` (exclut `canceled` mais inclut `no_show` - voir Section 12.5)
   - ✅ Avec rappel demandé : `.where(wants_reminder: true)` (champ dans [`app/models/attendance.rb`](../app/models/attendance.rb))
   - ✅ Pas encore envoyé : `.where(reminder_sent_at: nil)` (protection contre doublons)
3. **Préférences utilisateur** :
   - Pour les **initiations** : Vérifie aussi `user.wants_initiation_mail?` (préférence globale - voir [`app/jobs/event_reminder_job.rb`](../app/jobs/event_reminder_job.rb) lignes 30-32)
   - Pour les **événements** : Pas de vérification supplémentaire (seulement `wants_reminder` par inscription)
4. **Envoi** : Un email par attendance (donc un parent peut recevoir plusieurs emails s'il a inscrit plusieurs enfants)

**Exemple concret** :
- Un parent inscrit 2 enfants à une initiation du samedi
- Le parent coche "Je veux recevoir un rappel" pour chaque enfant lors de l'inscription
- Le vendredi à 19h, le parent recevra **2 emails de rappel** (un par enfant inscrit)
- Chaque email contient les détails de l'initiation et le nom de l'enfant concerné

**Références** :
- Documentation complète : [`docs/06-events/event-reminder-job.md`](../../06-events/event-reminder-job.md)
- Architecture : Section 12.3 de ce document
- Code du job : [`app/jobs/event_reminder_job.rb`](../app/jobs/event_reminder_job.rb)
- Modèle Attendance : [`app/models/attendance.rb`](../app/models/attendance.rb) (scope `.active`, champ `wants_reminder`, `child_membership_id`)

---

### 7.2. HelloAsso Sync (Polling)

**Fichier** : [`lib/tasks/helloasso.rake`](../lib/tasks/helloasso.rake) (lignes 1-19)

**Fréquence** : Toutes les **5 minutes**

**Configuration** :
- ✅ **SolidQueue** : [`config/recurring.yml`](../config/recurring.yml) - **ACTIF**
- ✅ Job configuré : `SyncHelloAssoPaymentsJob` (toutes les 5 minutes)
- ⚠️ **Supercronic déprécié** : [`config/schedule.rb`](../config/schedule.rb) conservé pour référence uniquement

**Fonction** : Synchronise les statuts de paiement HelloAsso (déclenche emails `order_paid`, `membership_activated`, `payment_failed`)

**✅ STATUT ACTUEL** : **ACTIF** - Exécuté automatiquement par Solid Queue toutes les 5 minutes.

**Logique** :
- Filtre les paiements `pending` créés dans les dernières 24h (voir [`lib/tasks/helloasso.rake`](../lib/tasks/helloasso.rake) lignes 4-6)
- Appelle [`HelloassoService.fetch_and_update_payment`](../app/services/helloasso_service.rb) pour chaque paiement (ligne 9)
- Les emails sont déclenchés automatiquement via les callbacks dans [`app/models/order.rb`](../app/models/order.rb) et [`app/models/membership.rb`](../app/models/membership.rb)
- Les emails `payment_failed` sont envoyés directement depuis [`HelloassoService`](../app/services/helloasso_service.rb) (lignes 424, 436)

**Références** :
- Service HelloAsso : [`app/services/helloasso_service.rb`](../app/services/helloasso_service.rb) (méthode `fetch_and_update_payment`)
- Modèle Payment : [`app/models/payment.rb`](../app/models/payment.rb)

---

### 7.3. Adhésions Expirées

**Fichier** : [`lib/tasks/memberships.rake`](../lib/tasks/memberships.rake) (lignes 3-22)

**Fréquence** : Tous les jours à **00h00** (minuit)

**Configuration** :
- ✅ **SolidQueue** : [`config/recurring.yml`](../config/recurring.yml) - **ACTIF**
- ✅ Job configuré : `UpdateExpiredMembershipsJob` (minuit quotidien)
- ⚠️ **Supercronic déprécié** : [`config/schedule.rb`](../config/schedule.rb) conservé pour référence uniquement

**Fonction** : Met à jour les statuts d'adhésions expirées et envoie `membership_expired`

**✅ STATUT ACTUEL** : **ACTIF** - Exécuté automatiquement par Solid Queue tous les jours à minuit.

**Logique** :
- Filtre les adhésions `active` avec `end_date < Date.current` (voir [`lib/tasks/memberships.rake`](../lib/tasks/memberships.rake) lignes 6-9)
- Met à jour le statut vers `expired` (ligne 10)
- Envoie l'email `expired` avec `deliver_later` (ligne 20) ✅ **CORRIGÉ**
- ✅ **CORRIGÉ** : Utilise `deliver_later` → traitement asynchrone avec retry automatique
- ✅ **CORRIGÉ** : Flag `expired_email_sent_at` ajouté + filtre `.where(expired_email_sent_at: nil)` (ligne 10) - protection contre doublons
- **Voir Section 12.1 et 12.2** pour détails des corrections

**Références** :
- Modèle Membership : [`app/models/membership.rb`](../app/models/membership.rb) (enum `status` lignes 11-16)

---

### 7.4. Rappels Renouvellement

**Fichier** : [`lib/tasks/memberships.rake`](../lib/tasks/memberships.rake) (lignes 25-42)

**Fréquence** : Tous les jours à **09h00**

**Configuration** :
- ✅ **SolidQueue** : [`config/recurring.yml`](../config/recurring.yml) - **ACTIF**
- ✅ Job configuré : `SendRenewalRemindersJob` (9h quotidien)
- ⚠️ **Supercronic déprécié** : [`config/schedule.rb`](../config/schedule.rb) conservé pour référence uniquement

**Fonction** : Envoie `membership_renewal_reminder` 30 jours avant expiration

**✅ STATUT ACTUEL** : **ACTIF** - Exécuté automatiquement par Solid Queue tous les jours à 9h.

**Logique** :
- Calcule la date cible : `30.days.from_now.to_date` (voir [`lib/tasks/memberships.rake`](../lib/tasks/memberships.rake) ligne 26)
- Filtre les adhésions `active` avec `end_date = reminder_date` (lignes 29-32)
- Envoie l'email `renewal_reminder` avec `deliver_later` (ligne 43) ✅ **CORRIGÉ**
- ✅ **CORRIGÉ** : Utilise `deliver_later` → traitement asynchrone avec retry automatique
- ✅ **CORRIGÉ** : Flag `renewal_reminder_sent_at` ajouté + filtre `.where(renewal_reminder_sent_at: nil)` (ligne 39) - protection contre doublons
- **Voir Section 12.1 et 12.2** pour détails des corrections

**Références** :
- Modèle Membership : [`app/models/membership.rb`](../app/models/membership.rb) (enum `status` lignes 11-16)

---

### 7.5. Rapport Participants Initiation ✅ **IMPLÉMENTÉ**

**Fichier** : [`app/jobs/initiation_participants_report_job.rb`](../app/jobs/initiation_participants_report_job.rb)

**Fréquence** : Tous les jours à **07h00** (uniquement en production)

**Configuration** :
- ✅ **SolidQueue** : Job créé automatiquement lors de la publication d'une initiation
- ✅ Planifié pour s'exécuter le jour de l'initiation à 7h00
- ⚠️ **Note** : Ce job n'est plus récurrent, il est créé à la demande lors de la publication d'une initiation

**Fonction** : Envoie un email à `contact@grenoble-roller.org` avec la liste des participants et le matériel demandé pour chaque initiation du jour.

**Logique du Job** :

```ruby
class InitiationParticipantsReportJob < ApplicationJob
  queue_as :default

  def perform
    # Ne s'exécute qu'en production (ou si FORCE_INITIATION_REPORT=true pour tests)
    return unless Rails.env.production? || ENV['FORCE_INITIATION_REPORT'] == 'true'

    # Trouver toutes les initiations du jour (aujourd'hui entre 00:00 et 23:59:59)
    # qui n'ont pas encore reçu de rapport aujourd'hui (prévention doublons)
    today_start = Time.zone.now.beginning_of_day
    today_end = today_start.end_of_day

    initiations = Event::Initiation
                   .published
                   .where(start_at: today_start..today_end)
                   .where(participants_report_sent_at: nil) # Prévention doublons
                   .includes(:attendances, :creator_user) # Éviter N+1 queries

    # Si aucune initiation aujourd'hui, ne rien faire
    return if initiations.empty?

    # Envoyer un email pour chaque initiation
    initiations.find_each do |initiation|
      EventMailer.initiation_participants_report(initiation).deliver_later
      # Marquer comme envoyé pour éviter les doublons
      initiation.update_column(:participants_report_sent_at, Time.zone.now)
    end
  end
end
```

**Optimisations implémentées** :
- ✅ **Includes pour éviter N+1** : `.includes(:attendances, :creator_user)` - charge les associations en une seule requête
- ✅ **Vérification production optimisée** : Permet de tester en dev avec `FORCE_INITIATION_REPORT=true bin/rails runner "InitiationParticipantsReportJob.perform_now"`
- ✅ **Flag de suivi anti-doublons** : `participants_report_sent_at` - évite les relances si cron exécuté 2x le même jour

**Mailer** : Méthode `initiation_participants_report` dans [`app/mailers/event_mailer.rb`](../app/mailers/event_mailer.rb) ✅ **CRÉÉ**

```ruby
def initiation_participants_report(initiation)
  @initiation = initiation
  
  # Récupérer tous les participants actifs (non bénévoles, non annulés)
  @participants = initiation.attendances
                            .active
                            .participants
                            .includes(:user, :child_membership)
                            .order(:created_at)
  
  # Filtrer uniquement ceux qui demandent du matériel
  @participants_with_equipment = @participants.select { |a| a.needs_equipment? && a.roller_size.present? }
  
  mail(
    to: "contact@grenoble-roller.org",
    subject: "📋 Rapport participants - Initiation #{l(@initiation.start_at, format: :day_month, locale: :fr)}"
  )
end
```

**Templates** : ✅ **CRÉÉS**
- HTML : [`app/views/event_mailer/initiation_participants_report.html.erb`](../app/views/event_mailer/initiation_participants_report.html.erb)
- Texte : [`app/views/event_mailer/initiation_participants_report.text.erb`](../app/views/event_mailer/initiation_participants_report.text.erb)

**Code basique (sans CSS ni classes)** :

```erb
<div>
  <h1>Rapport Participants - Initiation</h1>
  
  <div>
    <h2><%= @initiation.title %></h2>
    <p><strong>Date :</strong> <%= l(@initiation.start_at, format: :long) %></p>
    <p><strong>Lieu :</strong> <%= @initiation.location_text %></p>
    <p><strong>Total participants :</strong> <%= @participants.count %></p>
    <p><strong>Participants avec matériel :</strong> <%= @participants_with_equipment.count %></p>
  </div>
  
  <div>
    <h3>Liste des Participants</h3>
    <table>
      <thead>
        <tr>
          <th>Nom</th>
          <th>Email</th>
          <th>Type</th>
          <th>Matériel</th>
          <th>Pointure</th>
        </tr>
      </thead>
      <tbody>
        <% @participants.each do |attendance| %>
          <tr>
            <td>
              <% if attendance.for_child? %>
                <%= attendance.child_membership.child_first_name %> <%= attendance.child_membership.child_last_name %>
              <% else %>
                <%= attendance.user.first_name %> <%= attendance.user.last_name %>
              <% end %>
            </td>
            <td><%= attendance.user.email %></td>
            <td><%= attendance.for_child? ? 'Enfant' : 'Adulte' %></td>
            <td><%= attendance.needs_equipment? ? 'Oui' : 'Non' %></td>
            <td><%= attendance.needs_equipment? && attendance.roller_size.present? ? attendance.roller_size : '-' %></td>
          </tr>
        <% end %>
      </tbody>
    </table>
  </div>
  
  <% if @participants_with_equipment.any? %>
    <div>
      <h3>Résumé Matériel Demandé</h3>
      <ul>
        <% @participants_with_equipment.group_by(&:roller_size).sort.each do |size, attendances| %>
          <li>Pointure <%= size %> : <%= attendances.count %> paire(s)</li>
        <% end %>
      </ul>
    </div>
  <% end %>
</div>
```

**Template texte** : `app/views/event_mailer/initiation_participants_report.text.erb`

**Avantages de cette solution** :
- ✅ Utilise la même architecture que les autres jobs (Supercronic)
- ✅ S'exécute uniquement en production (vérification dans le job)
- ✅ Ne s'exécute que s'il y a des initiations aujourd'hui (optimisé)
- ✅ Utilise `deliver_later` pour traitement asynchrone
- ✅ Réutilise `EventMailer` (cohérent avec le reste du système)
- ✅ Facile à tester et maintenir

**Références** :
- Job : [`app/jobs/initiation_participants_report_job.rb`](../app/jobs/initiation_participants_report_job.rb) ✅ **CRÉÉ**
- Mailer : [`app/mailers/event_mailer.rb`](../app/mailers/event_mailer.rb) (méthode `initiation_participants_report`) ✅ **CRÉÉ**
- Templates : 
  - [`app/views/event_mailer/initiation_participants_report.html.erb`](../app/views/event_mailer/initiation_participants_report.html.erb) ✅ **CRÉÉ**
  - [`app/views/event_mailer/initiation_participants_report.text.erb`](../app/views/event_mailer/initiation_participants_report.text.erb) ✅ **CRÉÉ**
- Schedule : [`config/schedule.rb`](../config/schedule.rb) (ligne ajoutée) ✅ **CRÉÉ**
- Migration : [`db/migrate/20251220062313_add_participants_report_sent_at_to_events.rb`](../db/migrate/20251220062313_add_participants_report_sent_at_to_events.rb) ✅ **CRÉÉ**

**Optimisations implémentées** :
- ✅ **Includes pour éviter N+1** : `.includes(:attendances, :creator_user)` - charge les associations en une seule requête
- ✅ **Vérification production optimisée** : Permet de tester en dev avec `FORCE_INITIATION_REPORT=true bin/rails runner "InitiationParticipantsReportJob.perform_now"`
- ✅ **Flag de suivi anti-doublons** : `participants_report_sent_at` - évite les relances si cron exécuté 2x le même jour

**Note** : ⚠️ Ce job ne fonctionnera que lorsque Supercronic sera corrigé (voir Section 12.3).

---

## 🎯 8. Préférences Utilisateur

### 8.1. Préférences par Inscription (Attendance)

**Champ** : `wants_reminder` (boolean)

**Modèle** : [`app/models/attendance.rb`](../app/models/attendance.rb)

**Usage** :
- Préférence par inscription (chaque inscription peut avoir sa propre préférence)
- Utilisé par `EventReminderJob` pour filtrer les rappels
- Défaut : `false` (pas de rappel par défaut)

**Formulaire** :
- Case à cocher dans le formulaire d'inscription
- Défaut : `true` (coché par défaut dans le formulaire)

---

### 8.2. Préférences Globales (User)

**Champ** : `wants_initiation_mail` (boolean)

**Modèle** : [`app/models/user.rb`](../app/models/user.rb)

**Migration** : [`db/migrate/20251201020755_add_email_preferences_to_users.rb`](../db/migrate/20251201020755_add_email_preferences_to_users.rb) (ligne 3)

**Schema** : [`db/schema.rb`](../db/schema.rb) table `users` (champ `wants_initiation_mail`)

**Formulaire** : [`app/views/devise/registrations/edit.html.erb`](../app/views/devise/registrations/edit.html.erb) (lignes 191-196)

**Usage** :
- Préférence globale pour les initiations uniquement
- Utilisé par [`EventReminderJob`](../app/jobs/event_reminder_job.rb) (lignes 28-30) pour filtrer les rappels d'initiations
- Utilisé dans [`app/controllers/initiations/attendances_controller.rb`](../app/controllers/initiations/attendances_controller.rb) (lignes 68, 222) pour filtrer les emails de confirmation
- Utilisé dans [`app/controllers/initiations/attendances_controller.rb`](../app/controllers/initiations/attendances_controller.rb) (ligne 277) pour filtrer les emails d'annulation
- Application : Uniquement pour `Event::Initiation`

**Défaut** : `true` (voir migration ligne 3 : `default: true, null: false`)

---

### 8.3. Préférences Email Événements (User)

**Champ** : `wants_events_mail` (boolean)

**Modèle** : [`app/models/user.rb`](../app/models/user.rb)

**Migration** : [`db/migrate/20251201020755_add_email_preferences_to_users.rb`](../db/migrate/20251201020755_add_email_preferences_to_users.rb) (ligne 4)

**Schema** : [`db/schema.rb`](../db/schema.rb) table `users` (champ `wants_events_mail`)

**Formulaire** : [`app/views/devise/registrations/edit.html.erb`](../app/views/devise/registrations/edit.html.erb) (lignes 201-206) - "Emails événements"

**Usage** :
- Préférence globale pour les événements généraux (pas les initiations)
- Utilisé dans [`app/controllers/events/attendances_controller.rb`](../app/controllers/events/attendances_controller.rb) (lignes 93, 97) pour filtrer les emails d'annulation
- Utilisé dans [`app/controllers/events/waitlist_entries_controller.rb`](../app/controllers/events/waitlist_entries_controller.rb) (ligne 117) pour filtrer les emails de confirmation
- Utilisé dans [`app/controllers/memberships_controller.rb`](../app/controllers/memberships_controller.rb) (plusieurs lignes) lors de la création d'adhésion

**Défaut** : `true` (voir migration ligne 4 : `default: true, null: false`)

**Note** : Il n'existe **PAS** de champ `email_preferences` (JSON/hash). Les préférences sont gérées via deux champs boolean séparés : `wants_initiation_mail` et `wants_events_mail`.

---

## 📊 9. Statistiques Globales

**Total emails** : 19 emails (18 existants + 1 à implémenter)

### 9.1. Résumé par Mailer

| Mailer | Emails | HTML | Text | Status |
|--------|--------|------|------|--------|
| **EventMailer** | 6 (5 + 1 à implémenter) | ✅ 5/6 | ✅ 5/6 | 📝 **83%** (1 à implémenter) |
| **OrderMailer** | 7 | ✅ 7/7 | ✅ 7/7 | ✅ **100%** |
| **MembershipMailer** | 4 | ✅ 4/4 | ✅ 4/4 | ✅ **100%** |
| **UserMailer** | 1 | ✅ 1/1 | ✅ 1/1 | ✅ **100%** |
| **DeviseMailer** | 1 | ✅ 1/1 | ✅ 1/1 | ✅ **100%** |
| **TOTAL** | **19** (18 + 1 à implémenter) | ✅ **18/19** | ✅ **18/19** | 📝 **95%** (1 à implémenter) |

---

### 9.2. Résumé par Type

| Type | Compteur |
|------|----------|
| ✅ **Emails complets** (HTML + Texte) | 18 |
| 📝 **Emails à implémenter** | 1 (`initiation_participants_report`) |
| ⚠️ **Emails partiels** (HTML seulement) | 0 |
| ❌ **Emails manquants** | 0 |

---

## 🧪 10. Tests

### 10.1. Tests RSpec

**Fichiers de tests** :
- ✅ [`spec/mailers/user_mailer_spec.rb`](../spec/mailers/user_mailer_spec.rb) - Tests `welcome_email`
- ✅ [`spec/mailers/event_mailer_spec.rb`](../spec/mailers/event_mailer_spec.rb) - Tests `attendance_confirmed`, `attendance_cancelled`, `event_reminder`, `event_rejected`, `waitlist_spot_available`
- ✅ [`spec/mailers/membership_mailer_spec.rb`](../spec/mailers/membership_mailer_spec.rb) - Tests `activated`, `expired`, `renewal_reminder`, `payment_failed`
- ✅ [`spec/mailers/order_mailer_spec.rb`](../spec/mailers/order_mailer_spec.rb) - Tests `order_confirmation`, `order_paid`, `order_cancelled`, `order_preparation`, `order_shipped`, `refund_requested`, `refund_confirmed`
- ✅ [`spec/jobs/event_reminder_job_spec.rb`](../spec/jobs/event_reminder_job_spec.rb) - Tests complets du job (filtres, préférences, scopes)
- ✅ [`spec/requests/event_email_integration_spec.rb`](../spec/requests/event_email_integration_spec.rb) - Tests d'intégration emails événements

**Tests de preview** :
- [`spec/mailers/previews/membership_mailer_preview.rb`](../spec/mailers/previews/membership_mailer_preview.rb) - Preview des emails MembershipMailer

**Exécution** :
```bash
# Tous les tests mailers
bundle exec rspec spec/mailers/

# Tests spécifiques
bundle exec rspec spec/mailers/event_mailer_spec.rb
bundle exec rspec spec/jobs/event_reminder_job_spec.rb
```

---

### 10.2. Script de Test SMTP

**Fichier** : [`bin/test-mailer`](../bin/test-mailer)

**Usage** :
```bash
docker compose -f ops/dev/docker-compose.yml run --rm \
  -e BUNDLE_PATH=/rails/vendor/bundle \
  web bundle exec ruby bin/test-mailer votre-email@example.com
```

---

## 🔒 11. Sécurité Email

### 11.1. EmailSecurityService

**Fichier** : [`app/services/email_security_service.rb`](../app/services/email_security_service.rb)

**Fonctionnalités** :
- ✅ Détection email scanner (auto-click < 10 secondes)
- ✅ Détection brute force (tentatives multiples)
- ✅ Logging sécurisé des alertes
- ✅ Intégration Sentry (alertes automatiques)

**Références** :
- Documentation complète : [`docs/04-rails/security/email-security-service.md`](../security/email-security-service.md)

---

## 🚨 12. Points Critiques Identifiés - Audit Complet

### 🔴 CRITIQUES (À faire ASAP)

#### 1. ✅ Rake Tasks avec deliver_now = CORRIGÉ

**Problème identifié** :
- ~~[`lib/tasks/memberships.rake`](../lib/tasks/memberships.rake) (lignes 15, 34) utilise `deliver_now` pour `expired` et `renewal_reminder`~~
- ~~**Risque** : Si SMTP timeout → rake task échoue sans retry~~
- ~~**Impact** : Les emails ne sont pas envoyés et la task échoue complètement~~

**✅ CORRIGÉ** :
- `deliver_now` remplacé par `deliver_later` dans [`lib/tasks/memberships.rake`](../lib/tasks/memberships.rake) (lignes 20, 43)
- Les emails sont maintenant traités de manière asynchrone via SolidQueue avec retry automatique
- Messages d'erreur mis à jour : "Failed to send" → "Failed to queue"

**Code corrigé** :
```ruby
# lib/tasks/memberships.rake ligne 20
MembershipMailer.expired(membership).deliver_later if defined?(MembershipMailer)

# lib/tasks/memberships.rake ligne 43
MembershipMailer.renewal_reminder(membership).deliver_later if defined?(MembershipMailer)
```

**Références** :
- Fichier : [`lib/tasks/memberships.rake`](../lib/tasks/memberships.rake) (lignes 20, 43)
- SolidQueue config : [`config/queue.yml`](../config/queue.yml)

---

#### 2. ✅ Flags de Suivi Manquants = CORRIGÉ

**Problème identifié** :
- ~~`reminder_sent_at` : **N'existe PAS** dans [`db/schema.rb`](../db/schema.rb) table `attendances`~~
- ~~`renewal_reminder_sent_at` : **N'existe PAS** dans [`db/schema.rb`](../db/schema.rb) table `memberships`~~
- ~~`expired_email_sent_at` : **N'existe PAS** dans [`db/schema.rb`](../db/schema.rb) table `memberships`~~

**✅ CORRIGÉ** :

**Migrations créées** :
1. ✅ [`db/migrate/20251220042130_add_reminder_sent_at_to_attendances.rb`](../db/migrate/20251220042130_add_reminder_sent_at_to_attendances.rb) - Ajoute `reminder_sent_at` (datetime) à `attendances`
2. ✅ [`db/migrate/20251220042131_add_email_flags_to_memberships.rb`](../db/migrate/20251220042131_add_email_flags_to_memberships.rb) - Ajoute `renewal_reminder_sent_at` et `expired_email_sent_at` (datetime) à `memberships`

**Code modifié** :
1. ✅ [`app/jobs/event_reminder_job.rb`](../app/jobs/event_reminder_job.rb) (ligne 24) : Filtre `.where(reminder_sent_at: nil)` + mise à jour du flag (ligne 38)
2. ✅ [`lib/tasks/memberships.rake`](../lib/tasks/memberships.rake) :
   - Task `update_expired` (ligne 10) : Filtre `.where(expired_email_sent_at: nil)` + mise à jour du flag (ligne 14)
   - Task `send_renewal_reminders` (ligne 39) : Filtre `.where(renewal_reminder_sent_at: nil)` + mise à jour du flag (ligne 45)

**Protection implémentée** :
- ✅ Filtres `.where(..._sent_at: nil)` empêchent les doublons
- ✅ Flags mis à jour avec `update_column` après l'envoi
- ✅ Protection contre les relances de cron

**Références** :
- Migrations : [`db/migrate/20251220042130_add_reminder_sent_at_to_attendances.rb`](../db/migrate/20251220042130_add_reminder_sent_at_to_attendances.rb), [`db/migrate/20251220042131_add_email_flags_to_memberships.rb`](../db/migrate/20251220042131_add_email_flags_to_memberships.rb)
- EventReminderJob : [`app/jobs/event_reminder_job.rb`](../app/jobs/event_reminder_job.rb) (lignes 24, 38)
- Rake tasks : [`lib/tasks/memberships.rake`](../lib/tasks/memberships.rake) (lignes 10, 14, 39, 45)

---

#### 3. ✅ SolidQueue - Architecture Actuelle (2025-01-13)

**Architecture réelle** :
- **SolidQueue** : Gère TOUS les jobs (asynchrones ET récurrents)
  - **Jobs asynchrones** (`deliver_later`) : Configuration via [`config/queue.yml`](../config/queue.yml)
  - **Jobs récurrents** : Configuration via [`config/recurring.yml`](../config/recurring.yml) ✅ **UTILISÉ**
  - Plugin Puma : [`config/puma.rb`](../config/puma.rb) (ligne 38) - `plugin :solid_queue if ENV["SOLID_QUEUE_IN_PUMA"]`
  - Variable env : `SOLID_QUEUE_IN_PUMA: true` dans [`config/deploy.yml`](../config/deploy.yml) (ligne 41)
  - Configuration ActiveJob : [`config/environments/production.rb`](../config/environments/production.rb) (ligne 56) - `config.active_job.queue_adapter = :solid_queue`
  - Base de données : PostgreSQL (via `config.solid_queue.connects_to = { database: { writing: :queue } }`)

**Architecture actuelle** :

```
┌─────────────────────────────────────────────────────────────┐
│                    SYSTÈME DE JOBS                          │
└─────────────────────────────────────────────────────────────┘

1. JOBS RÉCURRENTS (SolidQueue) ✅ FONCTIONNE
   ├─ Configuration : config/recurring.yml
   ├─ Chargement : Automatique par Solid Queue au démarrage
   ├─ Tables : solid_queue_recurring_tasks, solid_queue_recurring_executions
   └─ Jobs configurés :
      ├─ EventReminderJob (19h quotidien) ✅
      ├─ SyncHelloAssoPaymentsJob (toutes les 5 minutes) ✅
      ├─ UpdateExpiredMembershipsJob (minuit quotidien) ✅
      ├─ SendRenewalRemindersJob (9h quotidien) ✅
      └─ clear_solid_queue_finished_jobs (toutes les heures) ✅

2. JOBS ACTIVEJOB ASYNCHRONES (SolidQueue) ✅ FONCTIONNE
   ├─ Configuration : config/queue.yml
   ├─ Plugin Puma : config/puma.rb ligne 38
   ├─ Variable env : SOLID_QUEUE_IN_PUMA=true
   └─ Jobs :
      └─ Tous les deliver_later (emails, etc.) ✅

3. SUPERCRONIC (⚠️ DÉPRÉCIÉ - Migration terminée)
   ├─ Source : config/schedule.rb (Whenever) - Conservé pour référence uniquement
   ├─ Généré : config/crontab (Supercronic) - Conservé pour référence uniquement
   ├─ Démarrage : bin/docker-entrypoint (lignes 68-82) - Non utilisé
   └─ Status : ✅ **Migration terminée** - Tous les jobs sont dans Solid Queue
```

**✅ Migration vers Solid Queue - TERMINÉE** :

Tous les jobs récurrents sont maintenant configurés dans `config/recurring.yml` et exécutés automatiquement par Solid Queue :
- ✅ `EventReminderJob` : 19h quotidien
- ✅ `SyncHelloAssoPaymentsJob` : Toutes les 5 minutes
- ✅ `UpdateExpiredMembershipsJob` : Minuit quotidien
- ✅ `SendRenewalRemindersJob` : 9h quotidien
- ✅ `clear_solid_queue_finished_jobs` : Toutes les heures

**Vérification** :
```bash
# Vérifier que les jobs récurrents sont chargés
docker exec grenoble-roller-production bin/rails runner "puts SolidQueue::RecurringTask.count"
# Doit retourner 5 (nombre de jobs configurés)

# Vérifier les jobs récurrents enregistrés
docker exec grenoble-roller-production bin/rails runner "SolidQueue::RecurringTask.all.each { |t| puts \"#{t.key}: #{t.schedule}\" }"
```

**✅ SolidQueue charge automatiquement `config/recurring.yml`** :
- Solid Queue lit automatiquement `config/recurring.yml` au démarrage
- Les jobs récurrents sont enregistrés dans `solid_queue_recurring_tasks`
- Le scheduler Solid Queue enqueue les jobs selon leur schedule
- Voir [`docs/04-rails/background-jobs/CRON.md`](../background-jobs/CRON.md) pour la documentation complète

**Références** :
- Recurring config : [`config/recurring.yml`](../config/recurring.yml) ✅ **UTILISÉ** par SolidQueue
- Queue config : [`config/queue.yml`](../config/queue.yml) ✅ Utilisé par SolidQueue pour deliver_later
- Puma config : [`config/puma.rb`](../config/puma.rb) (ligne 38 - plugin SolidQueue)
- Deploy config : [`config/deploy.yml`](../config/deploy.yml) (ligne 41 - SOLID_QUEUE_IN_PUMA: true)
- Production config : [`config/environments/production.rb`](../config/environments/production.rb) (ligne 56 - queue_adapter = :solid_queue)
- Staging config : [`config/environments/staging.rb`](../config/environments/staging.rb) (ligne 45 - queue_adapter = :solid_queue)
- SolidQueue initializer : [`config/initializers/solid_queue.rb`](../config/initializers/solid_queue.rb)
- Documentation jobs récurrents : [`docs/04-rails/background-jobs/CRON.md`](../background-jobs/CRON.md) (Solid Queue actif, migration terminée)
- Schedule config (déprécié) : [`config/schedule.rb`](../config/schedule.rb) (⚠️ Conservé pour référence uniquement, migration terminée)
- Crontab généré (déprécié) : [`config/crontab`](../config/crontab) (⚠️ Conservé pour référence uniquement, migration terminée)

---

### 🟡 À VÉRIFIER (Important)

#### 4. ⚠️ Callback notify_waitlist_if_needed - Ordre et Race Conditions

**Problème identifié** :
- [`app/models/attendance.rb`](../app/models/attendance.rb) (ligne 42) : `after_destroy :notify_waitlist_if_needed`
- [`app/models/waitlist_entry.rb`](../app/models/waitlist_entry.rb) (ligne 231) : `EventMailer.waitlist_spot_available(self).deliver_now`
- **Question** : Ordre des callbacks, pas de race condition avec attendances ?

**Ordre des callbacks dans Attendance** :
1. `after_destroy :notify_waitlist_if_needed`
2. `after_update :notify_waitlist_on_cancellation` — si statut passe à `canceled`

**Roller stock :** les callbacks `increment_roller_stock` / `decrement_roller_stock` ont été **supprimés** (v2.3) — voir [`docs/06-events/roller-stock.md`](../../06-events/roller-stock.md).

**Logique notify_waitlist_if_needed** :
- Vérifie si `status == "pending"` → skip (ligne 299)
- Vérifie si `is_volunteer` → skip (ligne 302)
- Recharge l'événement pour avoir le bon comptage (ligne 305)
- Vérifie si `event.has_available_spots?` (ligne 308)
- Appelle `WaitlistEntry.notify_next_in_queue(event, count: 1)` (ligne 310)

**Risques identifiés** :
- ⚠️ Race condition possible si plusieurs attendances supprimées simultanément
- ⚠️ `deliver_now` utilisé (time-sensitive, justifié mais à documenter)

**Action requise** :
1. Vérifier l'ordre des callbacks (actuellement correct)
2. Documenter pourquoi `deliver_now` est utilisé (24h deadline)
3. Vérifier s'il y a des locks nécessaires pour éviter race conditions

**Références** :
- Modèle Attendance : [`app/models/attendance.rb`](../app/models/attendance.rb) (callbacks lignes 38-43, méthode `notify_waitlist_if_needed` lignes 295-313)
- Modèle WaitlistEntry : [`app/models/waitlist_entry.rb`](../app/models/waitlist_entry.rb) (méthode `send_notification_email` ligne 229)

---

#### 5. ⚠️ Scope Attendance.active - Statuts Exclus

**Problème identifié** :
- [`app/models/attendance.rb`](../app/models/attendance.rb) (ligne 45) : `scope :active, -> { where.not(status: "canceled") }`
- **Question** : Exclut "canceled" mais `no_show` ? Tous les statuts documentés ?

**Statuts disponibles** (voir [`app/models/attendance.rb`](../app/models/attendance.rb) lignes 9-16) :
- `pending` : En attente de confirmation (liste d'attente)
- `registered` : Inscrit
- `paid` : Payé
- `canceled` : Annulé ❌ **EXCLU du scope active**
- `present` : Présent
- `no_show` : Absent ⚠️ **INCLUS dans le scope active**

**Impact pour EventReminderJob** :
- Les attendances avec statut `no_show` **SERONT** incluses dans les rappels
- **Question métier** : Est-ce voulu ? Un `no_show` devrait-il recevoir un rappel ?

**Action requise** :
1. Clarifier la règle métier : `no_show` doit-il être exclu du scope `active` ?
2. Si oui, modifier le scope : `.where.not(status: ["canceled", "no_show"])`
3. Mettre à jour [`EventReminderJob`](../app/jobs/event_reminder_job.rb) si nécessaire

**Références** :
- Modèle Attendance : [`app/models/attendance.rb`](../app/models/attendance.rb) (enum `status` lignes 9-16, scope `active` ligne 45)
- EventReminderJob : [`app/jobs/event_reminder_job.rb`](../app/jobs/event_reminder_job.rb) (utilise `.active` ligne 21)

---

#### 6. ⚠️ Initiation vs Event - STI (Single Table Inheritance)

**Problème identifié** :
- [`app/models/event/initiation.rb`](../app/models/event/initiation.rb) : `class Event::Initiation < Event`
- C'est du **STI (Single Table Inheritance)** - même table `events`, différencié par colonne `type`
- **Question** : Tous les filtres retournent les 2 types ?

**Vérification des scopes** :
- `Event.published` : Retourne **TOUS** les événements publiés (initiations + événements généraux)
- `Event.upcoming` : Retourne **TOUS** les événements à venir (initiations + événements généraux)
- `Event.not_initiations` : Scope défini dans [`app/models/event.rb`](../app/models/event.rb) (ligne 102) : `.where(type: [ nil, "Event" ])`

**Impact pour EventReminderJob** :
- Le job traite **TOUS** les événements publiés du lendemain (initiations + événements généraux)
- Filtre ensuite par `is_initiation` pour appliquer `wants_initiation_mail` (lignes 18, 28-30)

**Action requise** :
1. ✅ **Comportement correct** : Le job doit traiter initiations ET événements généraux
2. Documenter que c'est du STI et que les scopes incluent les 2 types
3. Vérifier que tous les filtres sont cohérents

**Références** :
- Modèle Event : [`app/models/event.rb`](../app/models/event.rb) (scopes `published` ligne 96, `upcoming` ligne 94, `not_initiations` ligne 102)
- Modèle Event::Initiation : [`app/models/event/initiation.rb`](../app/models/event/initiation.rb) (STI)
- EventReminderJob : [`app/jobs/event_reminder_job.rb`](../app/jobs/event_reminder_job.rb) (détection STI ligne 18)

---

#### 7. ⚠️ Préférence wants_events_mail - Logique au Niveau Controller

**Problème identifié** :
- `wants_events_mail` est filtrée au **niveau controller**, pas dans le mailer
- **Question** : Volontaire ou à unifier ?

**Utilisation actuelle** :
- [`app/controllers/events/attendances_controller.rb`](../app/controllers/events/attendances_controller.rb) (lignes 93, 97) : Filtre `wants_events_mail` avant `attendance_cancelled`
- [`app/controllers/events/waitlist_entries_controller.rb`](../app/controllers/events/waitlist_entries_controller.rb) (ligne 117) : Filtre `wants_events_mail` avant `attendance_confirmed`
- [`app/controllers/memberships_controller.rb`](../app/controllers/memberships_controller.rb) : Utilisé lors de la création d'adhésion

**Comparaison avec `wants_initiation_mail`** :
- `wants_initiation_mail` : Filtré dans [`EventReminderJob`](../app/jobs/event_reminder_job.rb) (ligne 29) ET dans controllers
- `wants_events_mail` : Filtré **uniquement** dans controllers

**Action requise** :
1. ✅ **Comportement cohérent** : Filtrage au niveau controller est correct pour les emails déclenchés par actions utilisateur
2. Documenter que `wants_events_mail` est pour les emails déclenchés par actions utilisateur (pas jobs automatiques)
3. Vérifier que tous les emails d'événements généraux respectent cette préférence

**Références** :
- Controllers : [`app/controllers/events/attendances_controller.rb`](../app/controllers/events/attendances_controller.rb), [`app/controllers/events/waitlist_entries_controller.rb`](../app/controllers/events/waitlist_entries_controller.rb)
- EventReminderJob : [`app/jobs/event_reminder_job.rb`](../app/jobs/event_reminder_job.rb) (utilise `wants_initiation_mail` pour initiations uniquement)

---

#### 8. ⚠️ Timing Cron Conflicts - Ordre des Jobs

**Problème identifié** :
- **00:00** : `memberships:update_expired` (voir [`config/schedule.rb`](../config/schedule.rb) ligne 19)
- **05:00** : Pas de job configuré
- **09:00** : `memberships:send_renewal_reminders` (voir [`config/schedule.rb`](../config/schedule.rb) ligne 24)
- **19:00** : `EventReminderJob` (voir [`config/schedule.rb`](../config/schedule.rb) ligne 14)
- **Toutes les 5 min** : `helloasso:sync_payments` (voir [`config/schedule.rb`](../config/schedule.rb) ligne 9)

**Question** : Risques de chevauchement ?

**Analyse** :
- ✅ Pas de conflit temporel direct (horaires différents)
- ⚠️ `helloasso:sync_payments` toutes les 5 min peut chevaucher avec les autres jobs
- ⚠️ Si un job prend plus de 5 minutes, le suivant peut démarrer avant la fin

**Action requise** :
1. Vérifier les durées d'exécution des jobs
2. Documenter les risques de chevauchement
3. Considérer l'ajout de locks si nécessaire

**Références** :
- Schedule config : [`config/schedule.rb`](../config/schedule.rb) (toutes les tâches)
- Crontab généré : [`config/crontab`](../config/crontab) (format cron)

---

### 🟢 AMÉLIORATIONS (Court terme)

#### 9. ✅ Dashboard Admin pour Monitorer les Crons - Solution Proposée

**Problème** : Impossible de savoir si les crons tournent sans accéder au conteneur Docker.

**Solution** : Créer une page admin pour visualiser le statut de tous les crons en temps réel.

**Fichier à créer** : `app/views/admin/crons/status.html.erb`

**Code basique (sans CSS ni classes)** :

```erb
<div>
  <h1>Crons Status Dashboard</h1>
  
  <div>
    <div>
      <h3>HelloAsso Sync</h3>
      <p>Every 5 minutes</p>
      
      <div>
        <span></span>
        <%= @status[:helloasso_sync][:status].upcase %>
      </div>
      
      <div>
        <p><strong>Last Run:</strong> <%= @status[:helloasso_sync][:last_run]&.strftime('%Y-%m-%d %H:%M:%S') || 'Never' %></p>
        <p><strong>Pending Payments:</strong> <%= @status[:helloasso_sync][:pending_payments] %></p>
      </div>
      
      <button onclick="runCronNow('helloasso:sync_payments')">Run Now</button>
    </div>
    
    <div>
      <h3>Event Reminders</h3>
      <p>Daily at 19:00</p>
      
      <div>
        <span></span>
        <%= @status[:event_reminders][:status].upcase %>
      </div>
      
      <div>
        <p><strong>Last Run:</strong> <%= @status[:event_reminders][:last_run]&.strftime('%Y-%m-%d %H:%M:%S') || 'Never' %></p>
        <p><strong>Events Tomorrow:</strong> <%= @status[:event_reminders][:events_tomorrow] %></p>
      </div>
      
      <button onclick="runCronNow('EventReminderJob')">Run Now</button>
    </div>
    
    <div>
      <h3>Memberships Expired</h3>
      <p>Daily at 00:00</p>
      
      <div>
        <span></span>
        <%= @status[:memberships_expired][:status].upcase %>
      </div>
      
      <div>
        <p><strong>Last Run:</strong> <%= @status[:memberships_expired][:last_run]&.strftime('%Y-%m-%d %H:%M:%S') || 'Never' %></p>
        <p><strong>Expired Today:</strong> <%= @status[:memberships_expired][:expired_today] %></p>
      </div>
      
      <button onclick="runCronNow('memberships:update_expired')">Run Now</button>
    </div>
    
    <div>
      <h3>Renewal Reminders</h3>
      <p>Daily at 09:00</p>
      
      <div>
        <span></span>
        <%= @status[:renewal_reminders][:status].upcase %>
      </div>
      
      <div>
        <p><strong>Last Run:</strong> <%= @status[:renewal_reminders][:last_run]&.strftime('%Y-%m-%d %H:%M:%S') || 'Never' %></p>
        <p><strong>Expiring in 30 days:</strong> <%= @status[:renewal_reminders][:expiring_in_30_days] %></p>
      </div>
      
      <button onclick="runCronNow('memberships:send_renewal_reminders')">Run Now</button>
    </div>
  </div>
  
  <div>
    <h2>Recent Cron Logs</h2>
    <pre><%= File.read('log/cron.log').lines.last(50).join if File.exist?('log/cron.log') %></pre>
  </div>
</div>
```

**Controller à créer** : `app/controllers/admin/crons_controller.rb`

**Exemple de controller (code basique)** :

```ruby
class Admin::CronsController < ApplicationController
  before_action :authenticate_user!
  before_action :ensure_admin
  
  def status
    @status = {
      helloasso_sync: {
        status: check_cron_status('helloasso:sync_payments'),
        last_run: get_last_run_time('helloasso:sync_payments'),
        pending_payments: Payment.where(status: :pending).where('created_at > ?', 24.hours.ago).count
      },
      event_reminders: {
        status: check_cron_status('EventReminderJob'),
        last_run: get_last_run_time('EventReminderJob'),
        events_tomorrow: Event.published.upcoming.where(start_at: (Time.zone.now.beginning_of_day + 1.day)..(Time.zone.now.end_of_day + 1.day)).count
      },
      memberships_expired: {
        status: check_cron_status('memberships:update_expired'),
        last_run: get_last_run_time('memberships:update_expired'),
        expired_today: Membership.where(status: :expired).where('updated_at > ?', Time.zone.now.beginning_of_day).count
      },
      renewal_reminders: {
        status: check_cron_status('memberships:send_renewal_reminders'),
        last_run: get_last_run_time('memberships:send_renewal_reminders'),
        expiring_in_30_days: Membership.where(status: :active).where(end_date: 30.days.from_now.to_date).count
      }
    }
  end
  
  def run_now
    cron_name = params[:cron_name]
    
    case cron_name
    when 'helloasso:sync_payments'
      Rake::Task['helloasso:sync_payments'].invoke
    when 'EventReminderJob'
      EventReminderJob.perform_now
    when 'memberships:update_expired'
      Rake::Task['memberships:update_expired'].invoke
    when 'memberships:send_renewal_reminders'
      Rake::Task['memberships:send_renewal_reminders'].invoke
    end
    
    redirect_to admin_crons_status_path, notice: "Cron #{cron_name} exécuté avec succès"
  rescue => e
    redirect_to admin_crons_status_path, alert: "Erreur: #{e.message}"
  end
  
  private
  
  def ensure_admin
    redirect_to root_path unless current_user&.admin?
  end
  
  def check_cron_status(cron_name)
    # Vérifier si Supercronic tourne
    supercronic_running = system('pgrep -f supercronic > /dev/null 2>&1')
    return 'unknown' unless supercronic_running
    
    # Vérifier dernière exécution (basé sur logs ou flags)
    last_run = get_last_run_time(cron_name)
    return 'unknown' if last_run.nil?
    
    # Déterminer si healthy basé sur dernière exécution
    case cron_name
    when 'helloasso:sync_payments'
      last_run > 10.minutes.ago ? 'healthy' : 'unknown'
    when 'EventReminderJob'
      # Vérifier si exécuté aujourd'hui à 19h
      today_19h = Time.zone.now.beginning_of_day + 19.hours
      (last_run >= today_19h && last_run < today_19h + 1.hour) ? 'healthy' : 'unknown'
    when 'memberships:update_expired'
      last_run > Time.zone.now.beginning_of_day ? 'healthy' : 'unknown'
    when 'memberships:send_renewal_reminders'
      last_run > Time.zone.now.beginning_of_day ? 'healthy' : 'unknown'
    else
      'unknown'
    end
  end
  
  def get_last_run_time(cron_name)
    # Méthode 1 : Lire depuis log/cron.log
    if File.exist?('log/cron.log')
      log_content = File.read('log/cron.log')
      # Chercher dernière ligne contenant le nom du cron
      matching_lines = log_content.lines.select { |line| line.include?(cron_name) }
      return nil if matching_lines.empty?
      # Extraire timestamp de la dernière ligne (format à adapter selon vos logs)
      # Exemple: "2025-12-20 19:00:01 - EventReminderJob.perform_now"
      last_line = matching_lines.last
      # Parser le timestamp (à adapter selon format réel)
      # Time.zone.parse(...)
    end
    
    # Méthode 2 : Utiliser les flags de suivi (reminder_sent_at, etc.)
    case cron_name
    when 'EventReminderJob'
      Attendance.where.not(reminder_sent_at: nil).maximum(:reminder_sent_at)
    when 'memberships:update_expired'
      Membership.where.not(expired_email_sent_at: nil).maximum(:expired_email_sent_at)
    when 'memberships:send_renewal_reminders'
      Membership.where.not(renewal_reminder_sent_at: nil).maximum(:renewal_reminder_sent_at)
    end
  end
end
```

**Routes à ajouter dans `config/routes.rb`** :

```ruby
namespace :admin do
  resources :crons, only: [] do
    collection do
      get :status
      post :run_now
    end
  end
end
```

**JavaScript pour le bouton "Run Now"** :

```javascript
function runCronNow(cronName) {
  if (confirm('Exécuter ' + cronName + ' maintenant ?')) {
    const form = document.createElement('form');
    form.method = 'POST';
    form.action = '/admin/crons/run_now';
    
    const input = document.createElement('input');
    input.type = 'hidden';
    input.name = 'cron_name';
    input.value = cronName;
    form.appendChild(input);
    
    const token = document.querySelector('meta[name="csrf-token"]');
    if (token) {
      const csrfInput = document.createElement('input');
      csrfInput.type = 'hidden';
      csrfInput.name = 'authenticity_token';
      csrfInput.value = token.content;
      form.appendChild(csrfInput);
    }
    
    document.body.appendChild(form);
    form.submit();
  }
}
```

**Logique nécessaire** :
- Récupérer le statut de chaque cron (dernière exécution, nombre d'éléments à traiter)
- Permettre l'exécution manuelle via bouton "Run Now"
- Afficher les logs récents depuis `log/cron.log`
- Vérifier si Supercronic tourne (processus `pgrep -f supercronic`)

**Bénéfices** :
- ✅ Visualisation en temps réel du statut des crons
- ✅ Exécution manuelle possible (dépannage)
- ✅ Consultation des logs sans accès SSH/Docker
- ✅ Détection rapide des crons inactifs
- ✅ Vérification si Supercronic tourne

**Références** :
- Vue : `app/views/admin/crons/status.html.erb` (à créer)
- Controller : `app/controllers/admin/crons_controller.rb` (à créer)
- Routes : Ajouter dans `config/routes.rb` sous namespace `admin`

#### 10. Error Handling
- Gestion d'erreurs SMTP plus robuste
- Retry automatique avec backoff exponentiel
- Notification admin si échecs répétés

#### 11. ✅ Timezone Edges - Configuration Manquante = CORRIGÉ

**Problème identifié** :
- ~~Le fuseau horaire n'est **PAS configuré** dans [`config/application.rb`](../config/application.rb) (ligne 25 commentée)~~
- ~~**Risque** : Utilise le fuseau horaire système (peut varier selon serveur)~~
- ~~**Impact** : EventReminderJob utilise `Time.zone.now` qui peut être incorrect~~

**✅ CORRIGÉ** :
- Fuseau horaire configuré dans [`config/application.rb`](../config/application.rb) (ligne 27) : `config.time_zone = "Europe/Paris"`
- Commentaires ajoutés expliquant l'importance pour EventReminderJob
- `Time.zone.now` utilisera maintenant systématiquement le fuseau horaire Europe/Paris

**Code corrigé** :
```ruby
# config/application.rb ligne 27
config.time_zone = "Europe/Paris"
```

**Bénéfices** :
- ✅ Comportement cohérent lors des changements d'heure (été/hiver)
- ✅ EventReminderJob calcule correctement les dates/heures
- ✅ Plus de dépendance au fuseau horaire système

**Références** :
- Application config : [`config/application.rb`](../config/application.rb) (ligne 27)
- EventReminderJob : [`app/jobs/event_reminder_job.rb`](../app/jobs/event_reminder_job.rb) (utilise `Time.zone.now` ligne 9)

#### 12. Tests de Charge
- Tester EventReminderJob avec 1000+ événements
- Tester avec 1000+ attendances par événement
- Vérifier performance SolidQueue

#### 13. DKIM/SPF Audit
- Vérifier configuration DKIM pour grenoble-roller.org
- Vérifier SPF records
- Tester deliverabilité (Mail-Tester, etc.)

#### 14. Dashboard Admin
- Statistiques emails par type
- Taux d'ouverture/clics (si tracking configuré)
- Logs des envois

---

## 📝 13. Points d'Attention / Actions Requises (Ancienne Section - Voir Section 12 pour Audit Critique)

### 🔴 Priorité Haute (Points Critiques - Voir Section 12)

**⚠️ IMPORTANT** : Les points critiques sont maintenant documentés dans la **Section 12** ci-dessus. Cette section conserve les points d'attention généraux.

#### 1. ✅ Rappels Bénévoles - Vérifié

**Statut** : ✅ **VÉRIFIÉ**

**Résultat** : Les bénévoles reçoivent le **même email** que les participants.

**État actuel** :
- ✅ `EventReminderJob` envoie le même email aux bénévoles et participants
- ✅ Pas de distinction dans les templates
- ✅ Pas de préférence spécifique pour les bénévoles
- ✅ Le champ `is_volunteer` n'est **pas utilisé** dans `EventReminderJob`

**Conclusion** :
- Comportement actuel : Bénévoles = même rappel que participants
- Si besoin de rappels spécifiques : créer `volunteer_reminder(attendance)` dans `EventMailer` et adapter `EventReminderJob`

**Références** :
- Modèle Attendance : [`app/models/attendance.rb`](../app/models/attendance.rb) (champ `is_volunteer`)
- EventReminderJob : [`app/jobs/event_reminder_job.rb`](../app/jobs/event_reminder_job.rb) (lignes 20-34)

---

#### 2. ✅ Préférences Email Utilisateur - Vérifié

**Statut** : ✅ **VÉRIFIÉ**

**Résultat** : Les préférences email sont **implémentées et utilisées**.

**État actuel** :
- ✅ Migration `20251201020755_add_email_preferences_to_users.rb` existe
- ✅ Champs dans `users` table : `wants_initiation_mail` (boolean, default: true), `wants_events_mail` (boolean, default: true)
- ✅ Formulaire de préférences : [`app/views/devise/registrations/edit.html.erb`](../app/views/devise/registrations/edit.html.erb) (lignes 191-207)
- ✅ `wants_initiation_mail` utilisé dans `EventReminderJob` (ligne 29)
- ✅ `wants_events_mail` utilisé dans :
  - `app/controllers/events/attendances_controller.rb` (lignes 93, 97) - pour `attendance_cancelled`
  - `app/controllers/events/waitlist_entries_controller.rb` (ligne 117) - pour `attendance_confirmed`
  - `app/controllers/memberships_controller.rb` (plusieurs lignes) - lors de la création d'adhésion

**Utilisation** :
- `wants_initiation_mail` : Filtre les emails de rappel pour les initiations dans `EventReminderJob`
- `wants_events_mail` : Filtre les emails de confirmation/annulation pour les événements généraux

**Références** :
- Migration : [`db/migrate/20251201020755_add_email_preferences_to_users.rb`](../db/migrate/20251201020755_add_email_preferences_to_users.rb)
- Formulaire : [`app/views/devise/registrations/edit.html.erb`](../app/views/devise/registrations/edit.html.erb)
- EventReminderJob : [`app/jobs/event_reminder_job.rb`](../app/jobs/event_reminder_job.rb)

---

### 🟡 Priorité Moyenne

#### 3. ✅ Vérification Utilisation `deliver_later` - Vérifié

**Statut** : ✅ **VÉRIFIÉ**

**Résultat** : Tous les appels utilisent `deliver_later` sauf **1 exception justifiée**.

**État actuel** :
- ✅ UserMailer : `deliver_later` (ligne 170 user.rb)
- ✅ EventMailer : `deliver_later` (tous les appels sauf 1)
- ✅ OrderMailer : `deliver_later` (tous les appels)
- ✅ MembershipMailer : `deliver_later` (tous les appels)

**Exceptions justifiées** :
- ⚠️ `WaitlistEntry#send_notification_email` : `deliver_now` (ligne 231)
  - **Raison** : Notification immédiate d'une place disponible (time-sensitive)
  - **Justification** : L'utilisateur a 24h pour confirmer, donc l'email doit être envoyé immédiatement
  - **Fichier** : [`app/models/waitlist_entry.rb`](../app/models/waitlist_entry.rb) (ligne 231)

**⚠️ PROBLÈME IDENTIFIÉ** :
- ⚠️ `lib/tasks/memberships.rake` : `deliver_now` (lignes 15, 34)
  - **Raison actuelle** : Exécution dans rake task cron
  - **Problème** : Si SMTP timeout → rake task échoue sans retry
  - **Action requise** : Changer en `deliver_later` + vérifier SolidQueue actif
  - **Fichier** : [`lib/tasks/memberships.rake`](../lib/tasks/memberships.rake) (lignes 15, 34)
  - **Voir Section 12.1** pour détails complets

**Conclusion** :
- ✅ Tous les appels utilisent `deliver_later` sauf :
  - Notification liste d'attente (justifié - time-sensitive)
  - **Rake tasks memberships (⚠️ À CORRIGER - voir Section 12.1)**

**Références** :
- WaitlistEntry : [`app/models/waitlist_entry.rb`](../app/models/waitlist_entry.rb) (ligne 231)
- Rake tasks : [`lib/tasks/memberships.rake`](../lib/tasks/memberships.rake) (lignes 15, 34) - ⚠️ À CORRIGER

---

#### 4. ✅ Flags de Suivi (Doublons) - Vérifié

**Statut** : ✅ **VÉRIFIÉ**

**Résultat** : Les flags de suivi **n'existent PAS** dans la base de données.

**État actuel** :
- ❌ `renewal_reminder_sent_at` : **N'existe PAS** dans `memberships` table
- ❌ `reminder_sent_at` : **N'existe PAS** dans `attendances` table
- ❌ `expired_email_sent_at` : **N'existe PAS** dans `memberships` table

**Risque identifié** :
- ⚠️ `renewal_reminder` : Risque d'envoyer plusieurs fois si job exécuté plusieurs fois
- ⚠️ `event_reminder` : Risque d'envoyer plusieurs fois si job exécuté plusieurs fois
- ⚠️ `expired` : Risque d'envoyer plusieurs fois si rake task exécuté plusieurs fois

**Actions recommandées** (Priorité Haute - Voir Section 12.2) :
1. Ajouter `renewal_reminder_sent_at` (datetime) dans `memberships` table
2. Ajouter `reminder_sent_at` (datetime) dans `attendances` table
3. Ajouter `expired_email_sent_at` (datetime) dans `memberships` table
4. Vérifier avant envoi si déjà envoyé (si flag présent et < 24h, skip)
5. Modifier [`app/jobs/event_reminder_job.rb`](../app/jobs/event_reminder_job.rb) pour vérifier `reminder_sent_at`
6. Modifier [`lib/tasks/memberships.rake`](../lib/tasks/memberships.rake) pour vérifier les flags avant envoi

**Références** :
- Schema : [`db/schema.rb`](../db/schema.rb) (tables `memberships` et `attendances`)
- **Voir Section 12.2** pour détails complets et plan d'action

---

### 🟢 Priorité Basse / Améliorations

#### 5. Templates Email - Compatibilité

**Actions recommandées** :
- Tester sur différents clients (Gmail, Outlook, Apple Mail)
- Vérifier styles inline pour compatibilité
- Tester responsive mobile

---

#### 6. Statistiques et Tracking

**Actions recommandées** :
- Suivi des ouvertures/clics (si service email tracking configuré)
- Dashboard admin avec statistiques emails
- Métriques par type d'email

---

## 🔗 14. Références Documentation

### Documentation Principale

- **Récapitulatif emails** : [`docs/04-rails/setup/emails-recapitulatif.md`](../setup/emails-recapitulatif.md)
- **Confirmation email** : [`docs/04-rails/setup/email-confirmation.md`](../setup/email-confirmation.md)
- **Welcome email** : [`docs/04-rails/setup/user-mailer-welcome.md`](../setup/user-mailer-welcome.md)
- **Sécurité email** : [`docs/04-rails/security/email-security-service.md`](../security/email-security-service.md)

### Documentation Événements

- **Emails événements** : [`docs/06-events/event-reminder-job.md`](../../06-events/event-reminder-job.md)
- **Job rappel** : [`docs/06-events/event-reminder-job.md`](../../06-events/event-reminder-job.md)

### Documentation Produit

- **Emails commandes** : [`docs/09-product/orders-workflow-emails.md`](../../09-product/orders-workflow-emails.md)
- **Emails adhésions** : [`docs/09-product/membership-mailer-emails.md`](../../09-product/membership-mailer-emails.md)

---

## 📋 15. Checklist de Vérification

### Mailers
- [x] EventMailer : 5 méthodes, tous templates créés
- [x] OrderMailer : 7 méthodes, tous templates créés
- [x] MembershipMailer : 4 méthodes, tous templates créés
- [x] UserMailer : 1 méthode, templates créés
- [x] DeviseMailer : Configuré

### Jobs Automatiques
- [x] EventReminderJob : Configuré (19h quotidien)
- [x] HelloAsso Sync : Configuré (5 min)
- [x] Memberships Expired : Configuré (00h quotidien)
- [x] Renewal Reminders : Configuré (09h quotidien)

### Configuration
- [x] SMTP configuré (développement, production, test)
- [x] Credentials Rails configurés
- [x] ApplicationMailer configuré
- [x] ActiveJob configuré (Solid Queue)

### Tests
- [x] Tests RSpec pour tous les mailers
- [x] Tests RSpec pour EventReminderJob
- [x] Tests d'intégration emails
- [x] Script test SMTP

### ✅ Points Vérifiés (Voir Section 12 pour Audit Critique)
- [x] Rappels bénévoles : Vérifié - même email que participants (Section 1.3)
- [x] Préférences email : Vérifié - formulaire et utilisation complète (Section 8)
- [x] Flags de suivi : Vérifié - n'existent PAS, risque identifié (Section 12.2)
- [x] deliver_later vs deliver_now : Vérifié - 2 exceptions justifiées + 2 à corriger (Section 12.1)
- [x] Architecture SolidQueue/Supercronic : Clarifiée (Section 12.3)

---

## 🎯 16. Améliorations Futures Possibles

### 1. ✅ Dashboard Admin pour Monitorer les Crons (Solution Proposée)

**Problème identifié** : Impossible de savoir si les crons tournent sans accéder au conteneur Docker.

**Solution** : Créer une page admin pour visualiser le statut de tous les crons en temps réel.

**Voir Section 12.9** pour le code complet (vue ERB, controller, routes, JavaScript).

---

### 2. Rappels Multiples
- Rappel à 48h, 24h, 1h avant événement
- Personnalisation horaire par utilisateur

### 2. Notifications Push
- Notifications in-app en plus de l'email
- Intégration service push (Firebase, OneSignal)

### 3. Templates Personnalisés
- Templates différents selon type d'adhésion (adulte/enfant, FFRS/Association)
- Templates saisonniers

### 4. Dashboard Admin
- Statistiques emails (envois, ouvertures, clics)
- Gestion préférences utilisateur
- Logs emails envoyés

### 5. Webhooks HelloAsso
- Alternative au polling (plus rapide)
- Notifications en temps réel

---

---

## 🔍 16. Diagnostic EventReminderJob - Problème Identifié

### ⚠️ Problème Signalé

**Symptôme** : Les utilisateurs cochent `wants_reminder: true` mais ne reçoivent pas les rappels.

### 🔎 Checklist de Diagnostic

#### 1. Vérifier que Supercronic est actif

```bash
# Vérifier le processus
docker exec grenoble-roller-production ps aux | grep supercronic

# Devrait afficher quelque chose comme :
# rails     1234  0.0  0.1  ... /usr/local/bin/supercronic /rails/config/crontab
```

**Si pas de processus** :
- Le fichier `/rails/config/crontab` n'existe peut-être pas
- Vérifier les logs du conteneur au démarrage : `docker logs grenoble-roller-production | grep -i supercronic`

---

#### 2. Vérifier que le fichier crontab existe et est correct

```bash
# Voir le contenu du fichier
docker exec grenoble-roller-production cat /rails/config/crontab

# Devrait contenir :
# 0 19 * * * /bin/bash -l -c 'cd /rails && bundle exec bin/rails runner -e "${RAILS_ENV:-production}" '\''EventReminderJob.perform_now'\'' >> log/cron.log 2>&1'
```

**Si le fichier n'existe pas** :
- Le script `install_crontab` n'a peut-être pas été exécuté lors du déploiement
- Installer manuellement : `./ops/scripts/update-crontab.sh production`

---

#### 3. Vérifier les logs d'exécution

```bash
# Logs des tâches cron (sortie des commandes)
docker exec grenoble-roller-production tail -f log/cron.log

# Vérifier les dernières exécutions
docker exec grenoble-roller-production tail -100 log/cron.log | grep EventReminderJob
```

**Si pas de logs** :
- Le job ne s'exécute pas (problème Supercronic ou crontab)
- Vérifier les logs du conteneur : `docker logs grenoble-roller-production`

---

#### 4. Tester manuellement le job

```bash
# Exécuter le job manuellement
docker exec grenoble-roller-production bin/rails runner "EventReminderJob.perform_now"

# Vérifier les emails envoyés (en développement)
# En production, vérifier les logs SMTP ou les emails reçus
```

**Si le job fonctionne manuellement mais pas automatiquement** :
- Problème de configuration Supercronic ou crontab
- Vérifier le fuseau horaire du conteneur

---

#### 5. Vérifier les préférences utilisateur

```ruby
# Rails console
docker exec -it grenoble-roller-production bin/rails console

# Vérifier les attendances avec wants_reminder
Attendance.where(wants_reminder: true).count

# Vérifier un événement du lendemain
tomorrow = Time.zone.now.beginning_of_day + 1.day
events = Event.published.upcoming.where(start_at: tomorrow.beginning_of_day..tomorrow.end_of_day)
events.count

# Vérifier les attendances pour ces événements
events.first.attendances.active.where(wants_reminder: true).count
```

---

#### 6. Vérifier la configuration du fuseau horaire

```bash
# Vérifier le fuseau horaire du conteneur
docker exec grenoble-roller-production date
docker exec grenoble-roller-production bin/rails runner "puts Time.zone.now"

# Vérifier la configuration Rails
docker exec grenoble-roller-production bin/rails runner "puts Rails.application.config.time_zone"
```

**Important** : Le job utilise `Time.zone.now` qui doit être configuré sur le fuseau horaire correct (Europe/Paris).

**✅ CORRIGÉ** :
- Le fuseau horaire est maintenant configuré dans [`config/application.rb`](../config/application.rb) (ligne 27) : `config.time_zone = "Europe/Paris"`
- ✅ Utilise systématiquement le fuseau horaire Europe/Paris
- **Voir Section 12.11** pour détails de la correction

---

#### 7. Vérifier que les emails sont bien envoyés

```bash
# Vérifier les logs SMTP
docker logs grenoble-roller-production | grep -i mail

# Vérifier les jobs ActiveJob en attente
docker exec grenoble-roller-production bin/rails runner "puts SolidQueue::Job.where(queue_name: 'default').count"
```

---

### 🛠️ Actions Correctives Possibles

#### Si Supercronic n'est pas lancé

1. Vérifier que le fichier crontab existe dans le conteneur
2. Vérifier les logs du conteneur au démarrage
3. Relancer le conteneur si nécessaire

#### Si le crontab n'est pas généré

1. Installer manuellement : `./ops/scripts/update-crontab.sh production`
2. Vérifier que `whenever` est disponible dans le conteneur
3. Vérifier les logs de déploiement

#### Si le job s'exécute mais pas d'emails

1. Vérifier la configuration SMTP
2. Vérifier les préférences utilisateur (`wants_reminder`, `wants_initiation_mail`)
3. Vérifier les logs ActiveJob
4. Tester manuellement l'envoi d'email

---

### 📋 Checklist Complète de Vérification

- [ ] Supercronic est actif (processus visible)
- [ ] Fichier `/rails/config/crontab` existe dans le conteneur
- [ ] Fichier crontab contient la ligne EventReminderJob
- [ ] Logs dans `log/cron.log` montrent l'exécution
- [ ] Job s'exécute manuellement sans erreur
- [ ] Préférences utilisateur correctes (`wants_reminder: true`)
- [ ] Événements du lendemain existent
- [ ] Configuration SMTP correcte
- [ ] Fuseau horaire correct (Europe/Paris)
- [ ] ActiveJob traite les emails (`deliver_later`)

---

**Dernière mise à jour** : 2025-12-20  
**Version** : 2.3  
**Statut** : ✅ Documentation complète + ✅ Corrections critiques implémentées (Points 1, 2, 11) + 🚨 **SITUATION CRITIQUE** : Supercronic ne tourne pas (Point 3)

---

## 📋 21. Plan d'Action Priorisé

### ✅ Actions Critiques (TERMINÉES)

#### 1. ✅ Corriger Rake Tasks deliver_now - TERMINÉ
**Fichier** : [`lib/tasks/memberships.rake`](../lib/tasks/memberships.rake)  
**Lignes** : 20, 43  
**Action** : ✅ Remplacé `deliver_now` par `deliver_later`  
**Impact** : ✅ Évite échec task si SMTP timeout  
**Temps réel** : 5 minutes

#### 2. ✅ Ajouter Flags de Suivi - TERMINÉ
**Fichiers** : Migrations créées + code modifié  
**Action** : ✅ Créé 3 migrations + modifié EventReminderJob et rake tasks  
**Impact** : ✅ Évite doublons d'emails  
**Temps réel** : 45 minutes (migrations + modifications code)

#### 3. ✅ Configurer Timezone - TERMINÉ
**Fichier** : [`config/application.rb`](../config/application.rb)  
**Ligne** : 27  
**Action** : ✅ Configuré `config.time_zone = "Europe/Paris"`  
**Impact** : ✅ Garantit bon fuseau horaire pour EventReminderJob  
**Temps réel** : 2 minutes

### 🟡 Actions Importantes (À vérifier)

### 🟡 Actions Importantes (À vérifier)

#### 4. Vérifier Scope active (no_show)
**Fichier** : [`app/models/attendance.rb`](../app/models/attendance.rb)  
**Ligne** : 45  
**Action** : Clarifier règle métier - `no_show` doit-il être exclu ?  
**Impact** : Affecte EventReminderJob  
**Temps estimé** : Discussion métier + 10 minutes si modification

#### 5. 🚨 URGENT - Corriger Supercronic (ne tourne pas)
**Fichiers** : [`bin/docker-entrypoint`](../bin/docker-entrypoint), [`ops/lib/deployment/cron.sh`](../ops/lib/deployment/cron.sh)  
**Action** : Diagnostiquer pourquoi Supercronic ne démarre pas et corriger  
**Impact** : **CRITIQUE** - Tous les jobs cron sont inactifs (EventReminderJob, HelloAsso sync, memberships tasks)  
**Temps estimé** : 1-2 heures (diagnostic + correction)

---

### ✅ Améliorations Implémentées (Bonus)

#### 6. ✅ Cohérence update_column
**Fichier** : [`lib/tasks/memberships.rake`](../lib/tasks/memberships.rake)  
**Action** : ✅ Remplacé `update!` par `update_column` partout  
**Impact** : ✅ Évite callbacks inutiles, plus performant

#### 7. ✅ Logging structuré
**Fichier** : [`lib/tasks/memberships.rake`](../lib/tasks/memberships.rake)  
**Action** : ✅ Remplacé tous les `puts` par `Rails.logger.info`  
**Impact** : ✅ Logs structurés, traçables dans fichiers de log

#### 8. ✅ Monitoring Sentry
**Fichier** : [`lib/tasks/memberships.rake`](../lib/tasks/memberships.rake)  
**Action** : ✅ Ajouté `Sentry.capture_exception` dans les blocs rescue  
**Impact** : ✅ Monitoring des erreurs avec contexte dans Sentry

### 🟢 Améliorations (Court terme)

#### 6-14. Monitoring, Error Handling, Tests, etc.
**Temps estimé** : 2-4 heures au total  
**Priorité** : Basse (améliorations, pas critiques)

---

## 📊 20. Résumé de l'Audit Critique

### 🔴 Points Critiques (À faire ASAP)

| # | Point | Fichier | Ligne | Action Requise | Priorité | Statut |
|---|-------|---------|-------|----------------|----------|--------|
| 1 | Rake tasks `deliver_now` | [`lib/tasks/memberships.rake`](../lib/tasks/memberships.rake) | 20, 43 | ✅ Changer en `deliver_later` | 🔴 CRITIQUE | ✅ TERMINÉ |
| 2 | Flags de suivi manquants | [`db/migrate/`](../db/migrate/) | - | ✅ Ajouter 3 migrations | 🔴 CRITIQUE | ✅ TERMINÉ |
| 3 | Architecture SolidQueue/Supercronic | [`bin/docker-entrypoint`](../bin/docker-entrypoint) | 68-82 | 🚨 **Supercronic ne tourne PAS** - Diagnostiquer et corriger | 🔴 CRITIQUE | 🚨 URGENT |
| 11 | Timezone non configuré | [`config/application.rb`](../config/application.rb) | 27 | ✅ Configurer `Europe/Paris` | 🟡 IMPORTANT | ✅ TERMINÉ |

### 🟡 À Vérifier (Important)

| # | Point | Fichier | Ligne | Action Requise | Priorité |
|---|-------|---------|-------|----------------|----------|
| 4 | Callback `notify_waitlist_if_needed` | [`app/models/attendance.rb`](../app/models/attendance.rb) | 42 | Vérifier ordre, race conditions | 🟡 IMPORTANT |
| 5 | Scope `active` inclut `no_show` | [`app/models/attendance.rb`](../app/models/attendance.rb) | 45 | Clarifier règle métier | 🟡 IMPORTANT |
| 6 | STI Event::Initiation | [`app/models/event/initiation.rb`](../app/models/event/initiation.rb) | 1 | Documenter comportement | 🟡 IMPORTANT |
| 7 | `wants_events_mail` logique | Controllers | - | Documenter choix | 🟡 IMPORTANT |
| 8 | Timing cron conflicts | [`config/schedule.rb`](../config/schedule.rb) | - | Vérifier chevauchements | 🟡 IMPORTANT |

### 🟢 Améliorations (Court terme)

| # | Point | Action Requise | Priorité |
|---|-------|----------------|----------|
| 9 | Monitoring et Logs | Dashboard admin, logs structurés | 🟢 MOYEN |
| 10 | Error Handling | Retry automatique, alertes | 🟢 MOYEN |
| 11 | Timezone Edges | Configurer `config.time_zone` | 🟢 MOYEN |
| 12 | Tests de Charge | Tester avec 1000+ événements | 🟢 BAS |
| 13 | DKIM/SPF Audit | Vérifier configuration email | 🟢 BAS |
| 14 | Dashboard Admin | Statistiques emails | 🟢 BAS |

**Voir Section 12** pour détails complets de chaque point critique.

---

## 📖 Table des Matières

1. [Vue d'Ensemble](#-vue-densemble)
2. [Architecture Générale](#-architecture-générale)
3. [Résumé Rapide - Points Critiques](#-résumé-rapide---points-critiques)
4. [EventMailer](#-1-eventmailer---emails-événements--initiations)
5. [OrderMailer](#-2-ordermailer---emails-commandes)
6. [MembershipMailer](#-3-membershipmailer---emails-adhésions)
7. [UserMailer](#-4-usermailer---emails-utilisateurs)
8. [DeviseMailer](#-5-devisemailer---emails-authentification)
9. [Configuration SMTP](#-6-configuration-smtp)
10. [Jobs et Tâches Automatiques](#-7-jobs-et-tâches-automatiques)
11. [Préférences Utilisateur](#-8-préférences-utilisateur)
12. [Statistiques Globales](#-9-statistiques-globales)
13. [Tests](#-10-tests)
14. [Sécurité Email](#-11-sécurité-email)
15. [🚨 Points Critiques Identifiés - Audit Complet](#-12-points-critiques-identifiés---audit-complet)
16. [Points d'Attention / Actions Requises](#-13-points-dattention--actions-requises)
17. [Références Documentation](#-14-références-documentation)
18. [Checklist de Vérification](#-15-checklist-de-vérification)
19. [Améliorations Futures Possibles](#-16-améliorations-futures-possibles)
20. [Diagnostic EventReminderJob](#-17-diagnostic-eventreminderjob---problème-identifié)
21. [Résumé des Vérifications Complètes](#-18-résumé-des-vérifications-complètes)
22. [Index des Liens Vers Fichiers](#-19-index-des-liens-vers-fichiers)
23. [Résumé de l'Audit Critique](#-20-résumé-de-laudit-critique)
24. [Plan d'Action Priorisé](#-21-plan-daction-priorisé)

---

## 📝 18. Résumé des Vérifications Complètes

### ✅ Tous les Points Vérifiés

#### Mailers (18 emails)
- ✅ **EventMailer** : 5 méthodes vérifiées avec tous les appels dans controllers/models + 1 méthode à implémenter (`initiation_participants_report` - voir Section 7.5)
- ✅ **OrderMailer** : 7 méthodes vérifiées avec callback dans Order model
- ✅ **MembershipMailer** : 4 méthodes vérifiées avec appels dans Membership model, HelloassoService, rake tasks
- ✅ **UserMailer** : 1 méthode vérifiée avec callback dans User model
- ✅ **DeviseMailer** : Configuré et documenté

#### Jobs Automatiques (4 jobs)
- ✅ **EventReminderJob** : Logique complète vérifiée, tous les filtres documentés
- ✅ **HelloAsso Sync** : Rake task vérifiée, appels emails documentés
- ✅ **Memberships Expired** : Rake task vérifiée, logique documentée
- ✅ **Renewal Reminders** : Rake task vérifiée, logique documentée

#### Préférences Email (3 champs)
- ✅ **wants_reminder** (Attendance) : Migration, formulaire, utilisation complète vérifiée
- ✅ **wants_initiation_mail** (User) : Migration, formulaire, utilisation complète vérifiée
- ✅ **wants_events_mail** (User) : Migration, formulaire, utilisation complète vérifiée

#### Configuration
- ✅ **SMTP** : Configuration développement/production/test vérifiée avec liens vers fichiers
- ✅ **Credentials** : Structure documentée avec commande d'édition
- ✅ **Supercronic** : Système réel documenté avec diagnostic complet
- ✅ **Cron** : Toutes les tâches vérifiées avec liens vers schedule.rb et crontab généré

#### Templates
- ✅ **Tous les templates HTML** : 18 fichiers vérifiés (existence confirmée)
- ✅ **Tous les templates Text** : 18 fichiers vérifiés (existence confirmée)

#### Appels Mailers
- ✅ **Controllers** : Tous les appels vérifiés (11 appels dans 6 controllers)
- ✅ **Models** : Tous les callbacks vérifiés (Order, Membership, User, WaitlistEntry)
- ✅ **Services** : HelloassoService vérifié (2 appels MembershipMailer)
- ✅ **Jobs** : EventReminderJob vérifié (1 appel EventMailer)
- ✅ **Rake Tasks** : Toutes les tasks vérifiées (2 appels MembershipMailer)

#### deliver_later vs deliver_now
- ✅ **Tous les appels vérifiés** : Tous les appels utilisent `deliver_later` via Solid Queue (migration terminée depuis les rake tasks)

#### Flags de Suivi
- ✅ **Vérification complète** : `reminder_sent_at`, `renewal_reminder_sent_at`, `expired_email_sent_at` n'existent PAS (documenté comme risque)

#### Bénévoles
- ✅ **Vérification complète** : `is_volunteer` n'est PAS utilisé dans EventReminderJob (bénévoles = même email que participants)

---

## 🔗 19. Index des Liens Vers Fichiers

### Mailers
- [`app/mailers/event_mailer.rb`](../app/mailers/event_mailer.rb) - EventMailer (5 méthodes existantes + 1 à implémenter)
- [`app/mailers/order_mailer.rb`](../app/mailers/order_mailer.rb) - OrderMailer (7 méthodes)
- [`app/mailers/membership_mailer.rb`](../app/mailers/membership_mailer.rb) - MembershipMailer (4 méthodes)
- [`app/mailers/user_mailer.rb`](../app/mailers/user_mailer.rb) - UserMailer (1 méthode)
- [`app/mailers/application_mailer.rb`](../app/mailers/application_mailer.rb) - Configuration de base

### Jobs
- [`app/jobs/event_reminder_job.rb`](../app/jobs/event_reminder_job.rb) - EventReminderJob

### Models
- [`app/models/attendance.rb`](../app/models/attendance.rb) - Modèle Attendance (champ `wants_reminder`, scope `active`)
- [`app/models/user.rb`](../app/models/user.rb) - Modèle User (champs `wants_initiation_mail`, `wants_events_mail`, callback `send_welcome_email_and_confirmation`)
- [`app/models/order.rb`](../app/models/order.rb) - Modèle Order (callback `notify_status_change`)
- [`app/models/membership.rb`](../app/models/membership.rb) - Modèle Membership (callback `activate_if_paid`)
- [`app/models/waitlist_entry.rb`](../app/models/waitlist_entry.rb) - Modèle WaitlistEntry (méthode `send_notification_email`)
- [`app/models/event.rb`](../app/models/event.rb) - Modèle Event (scopes `published`, `upcoming`)

### Controllers
- [`app/controllers/events_controller.rb`](../app/controllers/events_controller.rb) - EventsController (action `reject`)
- [`app/controllers/events/attendances_controller.rb`](../app/controllers/events/attendances_controller.rb) - Events::AttendancesController (actions `create`, `destroy`)
- [`app/controllers/initiations/attendances_controller.rb`](../app/controllers/initiations/attendances_controller.rb) - Initiations::AttendancesController (actions `create`, `destroy`)
- [`app/controllers/events/waitlist_entries_controller.rb`](../app/controllers/events/waitlist_entries_controller.rb) - Events::WaitlistEntriesController (action `confirm`)
- [`app/controllers/initiations/waitlist_entries_controller.rb`](../app/controllers/initiations/waitlist_entries_controller.rb) - Initiations::WaitlistEntriesController (action `confirm`)
- [`app/controllers/orders_controller.rb`](../app/controllers/orders_controller.rb) - OrdersController (action `create`)

### Services
- [`app/services/helloasso_service.rb`](../app/services/helloasso_service.rb) - HelloassoService (synchronisation paiements)

### Rake Tasks
- [`lib/tasks/memberships.rake`](../lib/tasks/memberships.rake) - Tasks membreships (update_expired, send_renewal_reminders)
- [`lib/tasks/helloasso.rake`](../lib/tasks/helloasso.rake) - Task helloasso (sync_payments)

### Configuration
- [`config/schedule.rb`](../config/schedule.rb) - Configuration Whenever (source)
- [`config/crontab`](../config/crontab) - Crontab généré pour Supercronic
- [`config/environments/production.rb`](../config/environments/production.rb) - Configuration SMTP production
- [`config/environments/development.rb`](../config/environments/development.rb) - Configuration SMTP développement
- [`config/environments/test.rb`](../config/environments/test.rb) - Configuration SMTP test
- [`config/credentials.yml.enc`](../config/credentials.yml.enc) - Credentials Rails (chiffré)
- [`bin/docker-entrypoint`](../bin/docker-entrypoint) - Entrypoint Docker (lance Supercronic)

### Scripts
- [`ops/lib/deployment/cron.sh`](../ops/lib/deployment/cron.sh) - Script installation crontab
- [`ops/scripts/update-crontab.sh`](../ops/scripts/update-crontab.sh) - Script manuel installation crontab
- [`ops/deploy.sh`](../ops/deploy.sh) - Script déploiement (appelle install_crontab)

### Migrations
- [`db/migrate/20251201020755_add_email_preferences_to_users.rb`](../db/migrate/20251201020755_add_email_preferences_to_users.rb) - Migration préférences email

### Schema
- [`db/schema.rb`](../db/schema.rb) - Schema complet (tables `users`, `attendances`, `memberships`)

### Tests
- [`spec/mailers/event_mailer_spec.rb`](../spec/mailers/event_mailer_spec.rb) - Tests EventMailer
- [`spec/mailers/order_mailer_spec.rb`](../spec/mailers/order_mailer_spec.rb) - Tests OrderMailer
- [`spec/mailers/membership_mailer_spec.rb`](../spec/mailers/membership_mailer_spec.rb) - Tests MembershipMailer
- [`spec/mailers/user_mailer_spec.rb`](../spec/mailers/user_mailer_spec.rb) - Tests UserMailer
- [`spec/jobs/event_reminder_job_spec.rb`](../spec/jobs/event_reminder_job_spec.rb) - Tests EventReminderJob
- [`spec/requests/event_email_integration_spec.rb`](../spec/requests/event_email_integration_spec.rb) - Tests intégration

### Documentation
- [`docs/06-events/event-reminder-job.md`](../../06-events/event-reminder-job.md) - Documentation EventReminderJob
- [`docs/09-product/orders-workflow-emails.md`](../../09-product/orders-workflow-emails.md) - Documentation emails commandes
- [`docs/09-product/membership-mailer-emails.md`](../../09-product/membership-mailer-emails.md) - Documentation emails adhésions
- [`docs/04-rails/background-jobs/CRON.md`](../background-jobs/CRON.md) - Documentation complète système jobs récurrents (Solid Queue actif)

---

## 🔗 Référence système cron

**Documentation complète** : Voir [`docs/04-rails/background-jobs/CRON.md`](../../04-rails/background-jobs/CRON.md) pour la documentation complète du système de jobs récurrents (Solid Queue actif).

### Résumé des tâches cron liées aux emails

| Tâche | Fréquence | Job/Task | Mailer utilisé | Status |
|-------|-----------|----------|----------------|--------|
| Rappels événements | Quotidien 19h | `EventReminderJob` | `EventMailer.event_reminder` | ✅ Actif |
| Rapport initiation | Quotidien 7h (prod) | `InitiationParticipantsReportJob` | `EventMailer.initiation_participants_report` | ✅ Actif |
| Adhésions expirées | Quotidien 00:00 | `memberships:update_expired` | `MembershipMailer.expired` | ✅ Actif |
| Rappels renouvellement | Quotidien 9h | `memberships:send_renewal_reminders` | `MembershipMailer.renewal_reminder` | ✅ Actif |

**Note** : Toutes les tâches récurrentes sont documentées dans [`docs/04-rails/background-jobs/CRON.md`](../background-jobs/CRON.md) avec détails complets, configuration et dépannage.
