# frozen_string_literal: true

# ⚠️ PROTECTION CRITIQUE : DatabaseCleaner NE DOIT JAMAIS s'exécuter en staging/production
# Ce fichier est chargé UNIQUEMENT dans l'environnement de test via rails_helper.rb
# qui charge spec/support/**/*.rb uniquement quand RAILS_ENV=test

# Vérification de sécurité supplémentaire - DOIT être la première chose
if Rails.env.production? || Rails.env.staging?
  raise "❌ ERREUR CRITIQUE : DatabaseCleaner ne peut PAS être chargé en #{Rails.env}!"
end

# DatabaseCleaner est uniquement disponible dans le groupe :test du Gemfile
# Si on arrive ici, c'est qu'on est en test, donc DatabaseCleaner devrait être disponible
begin
  require 'database_cleaner/active_record'
rescue LoadError => e
  raise "❌ DatabaseCleaner n'est pas disponible (devrait être dans le groupe :test du Gemfile): #{e.message}"
end

# Désactiver la protection DatabaseCleaner pour les URLs distantes (environnement de test contrôlé)
# ⚠️ Cette configuration est SANS RISQUE car ce fichier n'est chargé qu'en test
DatabaseCleaner.allow_remote_database_url = true

RSpec.configure do |config|
  # ✅ CRITIQUE: Les tests request ne peuvent pas utiliser les transactions
  # car Devise a besoin d'accéder à la BD depuis la session
  # Transactional tests SEULEMENT pour model/controller (pas request!)

  config.before(:suite) do
    DatabaseCleaner.clean_with(:truncation)
  end

  config.before(:each) do
    # Par défaut, utiliser les transactions (plus rapide)
    DatabaseCleaner.strategy = :transaction
  end

  config.before(:each, type: :request) do
    # ❌ Les tests request ne peuvent pas utiliser les transactions
    # car Devise a besoin d'accéder à la BD depuis la session
    DatabaseCleaner.strategy = :truncation
  end

  config.before(:each, js: true) do
    # Les tests JavaScript nécessitent aussi truncation
    DatabaseCleaner.strategy = :truncation
  end

  config.before(:each) do
    DatabaseCleaner.start
  end

  config.after(:each) do
    DatabaseCleaner.clean
  end
end
