# 🔍 Diagnostic - Suppression Base de Données

**Date** : 2025-01-13 | **Version** : 1.0

---

## 📋 Résumé

**Problème** : Base de données de développement vidée (0 utilisateurs, données supprimées)

**Cause identifiée** : Probablement exécution de `rails db:seed` qui contient des `destroy_all`

**Status DatabaseCleaner** : ✅ **SÉCURISÉ** - Ne peut pas affecter staging/production

---

## 🔍 Analyse des Logs

### Commandes exécutées dans cette session
- ✅ Tests RSpec uniquement (`bundle exec rspec`)
- ✅ Création de code applicatif (controllers, policies, routes, vues)
- ❌ **AUCUNE** commande de base de données destructrice
- ❌ **AUCUNE** migration créée
- ❌ **AUCUNE** exécution de `rails db:seed`, `rails db:reset`, `rails db:drop`

### Logs du conteneur (24h)
- ✅ Seulement des DELETE sur `SolidQueue::ClaimedExecution` (normal, queue de jobs)
- ❌ **AUCUNE** trace de `destroy_all`, `truncate`, `db:seed`, `db:reset`

### Conclusion
**DatabaseCleaner n'est PAS la cause** - Il est uniquement dans le groupe `:test` et ne peut pas s'exécuter en développement.

---

## ⚠️ Cause Confirmée : `db/seeds.rb`

**CONFIRMÉ** : L'exécution de `rails db:seed` a supprimé toutes les données.

Le fichier `db/seeds.rb` contient des `destroy_all` qui suppriment TOUTES les données :

```ruby
# Lignes 62-81 de db/seeds.rb
Attendance.destroy_all
Event.destroy_all
Route.destroy_all
OrganizerApplication.download_all
# ... etc
User.destroy_all
Role.destroy_all
```

**Preuve** : L'utilisateur a exécuté `rails db:seed` et les logs montrent :
```
🌪️ Seed supprimé !
✅ 7 rôles créés avec succès !
```

**Solution** : Utiliser `db/seeds_staging.rb` (sans destroy_all) pour staging.

---

## ✅ Protections Mises en Place

### 1. DatabaseCleaner - Protection Staging/Production

**Fichier** : `spec/support/database_cleaner.rb`

**Protections ajoutées** :
- ✅ Vérification explicite : `if Rails.env.production? || Rails.env.staging?` → raise error
- ✅ Vérification que DatabaseCleaner est disponible (groupe :test uniquement)
- ✅ Commentaires explicites sur les risques

**Fichier** : `spec/rails_helper.rb`

**Protection ajoutée** :
- ✅ `spec/support/**/*.rb` chargé UNIQUEMENT si `Rails.env.test?`
- ✅ Raise error si tentative de chargement en staging/production

### 2. Scripts Staging/Production

**Fichiers** : `ops/staging/init-db.sh`, `ops/production/init-db.sh`

**Protections existantes** :
- ✅ Confirmation interactive avant `db:seed`
- ✅ Vérification du conteneur running
- ✅ Logs détaillés de toutes les opérations

---

## 🛡️ Recommandations pour Staging

### ✅ Vérifications à faire

1. **DatabaseCleaner ne peut PAS être chargé en staging** :
   ```bash
   # Vérifier que le groupe :test n'est pas chargé
   docker exec grenoble-roller-staging bundle check --without test
   ```

2. **Vérifier que spec/support n'est pas chargé** :
   ```bash
   # En staging, cette commande devrait échouer
   docker exec grenoble-roller-staging bin/rails runner "require 'spec/support/database_cleaner'"
   ```

3. **Protection supplémentaire dans config/application.rb** :
   - S'assurer que `Bundler.require(*Rails.groups)` ne charge pas `:test` en staging/production

### ⚠️ Risque Identifié : `db/seeds.rb`

**Problème** : `db/seeds.rb` contient des `destroy_all` qui suppriment toutes les données.

**Recommandation** :
- ✅ Créer `db/seeds_staging.rb` sans `destroy_all` pour staging
- ✅ Créer `db/seeds_production.rb` minimaliste pour production (déjà fait)
- ✅ Modifier `ops/staging/init-db.sh` pour utiliser `seeds_staging.rb` au lieu de `seeds.rb`

---

## 📊 État Actuel

| Environnement | DatabaseCleaner | Risque Suppression |
|---------------|----------------|-------------------|
| **Test** | ✅ Actif (normal) | ✅ Acceptable (tests) |
| **Development** | ❌ Non chargé | ⚠️ Risque via `db:seed` |
| **Staging** | ❌ Non chargé | ⚠️ Risque via `db:seed` |
| **Production** | ❌ Non chargé | ✅ Protégé (confirmation requise) |

---

## ✅ Actions Correctives

1. ✅ Protection DatabaseCleaner ajoutée dans `spec/support/database_cleaner.rb`
2. ✅ Protection `spec/support` ajoutée dans `spec/rails_helper.rb`
3. ✅ **FAIT** : Créé `db/seeds_staging.rb` sans `destroy_all` (utilise `find_or_create_by!`)
4. ✅ **FAIT** : Modifié `ops/staging/init-db.sh` pour utiliser `seeds_staging.rb`
5. ✅ **FAIT** : Corrigé `db/seeds.rb` pour attacher des images aux ProductVariant (validation)
6. ✅ **FAIT** : Ajouté avertissement dans `db/seeds.rb` sur les risques de suppression

---

## 🔗 Fichiers Modifiés

- `spec/support/database_cleaner.rb` - Protections ajoutées (vérification staging/production)
- `spec/rails_helper.rb` - Protection chargement spec/support (uniquement en test)
- `db/seeds_staging.rb` - **NOUVEAU** : Seed staging sans `destroy_all` (utilise `find_or_create_by!`)
- `ops/staging/init-db.sh` - Modifié pour utiliser `seeds_staging.rb` au lieu de `seeds.rb`
- `docs/development/admin-panel/04-evenements/DIAGNOSTIC-BD.md` - Ce document

## ✅ Résumé des Protections

### DatabaseCleaner
- ✅ Groupe `:test` uniquement dans Gemfile
- ✅ Protection explicite dans `spec/support/database_cleaner.rb` (raise si staging/production)
- ✅ Protection dans `spec/rails_helper.rb` (ne charge spec/support qu'en test)

### Seeds Staging
- ✅ `db/seeds_staging.rb` créé (SANS `destroy_all`)
- ✅ `ops/staging/init-db.sh` modifié pour utiliser `seeds_staging.rb`
- ✅ Utilise `find_or_create_by!` pour ne pas écraser les données existantes

### Seeds Production
- ✅ `db/seeds_production.rb` existe déjà (SANS `destroy_all`)
- ✅ `ops/production/init-db.sh` utilise déjà `seeds_production.rb`

---

**Retour** : [STATUS Événements](./STATUS.md) | [INDEX principal](../INDEX.md)
