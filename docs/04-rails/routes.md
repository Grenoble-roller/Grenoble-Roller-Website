# Routes de l’application (Rails 8)

**Dernière mise à jour** : 2026-08-14


Ce document liste les routes disponibles et les flux principaux. Basé sur `config/routes.rb` à la date actuelle.

## Résumé
- Santé: `GET /up` (Rails health check)
- Accueil: `GET /` → `PagesController#index`
- Association: `GET /association` → `PagesController#association`
- Boutique: `GET /products`, `GET /products/:id` (slug ou id), alias `GET /shop`
- Événements: `GET /events`, `GET /events/:id`, `GET /events/new`, `POST /events`, `PATCH/PUT /events/:id`, `DELETE /events/:id`
- Panier (singulier): `GET /cart`, `POST /cart/add_item`, `PATCH /cart/update_item`, `DELETE /cart/remove_item`, `DELETE /cart/clear`
- Commandes: `GET /orders`, `GET /orders/new`, `POST /orders`, `GET /orders/:id`, `PATCH /orders/:id/cancel`
- Authentification: `devise_for :users` (routes Devise standard + `PasswordsController` personnalisé)

## Détail

### Pages statiques
- `GET /` → `pages#index`
- `GET /association` → `pages#association`

### Produits (catalogue)
- `GET /products` → `products#index`
- `GET /products/:id` → `products#show`
  - `:id` accepte un `slug` (préféré) ou un id numérique
- Alias boutique: `GET /shop` → `products#index`

### Panier (resource singulier)
- `GET    /cart` → `carts#show`
- `POST   /cart/add_item` → `carts#add_item`
- `PATCH  /cart/update_item` → `carts#update_item`
- `DELETE /cart/remove_item` → `carts#remove_item`
- `DELETE /cart/clear` → `carts#clear`

### Commandes
- `GET   /orders` → `orders#index`
- `GET   /orders/new` → `orders#new`
- `POST  /orders` → `orders#create`
- `GET   /orders/:id` → `orders#show`
- `PATCH /orders/:id/cancel` → `orders#cancel` (membre)
  - Protégé par `authenticate_user!`

### Événements (Phase 2)
- `GET    /events` → `events#index`
- `GET    /events/new` → `events#new`
- `POST   /events` → `events#create`
- `GET    /events/:id` → `events#show`
- `GET    /events/:id/edit` → `events#edit`
- `PATCH  /events/:id` → `events#update`
- `PUT    /events/:id` → `events#update`
- `DELETE /events/:id` → `events#destroy`
  - `index`/`show` publics (seuls les événements publiés hors organisateurs)
  - Création/édition réservées aux rôles `ORGANIZER+` (Pundit)

#### Actions membres sur événements
- `POST   /events/:id/attend` → `events#attend` (inscription)
- `DELETE /events/:id/cancel_attendance` → `events#cancel_attendance` (désinscription)
- `GET    /events/:id/ical` → `events#ical` (export iCal, format `.ics`)
- `PATCH  /events/:id/toggle_reminder` → `events#toggle_reminder` (activer/désactiver rappel)
- `PATCH  /events/:id/reject` → `events#reject` (rejeter événement, admin/organisateur)
- `GET    /events/:id/loop_routes` → `events#loop_routes` (API JSON, boucles multiples)

#### Routes liste d'attente (waitlist)
- `POST   /events/:id/join_waitlist` → `events#join_waitlist` (rejoindre liste d'attente)
- `DELETE /events/:id/leave_waitlist` → `events#leave_waitlist` (quitter liste d'attente)
- `POST   /events/:id/convert_waitlist_to_attendance` → `events#convert_waitlist_to_attendance` (confirmer place disponible)
- `POST   /events/:id/refuse_waitlist` → `events#refuse_waitlist` (refuser place disponible)
  - Routes protégées par authentification (`authenticate_user!`)
  - Autorisation via Pundit (`join_waitlist?`, `convert_waitlist_to_attendance?`, etc.)
  - Voir [`docs/06-events/waitlist-system.md`](../06-events/waitlist-system.md) pour la documentation complète

### Initiations
- `GET    /initiations` → `initiations#index`
- `GET    /initiations/new` → `initiations#new`
- `POST   /initiations` → `initiations#create`
- `GET    /initiations/:id` → `initiations#show`
- `GET    /initiations/:id/edit` → `initiations#edit`
- `PATCH  /initiations/:id` → `initiations#update`
- `PUT    /initiations/:id` → `initiations#update`
- `DELETE /initiations/:id` → `initiations#destroy`
  - Similaires aux événements généraux mais avec spécificités (sessions samedi, essai gratuit, etc.)

#### Actions membres sur initiations
- `POST   /initiations/:id/attend` → `initiations#attend` (inscription)
- `DELETE /initiations/:id/cancel_attendance` → `initiations#cancel_attendance` (désinscription)
- `GET    /initiations/:id/ical` → `initiations#ical` (export iCal, format `.ics`)
- `PATCH  /initiations/:id/toggle_reminder` → `initiations#toggle_reminder` (activer/désactiver rappel)

#### Routes liste d'attente initiations (waitlist)
- `POST   /initiations/:id/join_waitlist` → `initiations#join_waitlist` (rejoindre liste d'attente)
- `DELETE /initiations/:id/leave_waitlist` → `initiations#leave_waitlist` (quitter liste d'attente)
- `POST   /initiations/:id/convert_waitlist_to_attendance` → `initiations#convert_waitlist_to_attendance` (confirmer place disponible)
- `POST   /initiations/:id/refuse_waitlist` → `initiations#refuse_waitlist` (refuser place disponible)
- `GET    /initiations/:id/waitlist/confirm` → `initiations#confirm_waitlist` (lien email confirmation, redirige vers POST)
- `GET    /initiations/:id/waitlist/decline` → `initiations#decline_waitlist` (lien email refus, redirige vers POST)
  - Routes protégées par authentification
  - Support enfants (child_membership_id)
  - Support essai gratuit (use_free_trial)
  - Voir [`docs/06-events/waitlist-system.md`](../06-events/waitlist-system.md) pour la documentation complète

### Authentification (Devise)
- `devise_for :users, controllers: { registrations: 'registrations', sessions: 'sessions', passwords: 'passwords' }`
  - routes standard: `/users/sign_in`, `/users/sign_out`, `/users/password`, etc.
  - Inscription simplifiée : 4 champs (Email, Prénom, Mot de passe 12 caractères, Niveau)
  - Confirmation email : Accès immédiat, confirmation requise pour actions critiques
  - Email de bienvenue : Envoyé automatiquement après inscription

### Pages légales
- `GET /mentions-legales` → `legal_pages#mentions_legales`
- `GET /politique-confidentialite` → `legal_pages#politique_confidentialite`
- `GET /rgpd` → `legal_pages#politique_confidentialite` (alias)
- `GET /cgv` → `legal_pages#cgv`
- `GET /conditions-generales-vente` → `legal_pages#cgv` (alias)
- `GET /cgu` → `legal_pages#cgu`
- `GET /conditions-generales-utilisation` → `legal_pages#cgu` (alias)
- `GET /contact` → `legal_pages#contact`
  - Toutes les pages sont publiques (pas d'authentification requise)

### Gestion des cookies (RGPD 2025)
- `resource :cookie_consent` (ressource singleton RESTful)
  - `GET /cookie_consent/preferences` → `cookie_consents#preferences`
  - `POST /cookie_consent/accept` → `cookie_consents#accept`
  - `POST /cookie_consent/reject` → `cookie_consents#reject`
  - `PATCH /cookie_consent` → `cookie_consents#update`
  - Routes helpers : `preferences_cookie_consent_path`, `accept_cookie_consent_path`, `reject_cookie_consent_path`, `cookie_consent_path`

### Santé
- `GET /up` → `rails/health#show` (200/500)

## Flux principaux

- Parcours d’achat
  1. `GET /products` → choisir un produit et variantes
  2. `POST /cart/add_item` → ajouter une variante
  3. `GET /cart` → visualiser le panier
  4. `GET /orders/new` → checkout (auth requis)
  5. `POST /orders` → créer la commande (décrémente les stocks)

- Annulation de commande
  1. `PATCH /orders/:id/cancel` → annule si statut autorisé, restaure le stock

- Authentification
  - `GET /users/sign_in` → login via Devise

### Santé (Health Checks)
- `GET /up` → `rails/health#show` (health check simple, 200/500)
- `GET /health` → `health#check` (health check avancé avec DB + migrations, JSON)

### Mode maintenance
- `GET    /maintenance` → Page maintenance statique (pour tests)
- `PATCH  /activeadmin/maintenance/toggle` → `admin/maintenance_toggle#toggle` (activer/désactiver mode maintenance)
  - Protégé par authentification admin

## Notes
- **Administration** : `ActiveAdmin.routes(self)` expose `/admin/*` (accès restreint via Devise + Pundit).
- **Performance** : Les contrôleurs utilisent `includes` pour éviter les N+1 (ex: produits/variantes/options, événements/attendances).
- **Pages légales** : Toutes publiques, conformes aux obligations légales françaises (RGPD, Code de la consommation).
- **Gestion des cookies** : Système conforme RGPD 2025 avec banner automatique et préférences détaillées.
- **Liste d'attente** : Système complet de waitlist pour événements complets. Voir [`docs/06-events/waitlist-system.md`](../06-events/waitlist-system.md).
- **Boucles multiples** : Support événements avec plusieurs boucles via `GET /events/:id/loop_routes`. Voir [`docs/06-events/event-loop-routes.md`](../06-events/event-loop-routes.md).
