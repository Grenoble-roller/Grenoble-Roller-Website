# 📧 Notifications E-mail - Implémentation

**Document** : Documentation de l'implémentation des notifications e-mail pour les événements  
**Date** : Novembre 2025  
**Dernière mise à jour** : Janvier 2025  
**Version** : 2.3

---

## ✅ Implémentation Complète

### 1. Mailer créé : `EventMailer`

**Fichier** : `app/mailers/event_mailer.rb`

**Méthodes principales** :
- `attendance_confirmed(attendance)` : Email de confirmation d'inscription
- `attendance_cancelled(user, event)` : Email de confirmation de désinscription
- `event_reminder(user, event, attendances)` : Email de rappel 24h avant (✅ **IMPLÉMENTÉ**)
  - Accepte plusieurs attendances pour grouper les emails (parent + enfants)
  - Un seul email par utilisateur/événement même avec plusieurs participants
- `event_cancelled(user, event, attendances)` : Email de notification d'annulation d'événement (✅ **IMPLÉMENTÉ**)
  - Accepte plusieurs attendances pour grouper les emails (parent + enfants)
  - Envoyé automatiquement à tous les inscrits et bénévoles quand l'événement est annulé
  - Un seul email par utilisateur/événement même avec plusieurs participants

**Méthodes supplémentaires** :
- `event_rejected(event)` : Email de notification de refus d'événement au créateur
- `waitlist_spot_available(waitlist_entry)` : Email de notification de place disponible en liste d'attente
- `initiation_participants_report(initiation)` : Email de rapport des participants pour une initiation

### 2. Templates d'emails

**Templates HTML** :
- `app/views/event_mailer/attendance_confirmed.html.erb`
- `app/views/event_mailer/attendance_cancelled.html.erb`
- `app/views/event_mailer/event_reminder.html.erb`
- `app/views/event_mailer/event_cancelled.html.erb`
- `app/views/event_mailer/event_rejected.html.erb`
- `app/views/event_mailer/waitlist_spot_available.html.erb`
- `app/views/event_mailer/initiation_participants_report.html.erb`

**Templates texte** :
- `app/views/event_mailer/attendance_confirmed.text.erb`
- `app/views/event_mailer/attendance_cancelled.text.erb`
- `app/views/event_mailer/event_reminder.text.erb`
- `app/views/event_mailer/event_cancelled.text.erb`
- `app/views/event_mailer/event_rejected.text.erb`
- `app/views/event_mailer/waitlist_spot_available.text.erb`
- `app/views/event_mailer/initiation_participants_report.text.erb`

**Layout mailer amélioré** :
- `app/views/layouts/mailer.html.erb` : Design cohérent avec l'application

### 3. Configuration ActionMailer

**Développement** (`config/environments/development.rb`) :
- `delivery_method = :smtp` : Envoi via SMTP (configuré avec credentials)
- `raise_delivery_errors = true` : Afficher les erreurs
- `default_url_options = { host: "dev-grenoble-roller.flowtech-lab.org", protocol: "https" }`
- Configuration SMTP : `smtp.ionos.fr` (port 465, SSL)

**Production** (`config/environments/production.rb`) :
- ✅ **CONFIGURÉ** : `delivery_method = :smtp`
- Configuration SMTP complète avec credentials (voir `config/environments/production.rb` lignes 71-82)
- `default_url_options = { host: "grenoble-roller.org", protocol: "https" }`

**Staging** (`config/environments/staging.rb`) :
- ✅ **CONFIGURÉ** : Même configuration que production
- `default_url_options = { host: "grenoble-roller.flowtech-lab.org", protocol: "https" }`

### 4. Intégration dans les contrôleurs

**Contrôleurs utilisant EventMailer** :

**`app/controllers/events_controller.rb`** :
- `reject` : Envoie `event_rejected` après refus d'un événement

**`app/controllers/events/attendances_controller.rb`** :
- Inscription : Envoie `attendance_confirmed` si `current_user.wants_events_mail?`
- Désinscription : Envoie `attendance_cancelled` si `current_user.wants_events_mail?`

**`app/controllers/initiations/attendances_controller.rb`** :
- Inscription : Envoie `attendance_confirmed` si `current_user.wants_initiation_mail?`
- Désinscription : Envoie `attendance_cancelled` si `current_user.wants_initiation_mail?`

**`app/controllers/events/waitlist_entries_controller.rb`** :
- Confirmation place : Envoie `attendance_confirmed` si `current_user.wants_events_mail?`

**`app/controllers/initiations/waitlist_entries_controller.rb`** :
- Confirmation place : Envoie `attendance_confirmed` si `current_user.wants_initiation_mail?`

**`app/models/waitlist_entry.rb`** :
- `send_notification_email` : Envoie `waitlist_spot_available` avec `deliver_now` (time-sensitive, 24h pour confirmer)

**`app/models/event.rb`** :
- Callback `notify_attendees_on_cancellation` : Envoie automatiquement un email à tous les inscrits et bénévoles quand l'événement est annulé
  - Se déclenche uniquement si le statut passe de `published` à `canceled`
  - Groupe les attendances par utilisateur (un seul email par utilisateur/événement)
  - Respecte les préférences utilisateur (`wants_events_mail?`, `wants_initiation_mail?`)

**`app/models/event/initiation.rb`** :
- Callback `schedule_participants_report` : Crée automatiquement le job lors de la publication
- Callback `cancel_scheduled_report` : Annule le job si l'initiation est annulée/rejetée

**`app/jobs/initiation_participants_report_job.rb`** :
- Job créé automatiquement lors de la publication d'une initiation
- Planifié pour s'exécuter le jour de l'initiation à 7h00
- Vérifie le statut : n'envoie que si `published?` (ignore `canceled`, `rejected`, `draft`)

**Utilisation de `deliver_later`** :
- Les emails sont envoyés de manière asynchrone via Active Job (Solid Queue)
- Exception : `waitlist_spot_available` utilise `deliver_now` (notification time-sensitive)
- Pas de blocage de la requête HTTP

**Préférences utilisateur** :
- `wants_events_mail?` : Contrôle l'envoi d'emails pour les événements normaux
- `wants_initiation_mail?` : Contrôle l'envoi d'emails pour les initiations
- `wants_reminder?` : Contrôle l'envoi des rappels 24h avant (dans `EventReminderJob`)

### 5. Tests RSpec

**Fichier** : `spec/mailers/event_mailer_spec.rb`

**Couverture actuelle** :
- Tests pour `attendance_confirmed` (8 exemples) ✅
- Tests pour `attendance_cancelled` (5 exemples) ✅
- Tests pour `event_reminder` (8 exemples) ✅ (mis à jour le 2025-01-30)
- Tests pour `event_cancelled` (10 exemples) ✅ (créés le 2025-01-30)
- Tests pour `event_rejected` (6 exemples) ✅ (créés le 2025-01-30)
- Tests pour `waitlist_spot_available` (8 exemples) ✅ (créés le 2025-01-30)
- Tests pour `initiation_participants_report` (8 exemples) ✅ (créés le 2025-01-30)
- Tests avec routes, prix, max_participants ✅
- Tests avec plusieurs participants (parent + enfants) ✅
- Tests pour initiations ✅

**Tests** :
- ✅ `attendance_confirmed` : 8 exemples
- ✅ `attendance_cancelled` : 5 exemples
- ✅ `event_reminder` : 8 exemples (mis à jour le 2025-01-30, inclut cas initiations avec plusieurs participants)
- ✅ `event_cancelled` : 10 exemples (créés le 2025-01-30, inclut cas initiations avec plusieurs participants)
- ✅ `event_rejected` : 6 exemples (créés le 2025-01-30)
- ✅ `waitlist_spot_available` : 8 exemples (créés le 2025-01-30)
- ✅ `initiation_participants_report` : 8 exemples (créés le 2025-01-30)

**Total** : 55 exemples de tests ✅

---

## 📋 Contenu des Emails

### Email de Confirmation d'Inscription

**Sujet** :
- Événement normal : `✅ Inscription confirmée : [Titre de l'événement]`
- Initiation : `✅ Inscription confirmée - Initiation roller samedi [Date]` (format spécial avec date formatée)

**Contenu** :
- Salutation personnalisée avec le prénom
- Titre de l'événement
- Détails de l'événement :
  - Lieu
  - Date (format français)
  - Durée
  - Prix (si applicable)
  - Parcours (si applicable)
  - Nombre de participants / limite (si applicable)
- Lien vers la page de l'événement
- Rappel : Possibilité d'annuler l'inscription

### Email de Confirmation de Désinscription

**Sujet** :
- Événement normal : `❌ Désinscription confirmée : [Titre de l'événement]`
- Initiation : `❌ Désinscription confirmée - Initiation roller samedi [Date]` (format spécial avec date formatée)

**Contenu** :
- Salutation personnalisée avec le prénom
- Titre de l'événement
- Détails de l'événement :
  - Lieu
  - Date (format français)
  - Durée
- Lien vers la page de l'événement
- Rappel : Possibilité de se réinscrire

---

## 🎨 Design des Emails

### Layout Mailer

**Caractéristiques** :
- Design responsive (mobile-first)
- Couleurs cohérentes avec l'application (Bootstrap colors)
- Header avec logo "Grenoble Roller"
- Footer avec informations de l'association
- Styles inline pour compatibilité email clients

### Templates HTML

**Structure** :
- Titre avec emoji
- Section détails avec fond coloré et bordure
- Tableau pour les informations (meilleure compatibilité)
- Bouton d'action (lien vers l'événement)
- Rappels et informations supplémentaires

### Templates Texte

**Structure** :
- Titre en majuscules
- Séparateurs visuels (`─────────────────────────`)
- Informations formatées de manière lisible
- Lien vers l'événement

---

## 📧 Emails Supplémentaires

### Email de Refus d'Événement (`event_rejected`)

**Sujet** :
- Événement normal : `❌ Votre événement "[Titre]" a été refusé`
- Initiation : `❌ Votre initiation a été refusée`

**Déclencheur** : Refus d'un événement par un modérateur/admin  
**Destinataire** : Créateur de l'événement  
**Appel** : `app/controllers/events_controller.rb` ligne 240

### Email de Place Disponible (`waitlist_spot_available`)

**Sujet** :
- Événement normal : `🎉 Place disponible : [Titre]`
- Initiation : `🎉 Place disponible - Initiation roller samedi [Date]`

**Déclencheur** : Une place se libère dans un événement complet  
**Destinataire** : Premier utilisateur en liste d'attente  
**Appel** : `app/models/waitlist_entry.rb` ligne 290 (via `send_notification_email`)  
**⚠️ Important** : Utilise `deliver_now` (pas `deliver_later`) car notification time-sensitive (24h pour confirmer)  
**Contenu** : Lien de confirmation avec token sécurisé, délai de 24h

### Email d'Annulation d'Événement (`event_cancelled`)

**Sujet** :
- Événement normal : `⚠️ Événement annulé : [Titre]`
- Initiation : `⚠️ Événement annulé - Initiation roller samedi [Date]`
- Si plusieurs participants : `⚠️ Événement annulé : [Titre] ([N] participants)`

**Déclencheur** : Annulation d'un événement (statut passe de `published` à `canceled`)  
**Destinataires** : Tous les inscrits et bénévoles actifs de l'événement  
**Appel** : Callback automatique `notify_attendees_on_cancellation` dans `app/models/event.rb`  
**⚠️ Important** : 
- Envoyé automatiquement via callback `after_commit` quand le statut passe à `canceled`
- Groupe les attendances par utilisateur (un seul email par utilisateur/événement même avec plusieurs participants)
- Respecte les préférences utilisateur (`wants_events_mail?`, `wants_initiation_mail?`)
- Ne s'envoie que si l'événement était `published` avant (pas si c'était déjà `canceled` ou `draft`)

**Contenu** :
- Notification d'annulation
- Liste des participants concernés (si plusieurs)
- Détails de l'événement annulé (lieu, date, durée, prix)
- Information sur le remboursement (si événement payant)
- Lien vers les autres événements

### Email de Rapport Participants (`initiation_participants_report`)

**Sujet** : `📋 Rapport participants - Initiation [Date]`

**Déclencheur** : Job `InitiationParticipantsReportJob` créé automatiquement lors de la publication d'une initiation  
**Planification** : Job planifié pour s'exécuter le jour de l'initiation à 7h00  
**Destinataire** : `contact@grenoble-roller.org`  
**Contenu** : Liste des participants actifs avec matériel demandé (taille de rollers)

**Logique de création** :
- ✅ Job créé automatiquement via callback `schedule_participants_report` dans `Event::Initiation`
- ✅ Se déclenche uniquement si l'initiation est publiée (`status: "published"`)
- ✅ Se déclenche uniquement si `start_at` est dans le futur
- ✅ Planifié pour le jour de l'initiation à 7h00 (via `perform_at`)

**Vérifications dans le job** :
- ✅ Vérifie que l'initiation existe toujours
- ✅ Vérifie que le statut est toujours `published?` (ignore `canceled`, `rejected`, `draft`)
- ✅ Vérifie que l'initiation a bien lieu aujourd'hui
- ✅ Vérifie qu'on n'a pas déjà envoyé le rapport aujourd'hui (`participants_report_sent_at`)

**Annulation automatique** :
- ✅ Si l'initiation est annulée/rejetée après publication, le job planifié est automatiquement annulé
- ✅ Callback `cancel_scheduled_report` trouve et annule les jobs dans Solid Queue

---

## 🔧 Configuration et Utilisation

### Développement

**Configuration** : SMTP activé (même configuration que production mais avec credentials de dev)

**Test manuel** :
```ruby
# Rails console
user = User.first
event = Event.first
attendance = Attendance.create!(user: user, event: event, status: 'registered')

# Envoyer l'email
EventMailer.attendance_confirmed(attendance).deliver_now

# Vérifier les logs ou la boîte email configurée
```

### Production

**Configuration SMTP** : ✅ **DÉJÀ CONFIGURÉ**

**Fichier** : `config/environments/production.rb` (lignes 71-82)

```ruby
config.action_mailer.delivery_method = :smtp
config.action_mailer.smtp_settings = {
  user_name: Rails.application.credentials.dig(:smtp, :user_name),
  password: Rails.application.credentials.dig(:smtp, :password),
  address: Rails.application.credentials.dig(:smtp, :address) || "smtp.ionos.fr",
  port: Rails.application.credentials.dig(:smtp, :port) || 465,
  domain: Rails.application.credentials.dig(:smtp, :domain) || "grenoble-roller.org",
  authentication: :plain,
  enable_starttls_auto: false,
  ssl: true,
  openssl_verify_mode: "peer"
}
```

**Credentials** : Configurés via `rails credentials:edit` sous la clé `:smtp`

---

## 🧪 Tests

### Tests RSpec

**Exécution** :
```bash
# Tous les tests mailers
bundle exec rspec spec/mailers/

# Tests spécifiques
bundle exec rspec spec/mailers/event_mailer_spec.rb

# Dans le conteneur Docker de développement
docker compose -f ops/dev/docker-compose.yml exec web bundle exec rspec spec/mailers/event_mailer_spec.rb
```

**Couverture** :
- ✅ Envoi à la bonne adresse email
- ✅ Sujet correct
- ✅ Contenu correct (titre, détails, liens)
- ✅ Cas particuliers (route, prix, max_participants)

### Tests d'Intégration

**À faire** (dans les tests Capybara) :
- Vérifier que l'email est envoyé après inscription
- Vérifier que l'email est envoyé après désinscription
- Vérifier le contenu de l'email (si possible)

---

## 🚀 Prochaines Étapes

### ✅ Déjà Implémenté

1. **Email de rappel 24h avant** : ✅ **IMPLÉMENTÉ**
   - Job `EventReminderJob` créé (`app/jobs/event_reminder_job.rb`)
   - Planifié via `config/recurring.yml` (Solid Queue) - Tous les jours à 19h
   - Template `event_reminder.html.erb` créé
   - Respecte les préférences utilisateur (`wants_reminder?`, `wants_initiation_mail?`)
   - **Regroupement intelligent** : Un seul email par utilisateur/événement même avec plusieurs participants (parent + enfants)
   - Affiche la liste complète des participants dans un seul email

2. **Email de rapport participants initiation** : ✅ **IMPLÉMENTÉ ET OPTIMISÉ**
   - Job `InitiationParticipantsReportJob` créé automatiquement lors de la publication
   - Planifié pour le jour de l'initiation à 7h00 (au lieu d'un scan quotidien)
   - Vérifie le statut : n'envoie que si `published?` (ignore les autres statuts)
   - Annulation automatique si l'initiation est annulée/rejetée

2. **Préférences utilisateur** : ✅ **IMPLÉMENTÉ**
   - `wants_events_mail?` : Contrôle emails événements normaux
   - `wants_initiation_mail?` : Contrôle emails initiations
   - `wants_reminder?` : Contrôle rappels 24h avant
   - Formulaire dans `app/views/devise/registrations/edit.html.erb`

### Optionnel (Pour plus tard)

1. **Email à l'organisateur** :
   - Notification quand quelqu'un s'inscrit
   - Notification quand quelqu'un se désinscrit

2. **Email de confirmation de paiement** :
   - Si l'événement est payant
   - Intégration avec le système de paiement

3. **Personnalisation avancée** :
   - Templates avec images
   - Signature personnalisée

---

## 📊 Statistiques

### Fichiers créés/modifiés

**Créés** :
- `app/mailers/event_mailer.rb`
- `app/views/event_mailer/attendance_confirmed.html.erb`
- `app/views/event_mailer/attendance_confirmed.text.erb`
- `app/views/event_mailer/attendance_cancelled.html.erb`
- `app/views/event_mailer/attendance_cancelled.text.erb`
- `app/views/event_mailer/event_reminder.html.erb`
- `app/views/event_mailer/event_reminder.text.erb`
- `app/views/event_mailer/event_cancelled.html.erb`
- `app/views/event_mailer/event_cancelled.text.erb`
- `app/views/event_mailer/event_rejected.html.erb`
- `app/views/event_mailer/event_rejected.text.erb`
- `app/views/event_mailer/waitlist_spot_available.html.erb`
- `app/views/event_mailer/waitlist_spot_available.text.erb`
- `app/views/event_mailer/initiation_participants_report.html.erb`
- `app/views/event_mailer/initiation_participants_report.text.erb`
- `spec/mailers/event_mailer_spec.rb`
- `app/jobs/event_reminder_job.rb`
- `app/jobs/initiation_participants_report_job.rb`

**Modifiés** :
- `app/mailers/application_mailer.rb` (email expéditeur)
- `app/mailers/event_mailer.rb` (méthodes `event_reminder` et `event_cancelled` modifiées pour accepter plusieurs attendances)
- `app/models/event.rb` (callback `notify_attendees_on_cancellation` pour notification automatique)
- `app/controllers/events_controller.rb` (intégration mailer)
- `app/controllers/events/attendances_controller.rb` (emails avec préférences)
- `app/controllers/initiations/attendances_controller.rb` (emails avec préférences)
- `app/controllers/events/waitlist_entries_controller.rb` (emails avec préférences)
- `app/controllers/initiations/waitlist_entries_controller.rb` (emails avec préférences)
- `app/models/waitlist_entry.rb` (notification place disponible)
- `app/models/event/initiation.rb` (callbacks pour planifier/annuler le rapport participants)
- `app/jobs/event_reminder_job.rb` (regroupement des attendances par utilisateur)
- `app/jobs/initiation_participants_report_job.rb` (modifié pour accepter un ID, vérifier le statut)
- `app/views/event_mailer/event_reminder.html.erb` (affichage liste participants si plusieurs)
- `app/views/event_mailer/event_reminder.text.erb` (affichage liste participants si plusieurs)
- `app/views/layouts/mailer.html.erb` (design amélioré)
- `config/environments/development.rb` (configuration ActionMailer SMTP)
- `config/environments/production.rb` (configuration ActionMailer SMTP)
- `config/environments/staging.rb` (configuration ActionMailer SMTP)
- `config/recurring.yml` (planification EventReminderJob uniquement, InitiationParticipantsReportJob supprimé)

### Tests

**Exemples de tests** : 55 exemples (dans `spec/mailers/event_mailer_spec.rb`)
- `attendance_confirmed` : 8 exemples ✅
- `attendance_cancelled` : 5 exemples ✅
- `event_reminder` : 8 exemples ✅ (mis à jour le 2025-01-30)
- `event_cancelled` : 10 exemples ✅ **NOUVEAU**
- `event_rejected` : 6 exemples ✅ **NOUVEAU**
- `waitlist_spot_available` : 8 exemples ✅ **NOUVEAU**
- `initiation_participants_report` : 8 exemples ✅ **NOUVEAU**

---

## ✅ Checklist

### Implémentation de Base
- [x] Mailer créé (`EventMailer`)
- [x] Templates HTML créés (7 méthodes)
- [x] Templates texte créés (7 méthodes)
- [x] Layout mailer amélioré
- [x] Configuration ActionMailer (dev/staging/production)
- [x] Intégration dans contrôleurs (5 contrôleurs)
- [x] Tests RSpec créés (55 exemples pour 7 méthodes) ✅
- [x] Documentation créée

### Fonctionnalités Avancées
- [x] Configuration SMTP (production/staging/dev) ✅
- [x] Job de rappel 24h avant (`EventReminderJob`) ✅
- [x] Préférences utilisateur (`wants_events_mail?`, `wants_initiation_mail?`, `wants_reminder?`) ✅
- [x] Email de refus (`event_rejected`) ✅
- [x] Email d'annulation (`event_cancelled`) ✅ **NOUVEAU**
  - Envoi automatique à tous les inscrits et bénévoles
  - Regroupement par utilisateur (un seul email pour parent + enfants)
  - Respecte les préférences utilisateur
- [x] Email liste d'attente (`waitlist_spot_available`) ✅
- [x] Email rapport participants (`initiation_participants_report`) ✅
- [x] Planification jobs (Solid Queue `config/recurring.yml`) ✅
- [x] Regroupement emails rappel (un seul email pour parent + enfants) ✅
- [x] Création automatique job rapport (lors de la publication) ✅
- [x] Vérification statut dans jobs (seulement `published?`) ✅
- [x] Annulation automatique jobs si initiation annulée/rejetée ✅

### À Améliorer
- [ ] Tests d'intégration Capybara - À faire
- [x] Tests RSpec pour `event_rejected` - ✅ Terminé (6 exemples)
- [x] Tests RSpec pour `event_cancelled` - ✅ Terminé (10 exemples)
- [x] Tests RSpec pour `waitlist_spot_available` - ✅ Terminé (8 exemples)
- [x] Tests RSpec pour `initiation_participants_report` - ✅ Terminé (8 exemples)
- [x] Tests RSpec pour `event_reminder` - ✅ Mis à jour (8 exemples, inclut cas initiations)
- [ ] Email à l'organisateur (inscription/désinscription) - Optionnel
- [ ] Email de confirmation de paiement - Optionnel

---

---

## 🔄 Optimisations Récentes (Décembre 2025)

### 1. Regroupement des Emails de Rappel

**Problème** : Un parent avec plusieurs enfants inscrits recevait plusieurs emails séparés (un par enfant).

**Solution** : Regroupement intelligent dans `EventReminderJob`
- Les attendances sont groupées par `user_id` et `event_id`
- Un seul email est envoyé par utilisateur/événement
- L'email affiche la liste complète des participants (parent + enfants)
- Le sujet indique le nombre de participants si > 1

**Fichiers modifiés** :
- `app/jobs/event_reminder_job.rb` : Groupement par utilisateur
- `app/mailers/event_mailer.rb` : Signature modifiée `event_reminder(user, event, attendances)`
- `app/views/event_mailer/event_reminder.html.erb` : Affichage liste participants
- `app/views/event_mailer/event_reminder.text.erb` : Affichage liste participants

### 2. Création Automatique du Job de Rapport Participants

**Problème** : Job récurrent qui scannait toutes les initiations tous les matins à 7h, même s'il n'y avait pas d'initiation.

**Solution** : Création du job à la demande lors de la publication
- Job créé automatiquement via callback `schedule_participants_report` dans `Event::Initiation`
- Planifié pour le jour de l'initiation à 7h00 (via `perform_at`)
- Plus efficace : pas de scan quotidien inutile
- Plus fiable : job créé au bon moment

**Vérifications ajoutées** :
- ✅ Vérifie que le statut est `published?` (ignore `canceled`, `rejected`, `draft`)
- ✅ Vérifie que l'initiation a bien lieu aujourd'hui
- ✅ Vérifie qu'on n'a pas déjà envoyé le rapport (`participants_report_sent_at`)

**Annulation automatique** :
- Si l'initiation est annulée/rejetée après publication, le job planifié est automatiquement annulé
- Callback `cancel_scheduled_report` trouve et annule les jobs dans Solid Queue

**Fichiers modifiés** :
- `app/models/event/initiation.rb` : Callbacks `schedule_participants_report` et `cancel_scheduled_report`
- `app/jobs/initiation_participants_report_job.rb` : Modifié pour accepter un ID, vérifier le statut
- `config/recurring.yml` : Job récurrent supprimé (création à la demande)

### 3. Email Automatique d'Annulation d'Événement

**Problème** : Aucun email n'était envoyé aux inscrits et bénévoles quand un événement était annulé.

**Solution** : Notification automatique via callback dans le modèle `Event`
- Callback `notify_attendees_on_cancellation` se déclenche quand le statut passe de `published` à `canceled`
- Envoie un email à tous les inscrits et bénévoles actifs
- Groupe les attendances par utilisateur (un seul email par utilisateur/événement même avec plusieurs participants)
- Respecte les préférences utilisateur (`wants_events_mail?`, `wants_initiation_mail?`)

**Fichiers créés** :
- `app/mailers/event_mailer.rb` : Méthode `event_cancelled(user, event, attendances)`
- `app/views/event_mailer/event_cancelled.html.erb` : Template HTML
- `app/views/event_mailer/event_cancelled.text.erb` : Template texte

**Fichiers modifiés** :
- `app/models/event.rb` : Callback `notify_attendees_on_cancellation`

**Contenu de l'email** :
- Notification d'annulation
- Liste des participants concernés (si plusieurs)
- Détails de l'événement annulé
- Information sur le remboursement (si événement payant)
- Lien vers les autres événements

---

**Document créé le** : Novembre 2025  
**Dernière mise à jour** : Janvier 2025  
**Version** : 2.3

**Changelog v2.3 (2025-01-30)** :
- ✅ Ajout de 20 nouveaux tests RSpec pour les 4 méthodes manquantes
- ✅ Mise à jour des tests `event_reminder` pour inclure les cas d'initiations avec plusieurs participants
- ✅ Total : 55 exemples de tests (tous passent dans le conteneur Docker de développement)
- ✅ Documentation mise à jour avec les nombres exacts de tests

