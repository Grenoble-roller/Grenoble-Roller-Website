# Tests RSpec - Configuration et Bonnes Pratiques

## 📋 Vue d'Ensemble

Ce document décrit la configuration des tests RSpec pour le projet Grenoble Roller, en particulier pour les tests request avec Devise et DatabaseCleaner.

## 🔧 Configuration Principale

### **DatabaseCleaner** (`spec/support/database_cleaner.rb`)

DatabaseCleaner est utilisé pour gérer le nettoyage de la base de données entre les tests.

**Pourquoi DatabaseCleaner ?**
- Les tests request avec Devise nécessitent `truncation` (pas de transactions)
- Les tests model/controller peuvent utiliser `transaction` (plus rapide)
- DatabaseCleaner permet de choisir la stratégie selon le type de test

**Configuration :**
```ruby
# Par défaut : transaction (rapide)
config.before(:each) do
  DatabaseCleaner.strategy = :transaction
end

# Tests request : truncation (nécessaire pour Devise)
config.before(:each, type: :request) do
  DatabaseCleaner.strategy = :truncation
end
```

**Important :**
- `use_transactional_fixtures = false` dans `rails_helper.rb` pour permettre à DatabaseCleaner de fonctionner
- La protection pour les URLs distantes est désactivée (`DatabaseCleaner.allow_remote_database_url = true`) car nous sommes dans un environnement Docker contrôlé

### **Authentification dans les Tests Request** (`spec/support/request_authentication_helper.rb`)

**Problème résolu :**
- `sign_in` de Devise peut échouer avec l'erreur "Could not find a valid mapping"
- Solution : wrapper `login_user` qui utilise `sign_in` avec fallback vers POST si nécessaire

**Utilisation :**
```ruby
before { login_user(admin_user) }
```

**Fonctionnement :**
1. Essaie d'abord `sign_in` (méthode native Devise)
2. Si échec avec "Could not find a valid mapping", utilise POST vers `user_session_path`
3. Maintient la session pour les requêtes suivantes

## 🎯 Bonnes Pratiques pour les Tests Request

### **1. Isolation des Tests**

**❌ À éviter :**
```ruby
# let partagé au niveau du describe (état partagé)
let(:admin_user) { create(:user, :admin) }
let(:target_user) { create(:user) }

describe 'GET /admin-panel/users' do
  # Utilise admin_user et target_user partagés
end

describe 'POST /admin-panel/users' do
  # Utilise admin_user et target_user partagés (problème !)
end
```

**✅ À faire :**
```ruby
describe 'GET /admin-panel/users' do
  let(:admin_user) { create(:user, :admin) }  # Créé dans ce contexte uniquement
  
  before { login_user(admin_user) }
  
  it 'returns success' do
    get admin_panel_users_path
    expect(response).to have_http_status(:success)
  end
end

describe 'POST /admin-panel/users' do
  let(:admin_user) { create(:user, :admin) }  # Créé dans ce contexte uniquement
  
  before { login_user(admin_user) }
  
  it 'creates a new user' do
    # Créer les params à l'intérieur du test
    params = { user: { ... } }
    post admin_panel_users_path, params: params
  end
end
```

### **2. Création des Rôles**

**❌ À éviter :**
```ruby
# Créer un rôle avec un code fixe dans un let (conflit d'unicité)
let(:user_role) { create(:role, code: 'USER') }

# Utiliser create(:role_user) plusieurs fois (conflit d'unicité)
role_id: create(:role_user).id
```

**✅ À faire :**
```ruby
# Pour les rôles standards (codes fixes), utiliser find_or_create_by!
user_role = Role.find_or_create_by!(code: 'USER') { |r| 
  r.name = 'Utilisateur'
  r.level = 10 
}
role_id: user_role.id

# Pour les rôles dynamiques, utiliser sequence dans la factory
create(:role)  # Utilise sequence(:code) pour éviter les conflits
```

### **3. Unicité des Emails**

**❌ À éviter :**
```ruby
# Email statique (conflit si test exécuté plusieurs fois)
email: "test@example.com"
```

**✅ À faire :**
```ruby
# Email unique avec SecureRandom ou timestamp
email: "newuser_#{SecureRandom.hex(4)}@example.com"
email: "user#{n}_#{Time.now.to_i}@example.com"  # Dans les factories
```

### **4. Création des Params**

**❌ À éviter :**
```ruby
# let partagé pour les params (évalué une seule fois)
let(:valid_params) do
  { user: { email: "...", role_id: create(:role_user).id } }
end

it 'creates a user' do
  post admin_panel_users_path, params: valid_params
end

it 'redirects' do
  post admin_panel_users_path, params: valid_params  # Même rôle créé !
end
```

**✅ À faire :**
```ruby
it 'creates a user' do
  # Créer les params à l'intérieur du test
  params = {
    user: {
      email: "newuser_#{SecureRandom.hex(4)}@example.com",
      role_id: Role.find_or_create_by!(code: 'USER') { |r| r.name = 'Utilisateur'; r.level = 10 }.id
    }
  }
  post admin_panel_users_path, params: params
end
```

## 🧪 Exécution des Tests

### **Ordre Défini (Recommandé pour le développement)**
```bash
docker compose -f ops/dev/docker-compose.yml run --rm \
  -e BUNDLE_PATH=/rails/vendor/bundle \
  -e DATABASE_URL=postgresql://postgres:postgres@db:5432/app_test \
  -e RAILS_ENV=test \
  web bundle exec rspec spec/requests/admin_panel/users_spec.rb \
  --format progress --order defined
```

### **Ordre Aléatoire avec Seed (Recommandé pour CI/CD)**
```bash
docker compose -f ops/dev/docker-compose.yml run --rm \
  -e BUNDLE_PATH=/rails/vendor/bundle \
  -e DATABASE_URL=postgresql://postgres:postgres@db:5432/app_test \
  -e RAILS_ENV=test \
  web bundle exec rspec spec/requests/admin_panel/users_spec.rb \
  --format progress --order random --seed 12345
```

### **Test Individuel (Debug)**
```bash
docker compose -f ops/dev/docker-compose.yml run --rm \
  -e BUNDLE_PATH=/rails/vendor/bundle \
  -e DATABASE_URL=postgresql://postgres:postgres@db:5432/app_test \
  -e RAILS_ENV=test \
  web bundle exec rspec spec/requests/admin_panel/users_spec.rb:117 \
  --format documentation
```

## 📊 Résultats Attendus

### **Tests Stables**
- ✅ `--order defined` : Tous les tests passent
- ✅ `--order random --seed 12345` : Tous les tests passent
- ⚠️ `--order random` (sans seed) : Peut avoir des échecs intermittents selon l'ordre

### **Indicateurs de Problèmes**

**Si les tests passent individuellement mais échouent en série :**
- → Problème d'état partagé
- → Vérifier les `let` partagés au niveau du `describe`
- → Vérifier la création des rôles et emails

**Si les tests passent avec `--order defined` mais échouent avec `--order random` :**
- → Problème d'isolation entre les tests
- → Vérifier DatabaseCleaner (truncation pour request specs)
- → Vérifier la gestion des sessions

**Si `sign_in` échoue avec "Could not find a valid mapping" :**
- → Utiliser `login_user` au lieu de `sign_in`
- → Le fallback POST devrait résoudre le problème

## 🔍 Debugging

### **Vérifier l'État de la Base de Données**
```bash
docker compose -f ops/dev/docker-compose.yml run --rm \
  -e RAILS_ENV=test \
  web bundle exec rails dbconsole
```

### **Afficher les Routes**
```bash
docker compose -f ops/dev/docker-compose.yml run --rm \
  -e RAILS_ENV=test \
  web bundle exec rails routes | grep admin_panel
```

### **Vérifier la Configuration DatabaseCleaner**
```ruby
# Dans rails console
require 'database_cleaner'
DatabaseCleaner.strategy
DatabaseCleaner.allow_remote_database_url
```

## 📚 Références

- [DatabaseCleaner Documentation](https://github.com/DatabaseCleaner/database_cleaner)
- [Devise Test Helpers](https://github.com/heartcombo/devise#test-helpers)
- [RSpec Rails Documentation](https://rspec.info/documentation/latest/rspec-rails/)

## ✅ Checklist pour Nouveaux Tests Request

- [ ] Utiliser `login_user` au lieu de `sign_in`
- [ ] Créer les utilisateurs/rôles dans chaque contexte (pas de `let` partagé)
- [ ] Utiliser `find_or_create_by!` pour les rôles standards (codes fixes)
- [ ] Utiliser `SecureRandom` ou timestamp pour les emails uniques
- [ ] Créer les params à l'intérieur des tests (pas de `let` pour les params)
- [ ] Tester avec `--order defined` et `--order random --seed 12345`
- [ ] Vérifier que DatabaseCleaner utilise `truncation` pour les request specs
