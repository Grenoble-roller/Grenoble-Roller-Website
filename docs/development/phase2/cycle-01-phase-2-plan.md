---
title: "Cycle 01 - Phase 2 Plan: Events & Admin"
status: "completed"
version: "1.0"
created: "2025-01-20"
updated: "2025-11-14"
authors: ["FlowTech"]
tags: ["shape-up", "building", "cycle-01", "phase-2", "events", "admin"]
---

# Cycle 01 - Phase 2 Plan: Events & Admin

**Document Type** : Detailed planning, checklist and pitfalls for Phase 2  
**Status** : ✅ Completed - Tests (166+ examples) → Homepage with featured event → DB optimizations → Reminder job → Phase 2 DEV completed → Capybara tests deferred to PREPROD

---

## 📊 ÉTAT ACTUEL

### ✅ TERMINÉ
- [x] Migrations Phase 2 créées et appliquées (7 migrations)
- [x] Modèles Phase 2 créés (Route, Event, Attendance, OrganizerApplication, Partner, ContactMessage, AuditLog)
- [x] Validations, associations, enums, scopes
- [x] Seeds créés et testés (Phase 2)
- [x] RSpec configuré
- [x] FactoryBot factories pour tous les modèles Phase 2 (Role, User, Route, Event, Attendance)
- [x] Tests RSpec complets :
  - Models (75 exemples + 60 nouveaux pour counter cache et max_participants)
  - Requests (Events, Attendances, Pages - 19 exemples)
  - Policies (EventPolicy - 12 exemples)
  - **Total : 166 exemples, 0 échec** ✅
- [x] ActiveAdmin installé (core + intégration Pundit configurée)
- [x] Resources ActiveAdmin générées (Events, Routes, Attendances, Users, Roles, etc.)
- [x] Application publique : CRUD Events complet (index/show/new/edit/destroy)
- [x] UI/UX évènements conforme UI-Kit (cards, hero, auth-form, mobile-first)
- [x] Parcours inscription/désinscription (EventsController#attend / #cancel_attendance)
- [x] Page membre `Mes sorties` (liste des attendances + CTA cohérents)
- [x] Navigation mise à jour (lien "Événements", "Mes sorties")
- [x] Homepage avec affichage du prochain événement (featured event card)
- [x] Documentation mise à jour (setup, testing, changelog)
- [x] **Optimisations DB** : Counter cache `attendances_count` sur Event ✅
- [x] **Feature** : Ajouter `max_participants` sur Event avec validation (0 = illimité) ✅
- [x] Popup de confirmation Bootstrap pour l'inscription ✅
- [x] Affichage des places restantes dans les vues (badges, compteurs) ✅
- [x] Validation côté modèle et policy pour empêcher l'inscription si événement plein ✅
- [x] Tests complets pour counter cache et max_participants (60 nouveaux exemples) ✅
- [x] Correction du problème des boutons dans les cards d'événements (stretched-link) ✅
  - Restructuration HTML : zone cliquable séparée (`.card-clickable-area`) et zone des boutons (`.action-row-wrapper`)
  - Le `stretched-link` ne couvre plus que le contenu, pas les boutons
  - Tous les boutons fonctionnent correctement (S'inscrire, Voir plus, Modifier, Supprimer)
- [x] **Job de rappel la veille à 19h** : ✅ TERMINÉ
  - Job `EventReminderJob` exécuté quotidiennement à 19h via Solid Queue
  - Rappels envoyés pour les événements du lendemain (toute la journée)
  - Option `wants_reminder` dans les attendances (case à cocher à l'inscription, activée par défaut)
  - Affichage du statut du rappel sur la page événement (alerte Bootstrap)
  - Bouton pour activer/désactiver le rappel après inscription
  - Tests RSpec complets (8 exemples pour le job, 4 exemples pour `toggle_reminder`)
  - Migration pour ajouter `wants_reminder` à `attendances` avec index

### ✅ PRÊT POUR PRÉPROD / PRODUCTION
- [x] **Phase 2 DEV terminée** : Toutes les fonctionnalités critiques implémentées et testées ✅
  - [x] Tests RSpec complets (166+ exemples, 0 échec) ✅
  - [x] CRUD Events public fonctionnel ✅
  - [x] Inscriptions/désinscriptions fonctionnelles ✅
  - [x] Notifications e-mail implémentées ✅
  - [x] Job de rappel la veille à 19h implémenté ✅
  - [x] Export iCal fonctionnel ✅
  - [x] Optimisations DB (counter cache, max_participants) ✅
  - [x] **Workflow de modération** : Implémenté (draft, published, rejected, canceled) ✅
  - [x] **Champs niveau et distance** : Implémenté (level, distance_km) ✅
  - [x] **Coordonnées GPS** : Implémenté (optionnel avec Google Maps/Waze) ✅
  - [x] **Améliorations UX** : Badge orange pour places restantes (≤5), réorganisation boutons ✅
  - [x] Documentation complète ✅

### 📅 REPORTÉ EN PRÉPROD
- [ ] **Tests Capybara** : Parcours utilisateur complet (inscription/désinscription) - **Reporté en préprod**
  - ✅ Configuration Capybara avec driver Selenium headless Chrome
  - ✅ Helper d'authentification pour les tests system
  - ✅ Tests de features créés (event_attendance_spec.rb, event_management_spec.rb, mes_sorties_spec.rb)
  - ✅ 30/40 tests passent (75%)
  - ❌ 10 tests à corriger (tests JavaScript avec modals, formulaires, confirmations)
  - **Justification** : Reporté en préprod car les fonctionnalités sont testées avec RSpec (166+ exemples, 0 échec)
  - **Priorité préprod** : Finaliser les tests Capybara avant passage en production

### 📅 PRÉPROD - AVANT PRODUCTION

#### Tests Capybara (Parcours Utilisateur)
**Objectif** : Valider les parcours utilisateur complets avant passage en production

**Tâches** :
- [x] Corriger helper Pagy 43 Frontend (Pagy::Frontend n'existe plus, créé helpers personnalisés dans ApplicationHelper) ✅
- [x] Corriger helper Pagy 43 Backend (Pagy::Backend n'existe plus, créé méthode pagy() dans ApplicationController) ✅
- [x] Réactiver les tests skipés (5 tests : xit → it dans event_attendance_spec.rb et mes_sorties_spec.rb) ✅
- [x] Corriger tests non-JS (test "Voir plus" corrigé - utilise le titre de l'événement) ✅
- [x] Ajouter Chrome dans Dockerfile.dev pour tests JS ✅
- [x] Reconstruire conteneur Docker avec Chrome ✅
- [x] Corriger les tests JavaScript (modals, formulaires, confirmations) ✅
- [x] Valider les parcours utilisateur complets (inscription/désinscription) ✅
- **Résultat** : 57 exemples, 0 échec, 2 pending (tests de suppression volontairement skipés)

**Fichiers à modifier** :
- `spec/features/event_attendance_spec.rb`
- `spec/features/event_management_spec.rb`
- `spec/features/mes_sorties_spec.rb`

**Justification du report** :
- Les fonctionnalités sont testées avec RSpec (166+ exemples, 0 échec)
- Les tests Capybara sont complémentaires mais non bloquants pour le passage en préprod
- Permet de tester en conditions réelles (préprod) avant production
- Priorité préprod : Finaliser les tests Capybara avant passage en production

### 📅 À VENIR

#### Priorité 2 : Améliorations ActiveAdmin
- [ ] **Customisation ActiveAdmin** :
  - Bulk actions (modifier status de plusieurs événements)
  - Exports CSV/PDF des événements et inscriptions
  - Dashboard avec statistiques
  - Actions personnalisées (publier, annuler un événement)
- [ ] **Tests admin** :
  - Tests RSpec pour controllers admin
  - Tests d'intégration Capybara pour actions admin
  - Vérification permissions Pundit

#### Priorité 3 : Fonctionnalités UX
- [x] **Notifications e-mail** : ✅ TERMINÉ
  - [x] Mailer pour inscription/désinscription ✅
  - [x] Templates d'emails (HTML + texte) ✅
  - [x] Configuration ActionMailer (dev/staging/prod) ✅
  - [x] Tests des mailers (16 exemples RSpec) ✅
  - [x] Tests d'intégration (vérifier que l'email est envoyé) - ✅ **CRÉÉ** (2025-12-07) - `spec/requests/event_email_integration_spec.rb`
- [x] **Job de rappel la veille à 19h** : ✅ TERMINÉ
  - [x] Job `EventReminderJob` pour envoyer automatiquement des rappels ✅
  - [x] Planification avec Solid Queue (`config/recurring.yml`) : exécution quotidienne à 19h ✅
  - [x] Rappels envoyés pour les événements du lendemain (toute la journée) ✅
  - [x] Option `wants_reminder` dans les attendances (case à cocher à l'inscription) ✅
  - [x] Affichage du statut du rappel sur la page événement ✅
  - [x] Bouton pour activer/désactiver le rappel après inscription ✅
  - [x] Template email déjà créé (`event_reminder`) ✅
  - [x] Tests RSpec complets (8 exemples) ✅
  - [x] Migration pour ajouter `wants_reminder` à `attendances` ✅
  - [x] Réduit le taux d'absence, améliore l'expérience utilisateur ✅
- [x] **Export iCal** : ✅ TERMINÉ
  - [x] Gem `icalendar` installée ✅
  - [x] Action `EventsController#ical` implémentée ✅
  - [x] Route `/events/:id/ical.ics` créée ✅
  - [x] Lien "Ajouter au calendrier" sur les pages événements (show, index, cards) ✅
  - [x] Tests RSpec pour l'export iCal (3 exemples) ✅
  - [ ] Export de tous les événements de l'utilisateur (optionnel - futur)

#### Priorité 4 : Performance et Qualité
- [ ] **Accessibilité** :
  - ARIA labels sur les boutons et formulaires
  - Navigation clavier complète
  - Tests avec screen reader
  - Amélioration du contraste et des focus states
- [x] **Performance** : ✅ TERMINÉ (Partiellement)
  - [x] Audit N+1 queries avec Bullet gem ✅
  - [x] Optimisation des requêtes (eager loading dans AttendancesController, EventsController, PagesController) ✅
  - [x] Configuration Bullet dans development.rb ✅
  - [ ] Audit de sécurité avec Brakeman ⏳
- [ ] **Pagination** :
  - Pagination sur "Mes sorties" si >20 événements
  - Pagination sur la liste des événements (optionnel)

---

## ⚠️ PIÈGE CRITIQUE À ÉVITER

### ❌ NE PAS créer contrôleurs/routes manuels avant ActiveAdmin

**Pourquoi ?** ActiveAdmin génère automatiquement :
- Contrôleurs admin (`app/admin/events.rb`, etc.)
- Routes admin (`/admin/events`, `/admin/routes`, etc.)
- Vues admin (index, show, form, filters, bulk actions)

**Si vous créez maintenant** :
```ruby
# app/controllers/events_controller.rb (full CRUD)
# app/controllers/routes_controller.rb (full CRUD)
# + routes.rb resources :events, :routes
# + vues ERB admin
```

**Puis Jour 11** :
```bash
rails generate activeadmin:resource Event Route
# ← Crée les MÊMES contrôleurs (version ActiveAdmin)
# ← Résultat : Duplication complète, travail perdu ❌
```

**✅ Solution** : ActiveAdmin génère TOUT automatiquement. Zéro travail manuel de CRUD admin.

> ℹ️ Exception déjà appliquée côté **application publique** : contrôleurs `EventsController` & `AttendancesController` implémentés pour le front (non admin). Ne rien dupliquer dans l’espace `admin`.

---

## 📅 PLAN DÉTAILLÉ (Jour par jour)

### Jour 5-10 : Tests RSpec COMPLETS (AVANT ActiveAdmin)

#### ✅ Pré-requis vérifiés
- [x] Modèles stables (validations, associations, scopes) ✅
- [x] Migrations appliquées ✅
- [x] Seeds créés et testés ✅

#### ✅ Réalisé
- [x] **Tests RSpec models complets** :
  - `spec/models/route_spec.rb` (validations name, distance_km, elevation_m, difficulty)
  - `spec/models/event_spec.rb` (validations title, description, start_at, duration_min, status, scopes)
  - `spec/models/attendance_spec.rb` (associations user, event, payment, validations)
  - `spec/models/organizer_application_spec.rb` (workflow status, associations)
  - `spec/models/partner_spec.rb` (validations, associations)
  - `spec/models/contact_message_spec.rb` (validations)
  - `spec/models/audit_log_spec.rb` (validations, associations, scopes)

- [x] **Tests edge cases** (validations négatives, associations invalides)
- [x] **Coverage >70%** ← **OBLIGATOIRE AVANT ActiveAdmin** *(modèle specs : 75 exemples, 0 échec)*

**Vérification** :
```bash
rspec spec/models
# ✅ 75 examples, 0 failures
# ✅ Coverage >70%
```

---

### Jour 11 : Installation ActiveAdmin

#### ⚠️ Pré-requis OBLIGATOIRES
- [x] Modèles 100% stables ✅
- [x] Migrations appliquées ✅
- [x] Seeds testés ✅
- [x] **Tests RSpec >70% coverage** ← **OBLIGATOIRE** (confirmé via `bundle exec rspec spec/models`)

> ✅ Commande validée (Docker) :
> ```bash
> docker compose -f ops/dev/docker-compose.yml up -d db
> docker compose -f ops/dev/docker-compose.yml run --rm \
>   -e DATABASE_URL=postgresql://postgres:postgres@db:5432/app_test \
>   -e RAILS_ENV=test \
>   web bundle exec rspec spec/models
> ```
> Utiliser la même configuration (`DATABASE_URL` explicite) pour `db:drop db:create db:schema:load` si un reset test est nécessaire.

#### Installation
- [x] Gems `activeadmin` + `pundit` ajoutées (`Gemfile`) puis `bundle install` via Docker (`BUNDLE_PATH=/rails/vendor/bundle`)
- [x] `rails generate active_admin:install --skip-users`
- [x] Configuration `config/initializers/active_admin.rb` + `ApplicationController` (Devise auth, `ActiveAdmin::PunditAdapter`, redirections)
- [x] `rails generate pundit:install`
- [x] `rails db:migrate` (création table `active_admin_comments`)
- [x] Vérification RSpec `spec/models` (base test) après migration
- [x] `bin/docker-entrypoint` mis à jour pour reconstruire automatiquement les CSS (application + ActiveAdmin) à chaque `docker compose up web`
- [x] Accès `/admin` validé (`admin@roller.com` / `admin123`)
- [x] Generate resources :
  ```bash
  rails g activeadmin:resource Route
  rails g activeadmin:resource Event
  rails g activeadmin:resource Attendance
  rails g activeadmin:resource OrganizerApplication
  rails g activeadmin:resource Partner
  rails g activeadmin:resource ContactMessage
  rails g activeadmin:resource AuditLog
  rails g activeadmin:resource User
  rails g activeadmin:resource Product
  rails g activeadmin:resource Order
  ```

> Commandes exécutées (Docker) :
> ```bash
> docker compose -f ops/dev/docker-compose.yml run --rm \
>   -e BUNDLE_PATH=/rails/vendor/bundle \
>   web bundle install
>
> docker compose -f ops/dev/docker-compose.yml run --rm \
>   -e BUNDLE_PATH=/rails/vendor/bundle \
>   -e DATABASE_URL=postgresql://postgres:postgres@db:5432/grenoble_roller_development \
>   web bundle exec rails generate active_admin:install --skip-users
>
> docker compose -f ops/dev/docker-compose.yml run --rm \
>   -e BUNDLE_PATH=/rails/vendor/bundle \
>   -e DATABASE_URL=postgresql://postgres:postgres@db:5432/grenoble_roller_development \
>   web bundle exec rails generate pundit:install
>
> docker compose -f ops/dev/docker-compose.yml run --rm \
>   -e BUNDLE_PATH=/rails/vendor/bundle \
>   -e DATABASE_URL=postgresql://postgres:postgres@db:5432/grenoble_roller_development \
>   web bundle exec rails db:migrate
>
> docker compose -f ops/dev/docker-compose.yml run --rm \
>   -e BUNDLE_PATH=/rails/vendor/bundle \
>   -e DATABASE_URL=postgresql://postgres:postgres@db:5432/app_test \
>   -e RAILS_ENV=test \
>   web bundle exec rails db:drop db:create db:schema:load
>
> docker compose -f ops/dev/docker-compose.yml run --rm \
>   -e BUNDLE_PATH=/rails/vendor/bundle \
>   -e DATABASE_URL=postgresql://postgres:postgres@db:5432/app_test \
>   -e RAILS_ENV=test \
>   web bundle exec rspec spec/models
>
> docker compose -f ops/dev/docker-compose.yml up web
> # → Dashboard ActiveAdmin disponible via http://localhost:3000/admin
> ```

#### ✅ ActiveAdmin génère automatiquement
- Contrôleurs admin (`app/admin/events.rb`, `app/admin/routes.rb`, etc.)
- Routes admin (`/admin/events`, `/admin/routes`, `/admin/attendances`, etc.)
- Vues admin (index, show, form, filters, bulk actions)
- **ZÉRO travail manuel de CRUD admin** ✅

---

### Jour 12-13 : Customisation ActiveAdmin

#### ✅ Réalisé
- [x] Configurer colonnes visibles (index, show, form) - Events partiellement configuré
- [x] Filtres simples (title, status, route, creator_user, start_at, created_at) - Events configuré
- [x] Scopes (À venir, Publiés, Brouillons, Annulés) - Events configuré
- [x] Exposer `Role` dans ActiveAdmin (ressource dédiée + policy Pundit) pour gérer la hiérarchie/rôles via l'UI
- [x] Panel "Inscriptions" dans la vue show d'un événement

#### 🔜 À faire
- [ ] Bulk actions (sélectionner 10 événements = modifier status en 1 clic)
- [ ] Export CSV/PDF intégré (out-of-the-box)
- [ ] Dashboard validation organisateurs
- [ ] Actions personnalisées (validate_organizer!, publish_event, cancel_event)
- [ ] Améliorer la customisation des autres resources (Routes, Attendances, etc.)

---

### Jour 14-15 : Tests Admin & Finalisation

- [ ] Tests admin controllers (RSpec)
- [ ] Integration tests (admin actions via Capybara)
- [ ] Permissions Pundit testées
- [ ] Coverage >70% maintenu
- [ ] Audit sécurité (Brakeman)
- [ ] Optimisation requêtes (N+1 queries)

---

## 📋 CHECKLIST RAPIDE

### Modèles Phase 2
- [x] Route ✅
- [x] Event ✅
- [x] Attendance ✅
- [x] OrganizerApplication ✅
- [x] Partner ✅
- [x] ContactMessage ✅
- [x] AuditLog ✅

### Tests RSpec
- [x] Route (validations, associations)
- [x] Event (validations, associations, scopes)
- [x] Attendance (validations, associations)
- [x] OrganizerApplication (validations, workflow)
- [x] Partner (validations)
- [x] ContactMessage (validations)
- [x] AuditLog (validations, associations, scopes)
- [x] Coverage >70%

### ActiveAdmin (Jour 11+)
- [x] Installation
- [x] Resource `Role` exposée + policy Pundit dédiée
- [x] Autres resources générées (`events`, `attendances`, `routes`, `users`, etc.)
- [x] Customisation basique (scopes, filtres, colonnes) - Events partiellement customisé
- [ ] Customisation avancée (bulk actions, exports CSV/PDF, dashboard)
- [ ] Tests admin
- [ ] Permissions Pundit (partiellement testées)

---

## 🎯 PROCHAINES ÉTAPES DÉTAILLÉES

### 📌 PRIORITÉ 1 : Optimisations et Fonctionnalités Critiques (Semaine 1)

#### 1. Optimisations Base de Données ✅ TERMINÉ
**Objectif** : Améliorer les performances des listes d'événements

**Tâches** :
- [x] Créer migration pour ajouter `attendances_count` sur `events`
- [x] Ajouter `counter_cache: true` dans le modèle `Attendance`
- [x] Migration de données pour mettre à jour les compteurs existants
- [x] Mettre à jour les vues pour utiliser `event.attendances_count` au lieu de `event.attendances.count`
- [x] Tests pour vérifier le counter cache (3 tests ajoutés)

**Fichiers modifiés** :
- `db/migrate/20251110141700_add_attendances_count_to_events.rb` ✅
- `app/models/attendance.rb` ✅
- `app/models/event.rb` ✅
- `app/views/events/_event_card.html.erb` ✅
- `app/views/events/index.html.erb` ✅
- `app/views/events/show.html.erb` ✅
- `app/views/pages/index.html.erb` ✅
- `spec/models/attendance_spec.rb` ✅

#### 2. Limite de Participants ✅ TERMINÉ
**Objectif** : Gérer le nombre maximum de participants par événement (0 = illimité)

**Tâches** :
- [x] Créer migration pour ajouter `max_participants` sur `events` (default: 0 = illimité)
- [x] Ajouter validation dans le modèle `Event` (max_participants >= 0)
- [x] Ajouter méthodes `unlimited?`, `full?`, `remaining_spots`, `has_available_spots?`
- [x] Ajouter validation dans le modèle `Attendance` (vérifier limite avant création, ignorer annulées)
- [x] Mettre à jour `EventPolicy#attend?` pour vérifier si événement plein
- [x] Ajouter méthodes `can_attend?` et `user_has_attendance?` dans la policy
- [x] Afficher le nombre de places restantes dans l'UI (badges, compteurs)
- [x] Désactiver le bouton "S'inscrire" si limite atteinte
- [x] Popup de confirmation Bootstrap avant inscription
- [x] Tests pour les validations et le comportement (57 tests ajoutés)
- [x] Intégration dans ActiveAdmin (affichage et formulaire)

**Fichiers modifiés** :
- `db/migrate/20251110142027_add_max_participants_to_events.rb` ✅
- `app/models/event.rb` ✅
- `app/models/attendance.rb` ✅
- `app/controllers/events_controller.rb` ✅
- `app/policies/event_policy.rb` ✅
- `app/views/events/_event_card.html.erb` ✅
- `app/views/events/show.html.erb` ✅
- `app/views/events/index.html.erb` ✅
- `app/views/pages/index.html.erb` ✅
- `app/views/events/_form.html.erb` ✅
- `app/admin/events.rb` ✅
- `spec/models/event_spec.rb` ✅
- `spec/models/attendance_spec.rb` ✅
- `spec/policies/event_policy_spec.rb` ✅
- `spec/factories/events.rb` ✅

#### 3. Tests Capybara (Parcours Utilisateur)
**Objectif** : Couvrir les parcours utilisateur critiques avec des tests d'intégration

**Tâches** :
- [ ] Installer Capybara et Selenium/Chrome driver
- [ ] Configurer Capybara dans `spec/rails_helper.rb`
- [ ] Créer `spec/features/event_attendance_spec.rb` :
  - Parcours : voir événement → s'inscrire → vérifier inscription → se désinscrire
  - Test de limite de participants
  - Test des permissions (non connecté, member, organizer)
- [ ] Créer `spec/features/event_management_spec.rb` :
  - Création d'événement (organizer)
  - Modification d'événement (créateur)
  - Suppression d'événement (créateur/admin)
- [ ] Tests des notifications flash
- [ ] Tests de la page "Mes sorties"

**Fichiers à créer/modifier** :
- `spec/features/event_attendance_spec.rb`
- `spec/features/event_management_spec.rb`
- `spec/features/mes_sorties_spec.rb`
- `spec/rails_helper.rb`
- `Gemfile` (ajouter `capybara`, `selenium-webdriver`)

### 📌 PRIORITÉ 2 : Améliorations ActiveAdmin (Semaine 2)

#### 4. Customisation ActiveAdmin
**Objectif** : Améliorer l'expérience utilisateur du back-office

**Tâches** :
- [ ] **Bulk Actions** :
  - Action "Publier" pour sélectionner plusieurs événements
  - Action "Annuler" pour sélectionner plusieurs événements
  - Action "Modifier le statut" en masse
- [ ] **Exports** :
  - Export CSV des événements avec toutes les colonnes
  - Export CSV des inscriptions par événement
  - Export PDF des événements (optionnel)
- [ ] **Dashboard** :
  - Statistiques (nombre d'événements, inscriptions, etc.)
  - Graphiques (optionnel)
  - Liste des événements à venir
- [ ] **Actions personnalisées** :
  - Bouton "Publier" dans la vue show d'un événement
  - Bouton "Annuler" dans la vue show d'un événement
  - Validation des organisateurs depuis le dashboard

**Fichiers à modifier** :
- `app/admin/events.rb`
- `app/admin/dashboard.rb`
- `app/admin/attendances.rb`

#### 5. Tests Admin
**Objectif** : Garantir la qualité du back-office

**Tâches** :
- [ ] Tests RSpec pour les controllers admin
- [ ] Tests d'intégration Capybara pour les actions admin
- [ ] Vérification des permissions Pundit pour chaque rôle
- [ ] Tests des bulk actions
- [ ] Tests des exports

**Fichiers à créer** :
- `spec/admin/events_spec.rb`
- `spec/features/admin/event_management_spec.rb`
- `spec/policies/admin/event_policy_spec.rb`

### 📌 PRIORITÉ 3 : Fonctionnalités UX (Semaine 3)

#### 6. Notifications E-mail ✅ TERMINÉ
**Objectif** : Informer les utilisateurs des inscriptions/désinscriptions

**Tâches** :
- [x] Créer `app/mailers/event_mailer.rb` ✅
- [x] Créer templates d'emails (HTML + texte) :
  - `app/views/event_mailer/attendance_confirmed.html.erb` ✅
  - `app/views/event_mailer/attendance_confirmed.text.erb` ✅
  - `app/views/event_mailer/attendance_cancelled.html.erb` ✅
  - `app/views/event_mailer/attendance_cancelled.text.erb` ✅
  - `app/views/event_mailer/event_reminder.html.erb` (template créé, job à faire) ✅
- [x] Configurer ActionMailer (dev/staging/prod) ✅
- [x] Appeler les mailers dans `EventsController#attend` et `#cancel_attendance` ✅
- [x] Tests des mailers (16 exemples RSpec) ✅
- [ ] Tests d'intégration (vérifier que l'email est envoyé) ⏳

**Fichiers créés** :
- `app/mailers/event_mailer.rb` ✅
- `app/views/event_mailer/attendance_confirmed.html.erb` ✅
- `app/views/event_mailer/attendance_confirmed.text.erb` ✅
- `app/views/event_mailer/attendance_cancelled.html.erb` ✅
- `app/views/event_mailer/attendance_cancelled.text.erb` ✅
- `spec/mailers/event_mailer_spec.rb` ✅
- `docs/06-events/email-notifications-implementation.md` ✅

#### 6.1. Job de Rappel la Veille à 19h ✅ TERMINÉ
**Objectif** : Envoyer automatiquement un email de rappel la veille à 19h pour les événements du lendemain aux participants inscrits

**Pourquoi cette feature** :
- ✅ Réduit le taux d'absence (les participants se souviennent de l'événement)
- ✅ Améliore l'expérience utilisateur (rappel automatique)
- ✅ Standard dans les applications d'événements (Eventbrite, Meetup, etc.)
- ✅ Facile à implémenter (template email déjà créé)

**Tâches** :
- [x] Créer `app/jobs/event_reminder_job.rb` ✅
- [x] Implémenter la logique de sélection des événements (événements du lendemain) ✅
- [x] Envoyer les emails via `EventMailer.event_reminder(attendance)` uniquement pour les utilisateurs avec `wants_reminder = true` ✅
- [x] Configurer la planification avec Solid Queue (`config/recurring.yml`) : exécution quotidienne à 19h ✅
- [x] Créer template `app/views/event_mailer/event_reminder.html.erb` ✅
- [x] Créer template `app/views/event_mailer/event_reminder.text.erb` ✅
- [x] Migration pour ajouter `wants_reminder` à `attendances` (boolean, default: false, avec index) ✅
- [x] Case à cocher dans les modales d'inscription pour activer le rappel (cochée par défaut) ✅
- [x] Affichage du statut du rappel sur la page événement (alerte Bootstrap) ✅
- [x] Action `toggle_reminder` dans `EventsController` pour activer/désactiver le rappel ✅
- [x] Tests du job (RSpec - 8 exemples, 0 échec) ✅
- [x] Tests de l'action `toggle_reminder` (4 exemples, 0 échec) ✅

**Fichiers créés/modifiés** :
- `app/jobs/event_reminder_job.rb` ✅
- `app/views/event_mailer/event_reminder.html.erb` ✅
- `app/views/event_mailer/event_reminder.text.erb` ✅
- `spec/jobs/event_reminder_job_spec.rb` ✅
- `config/recurring.yml` (planification avec Solid Queue) ✅
- `db/migrate/20250120140000_add_wants_reminder_to_attendances.rb` ✅
- `app/models/attendance.rb` (ajout `wants_reminder` dans `ransackable_attributes`) ✅
- `app/controllers/events_controller.rb` (actions `attend` et `toggle_reminder`) ✅
- `config/routes.rb` (route `PATCH /events/:id/toggle_reminder`) ✅
- `app/views/events/show.html.erb` (affichage statut rappel + case à cocher dans modal) ✅
- `app/views/events/index.html.erb` (case à cocher dans modal) ✅
- `app/views/events/_event_card.html.erb` (case à cocher dans modal) ✅
- `spec/factories/attendances.rb` (ajout `wants_reminder` et trait `:with_reminder`) ✅

**Configuration** :
- Solid Queue configuré (Rails 8.1.1)
- Planification via `config/recurring.yml` : exécution quotidienne à 19h (dev et prod)
- Queue adapter : Solid Queue (par défaut avec Rails 8.1.1)

**Implémentation actuelle** :
```ruby
# app/jobs/event_reminder_job.rb
class EventReminderJob < ApplicationJob
  queue_as :default

  def perform
    # Définir le début et la fin de demain (00:00:00 à 23:59:59)
    tomorrow_start = Time.zone.now.beginning_of_day + 1.day
    tomorrow_end = tomorrow_start.end_of_day

    # Trouver les événements publiés qui ont lieu demain (dans toute la journée)
    events = Event.published
                  .upcoming
                  .where(start_at: tomorrow_start..tomorrow_end)

    events.find_each do |event|
      # Envoyer un rappel uniquement aux participants actifs qui ont activé le rappel
      event.attendances.active
           .where(wants_reminder: true)
           .includes(:user, :event)
           .find_each do |attendance|
        next unless attendance.user&.email.present?
        EventMailer.event_reminder(attendance).deliver_later
      end
    end
  end
end

# config/recurring.yml
development:
  event_reminder:
    class: EventReminderJob
    queue: default
    schedule: every day at 7:00pm

production:
  event_reminder:
    class: EventReminderJob
    queue: default
    schedule: every day at 7:00pm
```

**Fonctionnalités** :
- ✅ Rappels envoyés la veille à 19h pour les événements du lendemain
- ✅ Option `wants_reminder` dans les attendances (case à cocher à l'inscription, activée par défaut)
- ✅ Affichage du statut du rappel sur la page événement (alerte Bootstrap avec icône)
- ✅ Bouton pour activer/désactiver le rappel après inscription
- ✅ Rappels envoyés uniquement aux utilisateurs avec `wants_reminder = true`
- ✅ Tests RSpec complets (8 exemples pour le job, 4 exemples pour `toggle_reminder`)

**Priorité** : ✅ TERMINÉ

#### 7. Export iCal ✅ TERMINÉ
**Objectif** : Permettre aux utilisateurs d'ajouter les événements à leur calendrier

**Tâches** :
- [x] Installer gem `icalendar` ✅
- [x] Créer `app/controllers/events_controller.rb#ical` (action pour générer .ics) ✅
- [x] Ajouter route pour l'export iCal (`GET /events/:id/ical.ics`) ✅
- [x] Génération du fichier .ics avec toutes les informations (titre, description, lieu, dates, URL, organizer) ✅
- [x] Ajouter lien "Ajouter au calendrier" sur les pages événements (show, index, cards) ✅
- [x] Tests RSpec pour l'action `ical` (3 exemples) ✅
- [ ] Créer action pour exporter tous les événements de l'utilisateur (optionnel - futur)
- [ ] Tests manuels avec différents clients calendrier (Google Calendar, Outlook, Apple Calendar) ⏳

**Fichiers créés/modifiés** :
- `Gemfile` (ajout gem `icalendar`)
- `app/controllers/events_controller.rb` (ajout action `ical`)
- `config/routes.rb` (ajout route `get :ical, defaults: { format: 'ics' }`)
- `app/views/events/show.html.erb` (ajout lien "Ajouter au calendrier")
- `app/views/events/index.html.erb` (ajout lien dans la section "Prochain rendez-vous")
- `app/views/events/_event_card.html.erb` (ajout lien dans les cards d'événements)
- `spec/requests/events_spec.rb` (ajout 3 tests pour l'export iCal)
- `Dockerfile.dev` (rebuild avec nouvelles gems)

### 📌 PRIORITÉ 4 : Performance et Qualité (Semaine 4)

#### 8. Accessibilité
**Objectif** : Rendre l'application accessible à tous les utilisateurs

**Tâches** :
- [ ] Ajouter ARIA labels sur tous les boutons et formulaires
- [ ] Vérifier la navigation clavier (Tab, Enter, Esc)
- [ ] Améliorer les contrastes de couleurs
- [ ] Améliorer les focus states (visibilité au clavier)
- [ ] Tests avec screen reader (NVDA, JAWS, VoiceOver)
- [ ] Validation avec outils d'accessibilité (axe-core, WAVE)

**Fichiers à modifier** :
- `app/views/events/_event_card.html.erb`
- `app/views/events/show.html.erb`
- `app/views/events/_form.html.erb`
- `app/views/layouts/_navbar.html.erb`
- `app/assets/stylesheets/_style.scss`

#### 9. Performance
**Objectif** : Optimiser les performances de l'application

**Tâches** :
- [ ] Installer Bullet gem (détection N+1 queries)
- [ ] Configurer Bullet en développement
- [ ] Auditer toutes les pages et corriger les N+1 queries
- [ ] Ajouter des index sur les colonnes fréquemment utilisées
- [ ] Optimiser les requêtes avec eager loading
- [ ] Audit de sécurité avec Brakeman
- [ ] Corriger les vulnérabilités identifiées

**Fichiers à créer/modifier** :
- `Gemfile` (ajouter `bullet`, `brakeman`)
- `config/environments/development.rb` (configurer Bullet)
- `app/controllers/events_controller.rb` (optimiser eager loading)
- `app/controllers/attendances_controller.rb` (optimiser eager loading)
- `db/migrate/XXXXXX_add_indexes_for_performance.rb`

#### 10. Pagination
**Objectif** : Améliorer l'expérience utilisateur sur les grandes listes

**Tâches** :
- [ ] Installer gem `kaminari` ou `pagy`
- [ ] Ajouter pagination sur "Mes sorties" (si >20 événements)
- [ ] Ajouter pagination sur la liste des événements (optionnel)
- [ ] Tests pour la pagination

**Fichiers à créer/modifier** :
- `Gemfile` (ajouter `kaminari` ou `pagy`)
- `app/controllers/attendances_controller.rb` (ajouter pagination)
- `app/views/attendances/index.html.erb` (ajouter pagination)
- `app/controllers/events_controller.rb` (ajouter pagination optionnel)
- `app/views/events/index.html.erb` (ajouter pagination optionnel)

---

## 📅 CALENDRIER RECOMMANDÉ

- **Semaine 1** : Optimisations DB (counter cache, max_participants) ✅ TERMINÉ
- **Semaine 2** : Notifications email + Export iCal + Job de rappel ✅ TERMINÉ
- **PRÉPROD** : Tests Capybara (parcours utilisateur complet) 📅
- **Semaine 3-4** : Améliorations ActiveAdmin + Accessibilité + Audit performance + Pagination (optionnel)

---

## 📚 RESSOURCES

- **Schema DB** : `ressources/db/dbdiagram.md`
- **Documentation modèles** : `docs/03-architecture/domain/models.md`
- **Migrations Phase 2** : `docs/development/phase2/phase2-migrations-models.md`
- **Guide technique** : [`../technical-implementation-guide.md`](../technical-implementation-guide.md)

---

**Document créé le** : 2025-01-20  
**Dernière mise à jour** : 2025-01-20  
**Version** : 2.2 (Phase 2 DEV terminée, tests Capybara reportés en préprod)

