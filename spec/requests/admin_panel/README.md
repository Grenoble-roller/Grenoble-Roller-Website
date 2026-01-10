# Tests RSpec - AdminPanel

## 📋 Structure des Tests

### **Policies** (`spec/policies/admin_panel/`)
- `base_policy_spec.rb` - Tests de la policy de base (level >= 60)
- `event/initiation_policy_spec.rb` - Tests des permissions initiations (lecture level >= 30, écriture level >= 60)
- `order_policy_spec.rb` - Tests des permissions commandes (level >= 60)
- `product_policy_spec.rb` - Tests des permissions produits (level >= 60)
- `roller_stock_policy_spec.rb` - Tests des permissions stock rollers (level >= 60)
- `user_policy_spec.rb` - Tests des permissions utilisateurs (level >= 60)
- `role_policy_spec.rb` - Tests des permissions rôles (level >= 60)
- `membership_policy_spec.rb` - Tests des permissions adhésions (level >= 60)

### **Requests** (`spec/requests/admin_panel/`)
- `base_controller_spec.rb` - Tests d'authentification et autorisation BaseController
- `initiations_spec.rb` - Tests du controller InitiationsController
- `dashboard_spec.rb` - Tests du controller DashboardController
- `orders_spec.rb` - Tests du controller OrdersController
- `users_spec.rb` - Tests du controller UsersController
- `roles_spec.rb` - Tests du controller RolesController
- `memberships_spec.rb` - Tests du controller MembershipsController
- `routes_spec.rb` - Tests du controller RoutesController (18 exemples)
- `attendances_spec.rb` - Tests du controller AttendancesController (18 exemples)
- `organizer_applications_spec.rb` - Tests du controller OrganizerApplicationsController (20 exemples)
- `payments_spec.rb` - Tests du controller PaymentsController (22 exemples)
- `contact_messages_spec.rb` - Tests du controller ContactMessagesController (14 exemples)
- `partners_spec.rb` - Tests du controller PartnersController (16 exemples)
- `events_spec.rb` - Tests du controller EventsController (21 exemples)

## 🎯 Permissions Testées

### **Grade 30 (INITIATION)**
- ✅ Peut accéder à `/admin-panel/initiations` (index, show)
- ❌ Ne peut pas créer/modifier/supprimer
- ❌ Ne peut pas accéder au dashboard
- ❌ Ne peut pas accéder aux commandes

### **Grade 40 (ORGANIZER)**
- ✅ Peut accéder à `/admin-panel/initiations` (index, show)
- ❌ Ne peut pas créer/modifier/supprimer
- ❌ Ne peut pas accéder au dashboard
- ❌ Ne peut pas accéder aux commandes
- ❌ Ne peut accéder à AUCUNE autre ressource

### **Grade 60 (ADMIN)**
- ✅ Accès complet à toutes les ressources
- ✅ Peut créer/modifier/supprimer des initiations
- ✅ Peut gérer les présences
- ✅ Peut accéder au dashboard
- ✅ Peut accéder aux commandes
- ✅ Peut gérer les utilisateurs (CRUD complet)
- ✅ Peut gérer les rôles (CRUD complet)
- ✅ Peut gérer les adhésions (CRUD complet, activer)
- ✅ Peut gérer les événements (index, show, destroy + waitlist actions)
- ✅ Peut gérer les routes (CRUD complet)
- ✅ Peut gérer les participations (CRUD complet)
- ✅ Peut gérer les candidatures organisateur (index, show, approve, reject, destroy)
- ✅ Peut gérer les paiements (index, show, destroy)
- ✅ Peut gérer les messages de contact (index, show, destroy)
- ✅ Peut gérer les partenaires (CRUD complet)
- ✅ Peut gérer les événements (index, show, destroy, convert_waitlist, notify_waitlist)

### **Grade 70 (SUPERADMIN)**
- ✅ Accès complet (identique à ADMIN)

## 🚀 Exécution des Tests

### **Dans Docker (Recommandé)**
```bash
# Tous les tests AdminPanel
docker compose -f ops/dev/docker-compose.yml run --rm \
  -e BUNDLE_PATH=/rails/vendor/bundle \
  -e DATABASE_URL=postgresql://postgres:postgres@db:5432/app_test \
  -e RAILS_ENV=test \
  web bundle exec rspec spec/policies/admin_panel spec/requests/admin_panel

# Tests des policies uniquement
docker compose -f ops/dev/docker-compose.yml run --rm \
  -e BUNDLE_PATH=/rails/vendor/bundle \
  -e DATABASE_URL=postgresql://postgres:postgres@db:5432/app_test \
  -e RAILS_ENV=test \
  web bundle exec rspec spec/policies/admin_panel

# Tests des controllers uniquement
docker compose -f ops/dev/docker-compose.yml run --rm \
  -e BUNDLE_PATH=/rails/vendor/bundle \
  -e DATABASE_URL=postgresql://postgres:postgres@db:5432/app_test \
  -e RAILS_ENV=test \
  web bundle exec rspec spec/requests/admin_panel

# Test spécifique avec ordre défini (recommandé pour développement)
docker compose -f ops/dev/docker-compose.yml run --rm \
  -e BUNDLE_PATH=/rails/vendor/bundle \
  -e DATABASE_URL=postgresql://postgres:postgres@db:5432/app_test \
  -e RAILS_ENV=test \
  web bundle exec rspec spec/requests/admin_panel/users_spec.rb \
  --format progress --order defined

# Test avec ordre aléatoire (recommandé pour CI/CD)
docker compose -f ops/dev/docker-compose.yml run --rm \
  -e BUNDLE_PATH=/rails/vendor/bundle \
  -e DATABASE_URL=postgresql://postgres:postgres@db:5432/app_test \
  -e RAILS_ENV=test \
  web bundle exec rspec spec/requests/admin_panel/users_spec.rb \
  --format progress --order random --seed 12345
```

### **Localement (si configuré)**
```bash
# Tous les tests AdminPanel
bundle exec rspec spec/policies/admin_panel spec/requests/admin_panel

# Tests des policies uniquement
bundle exec rspec spec/policies/admin_panel

# Tests des controllers uniquement
bundle exec rspec spec/requests/admin_panel

# Test spécifique
bundle exec rspec spec/policies/admin_panel/event/initiation_policy_spec.rb
```

## 📝 Notes

- Les factories utilisent les traits `:initiation`, `:organizer`, `:admin`, `:superadmin`
- Les tests vérifient à la fois les policies (Pundit) et les controllers (authentification)
- Les redirections et messages d'erreur sont testés
- **Configuration DatabaseCleaner** : Les tests request utilisent `truncation` (pas de transactions) pour permettre à Devise de fonctionner correctement
- **Authentification** : Utiliser `login_user` au lieu de `sign_in` dans les tests request (voir `spec/support/request_authentication_helper.rb`)

## 🔍 Bonnes Pratiques

Voir `spec/README.md` pour la documentation complète sur :
- Configuration DatabaseCleaner
- Isolation des tests
- Création des rôles et emails uniques
- Debugging des problèmes d'état partagé
