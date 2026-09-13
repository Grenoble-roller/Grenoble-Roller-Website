---
title: "Job de Rappel Événements (EventReminderJob) - Grenoble Roller"
status: "active"
version: "1.0"
created: "2025-01-30"
updated: "2026-08-14"
tags: ["job", "cron", "reminder", "events", "emails"]
---

# Job de Rappel Événements (EventReminderJob)

**Dernière mise à jour** : 2025-01-30

Ce document décrit le job automatique qui envoie des rappels email aux participants la veille à 19h pour les événements du lendemain.

---

## 📋 Vue d'Ensemble

Le `EventReminderJob` est un job ActiveJob qui s'exécute quotidiennement à 19h pour envoyer des rappels email aux participants des événements qui ont lieu le lendemain.

### Fonctionnalités

- ✅ Exécution quotidienne à 19h
- ✅ Rappels pour événements du lendemain
- ✅ Filtre par préférence utilisateur (`wants_reminder`)
- ✅ Support initiations avec préférence globale (`wants_initiation_mail`)
- ✅ Envoi asynchrone via ActiveJob
- ✅ Gestion des événements publiés uniquement

---

## 🏗️ Job : `EventReminderJob`

**Fichier** : `app/jobs/event_reminder_job.rb`

### Structure

```ruby
class EventReminderJob < ApplicationJob
  queue_as :default

  def perform
    # Logique d'envoi des rappels
  end
end
```

### Logique Métier

#### 1. Calcul de la Fenêtre Temporelle

```ruby
tomorrow_start = Time.zone.now.beginning_of_day + 1.day
tomorrow_end = tomorrow_start.end_of_day
```

**Période** : De 00:00:00 à 23:59:59 du lendemain

#### 2. Récupération des Événements

```ruby
events = Event.published
              .upcoming
              .where(start_at: tomorrow_start..tomorrow_end)
```

**Critères** :
- Statut `published` (publiés)
- `upcoming` (start_at > now, mais on filtre déjà avec la fenêtre)
- `start_at` dans la fenêtre du lendemain

#### 3. Parcours des Événements

```ruby
events.find_each do |event|
  is_initiation = event.is_a?(Event::Initiation)
  # ...
end
```

**Optimisation** : `find_each` pour traiter par batch et éviter la charge mémoire.

#### 4. Filtrage des Participants

```ruby
event.attendances.active
     .where(wants_reminder: true)
     .includes(:user, :event)
     .find_each do |attendance|
  # ...
end
```

**Critères** :
- `active` : Statuts actifs (exclut `canceled`, `no_show`)
- `wants_reminder: true` : Préférence utilisateur activée
- `includes(:user, :event)` : Évite les requêtes N+1

#### 5. Vérifications Supplémentaires

```ruby
# Vérifier que l'utilisateur existe et a un email
next unless attendance.user&.email.present?

# Pour les initiations, vérifier aussi la préférence globale
if is_initiation && !attendance.user.wants_initiation_mail?
  next # Skip si l'utilisateur a désactivé les emails d'initiations
end
```

**Logique** :
- Skip si pas d'email
- Pour initiations : Skip si préférence globale `wants_initiation_mail` désactivée

#### 6. Envoi de l'Email

```ruby
EventMailer.event_reminder(attendance).deliver_later
```

**Mailer** : `EventMailer.event_reminder(attendance)`  
**Méthode** : `deliver_later` (asynchrone via ActiveJob)

---

## ⏰ Configuration Cron

### Option 1 : Whenever (config/schedule.rb)

**Fichier** : `config/schedule.rb`

```ruby
set :output, "log/cron.log"

every 1.day, at: '7:00pm' do
  runner "EventReminderJob.perform_now"
end
```

**Exécution** : Tous les jours à 19h (7:00pm)

**Installation** :
```bash
whenever --update-crontab
```

### Option 2 : Solid Queue (config/recurring.yml)

**Fichier** : `config/recurring.yml`

```yaml
recurring:
  - name: event_reminders
    class: EventReminderJob
    schedule: every day at 7:00pm
    queue: default
```

**Exécution** : Tous les jours à 19h via Solid Queue

**Note** : Solid Queue doit être configuré et actif.

---

## 📧 Email de Rappel

### EventMailer.event_reminder

**Méthode** : `app/mailers/event_mailer.rb`

```ruby
def event_reminder(attendance)
  @attendance = attendance
  @event = attendance.event
  @user = attendance.user
  @is_initiation = @event.is_a?(Event::Initiation)

  subject = if @is_initiation
    "📅 Rappel : Initiation roller demain samedi #{l(@event.start_at, format: :day_month, locale: :fr)}"
  else
    "📅 Rappel : #{@event.title} demain !"
  end

  mail(to: @user.email, subject: subject)
end
```

**Templates** :
- HTML : `app/views/event_mailer/event_reminder.html.erb`
- Text : `app/views/event_mailer/event_reminder.text.erb`

**Variables** :
- `@attendance` : Objet Attendance
- `@event` : Événement concerné
- `@user` : Utilisateur participant
- `@is_initiation` : Boolean (initiation ou événement général)

---

## 🎯 Préférences Utilisateur

### Champ `wants_reminder` (Attendance)

**Modèle** : `Attendance`

**Champ** : `wants_reminder` (boolean)

**Utilisation** : Préférence par inscription

- `true` : Recevoir le rappel pour cette inscription
- `false` : Ne pas recevoir le rappel

**Défaut** : `false` (pas de rappel par défaut)

### Champ `wants_initiation_mail` (User)

**Modèle** : `User`

**Champ** : `wants_initiation_mail` (boolean)

**Utilisation** : Préférence globale pour les initiations

- `true` : Recevoir les emails d'initiations
- `false` : Ne pas recevoir les emails d'initiations

**Application** : Uniquement pour les initiations (`Event::Initiation`)

---

## 🔄 Flux Complet

```
1. Cron déclenche EventReminderJob à 19h
   ↓
2. Job calcule fenêtre "demain" (00:00 - 23:59)
   ↓
3. Récupère événements published + start_at demain
   ↓
4. Pour chaque événement :
   ↓
5. Récupère attendances actives + wants_reminder = true
   ↓
6. Pour chaque attendance :
   ↓
7. Vérifie email présent
   ↓
8. Si initiation : vérifie wants_initiation_mail
   ↓
9. Envoie EventMailer.event_reminder(attendance)
```

---

## 🧪 Tests

**Fichier** : `spec/jobs/event_reminder_job_spec.rb`

**Scénarios testés** :
- ✅ Envoie rappels pour événements du lendemain
- ✅ Ne envoie pas si `wants_reminder = false`
- ✅ Ne envoie pas si événement pas published
- ✅ Ne envoie pas si pas d'email utilisateur
- ✅ Pour initiations : respecte `wants_initiation_mail`
- ✅ N'envoie pas si événement passé
- ✅ N'envoie pas si événement pas demain
- ✅ Traite uniquement attendances actives

**Exécution** :
```bash
bundle exec rspec spec/jobs/event_reminder_job_spec.rb
```

---

## 🛠️ Utilisation Manuelle

### Exécution Manuelle (Rails Console)

```ruby
# Exécuter immédiatement
EventReminderJob.perform_now

# Ajouter à la queue
EventReminderJob.perform_later
```

### Exécution Manuelle (Terminal)

```bash
# Via Rails runner
docker exec grenoble-roller-prod bin/rails runner "EventReminderJob.perform_now"

# Via bundle exec
bundle exec rails runner "EventReminderJob.perform_now"
```

### Test en Développement

```bash
# Dans le conteneur Docker
docker exec grenoble-roller-dev bin/rails runner "EventReminderJob.perform_now"
```

---

## 📊 Performance et Optimisations

### Optimisations Actuelles

- **`find_each`** : Traitement par batch (évite charge mémoire)
- **`includes(:user, :event)`** : Évite requêtes N+1
- **`deliver_later`** : Envoi asynchrone (non-bloquant)

### Métriques

**Temps d'exécution estimé** :
- Pour 10 événements avec 20 participants chacun : ~2-3 secondes
- Pour 100 événements avec 200 participants : ~20-30 secondes

**Queue** : `default` (configuré dans ActiveJob)

---

## ⚠️ Limitations et Considérations

### Fuseau Horaire

**Important** : Le job utilise `Time.zone.now` qui respecte le fuseau horaire configuré dans Rails.

**Configuration** : `config/application.rb`

```ruby
config.time_zone = 'Paris'
```

### Doublons

**Protection** : Le job ne vérifie pas si un rappel a déjà été envoyé aujourd'hui.

**Amélioration future** : Ajouter un flag `reminder_sent_at` dans `Attendance`.

### Erreurs

**Gestion** : Si une erreur survient lors de l'envoi d'un email, le job continue avec les autres.

**Logging** : Les erreurs sont loggées dans les logs Rails et ActiveJob.

---

## 🔗 Références

- **Job** : `app/jobs/event_reminder_job.rb`
- **Mailer** : `app/mailers/event_mailer.rb` (méthode `event_reminder`)
- **Templates** : `app/views/event_mailer/event_reminder.*.erb`
- **Tests** : `spec/jobs/event_reminder_job_spec.rb`
- **Cron Whenever** : `config/schedule.rb`
- **Cron Solid Queue** : `config/recurring.yml`
- **Modèle Attendance** : `app/models/attendance.rb` (champ `wants_reminder`)
- **Modèle User** : `app/models/user.rb` (champ `wants_initiation_mail`)

---

## 🎯 Améliorations Futures Possibles

1. **Flag de suivi** : Ajouter `reminder_sent_at` dans `Attendance` pour éviter doublons
2. **Rappels multiples** : Rappel à 48h, 24h, 1h avant
3. **Personnalisation horaire** : Permettre à l'utilisateur de choisir l'heure du rappel
4. **Statistiques** : Suivi des ouvertures/clics
5. **Notifications push** : Ajouter notifications push en plus de l'email
6. **Rappels SMS** : Option pour rappels SMS (si service configuré)

---

**Version** : 1.0  
**Dernière mise à jour** : 2025-01-30

