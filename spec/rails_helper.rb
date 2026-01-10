# This file is copied to spec/ when you run 'rails generate rspec:install'
require 'spec_helper'
ENV['RAILS_ENV'] ||= 'test'
require_relative '../config/environment'
# Prevent database truncation if the environment is production
abort("The Rails environment is running in production mode!") if Rails.env.production?
# Uncomment the line below in case you have `--require rails_helper` in the `.rspec` file
# that will avoid rails generators crashing because migrations haven't been run yet
# return unless Rails.env.test?
require 'rspec/rails'
# Add additional requires below this line. Rails is not loaded until this point!

# Requires supporting ruby files with custom matchers and macros, etc, in
# spec/support/ and its subdirectories. Files matching `spec/**/*_spec.rb` are
# run as spec files by default. This means that files in spec/support that end
# in _spec.rb will both be required and run as specs, causing the specs to be
# run twice. It is recommended that you do not name files matching this glob to
# end with _spec.rb. You can configure this pattern with the --pattern
# option on the command line or in ~/.rspec, .rspec or `.rspec-local`.
#
# The following line is provided for convenience purposes. It has the downside
# of increasing the boot-up time by auto-requiring all files in the support
# directory. Alternatively, in the individual `*_spec.rb` files, manually
# require only the support files necessary.
#
# ⚠️ PROTECTION CRITIQUE : Ne charger spec/support QUE en environnement de test
# Les fichiers dans spec/support (notamment database_cleaner.rb) ne doivent JAMAIS
# être chargés en staging/production car ils contiennent du code destructif
if Rails.env.test?
  Rails.root.glob('spec/support/**/*.rb').sort_by(&:to_s).each { |f| require f }
else
  raise "❌ ERREUR CRITIQUE : spec/support ne peut être chargé qu'en environnement de test! (actuel: #{Rails.env})"
end

# Ensures that the test database schema matches the current schema file.
# If there are pending migrations it will invoke `db:test:prepare` to
# recreate the test database by loading the schema.
# If you are not using ActiveRecord, you can remove these lines.
begin
  ActiveRecord::Migration.maintain_test_schema!
rescue ActiveRecord::PendingMigrationError => e
  abort e.to_s.strip
end
# Configurer les traductions par défaut pour les tests
I18n.default_locale = :fr
I18n.locale = :fr

# Ajouter les traductions manquantes
I18n.backend.store_translations(:fr, {
  activerecord: {
    errors: {
      messages: {
        record_invalid: "L'enregistrement est invalide"
      }
    }
  }
})

RSpec.configure do |config|
  # Remove this line if you're not using ActiveRecord or ActiveRecord fixtures
  config.fixture_paths = [
    Rails.root.join('spec/fixtures')
  ]

  # ✅ CRITIQUE: Désactiver les transactions pour permettre DatabaseCleaner
  # de gérer le nettoyage avec la bonne stratégie (transaction vs truncation)
  # Les tests request nécessitent truncation car Devise accède à la BD depuis la session
  config.use_transactional_fixtures = false

  # You can uncomment this line to turn off ActiveRecord support entirely.
  # config.use_active_record = false

  # RSpec Rails uses metadata to mix in different behaviours to your tests,
  # for example enabling you to call `get` and `post` in request specs. e.g.:
  #
  #     RSpec.describe UsersController, type: :request do
  #       # ...
  #     end
  #
  # The different available types are documented in the features, such as in
  # https://rspec.info/features/8-0/rspec-rails
  #
  # You can also this infer these behaviours automatically by location, e.g.
  # /spec/models would pull in the same behaviour as `type: :model` but this
  # behaviour is considered legacy and will be removed in a future version.
  #
  # Infer spec type (model/request/etc.) from file location
  config.infer_spec_type_from_file_location!

  # Filter lines from Rails gems in backtraces.
  config.filter_rails_from_backtrace!
  # arbitrary gems may also be filtered via:
  # config.filter_gems_from_backtrace("gem name")

  config.include FactoryBot::Syntax::Methods
  config.include Devise::Test::IntegrationHelpers, type: :request
  config.include Devise::Test::IntegrationHelpers, type: :system
  config.include TestDataHelper if defined?(TestDataHelper)

  # Configurer le mapping Devise pour TOUS les tests de contrôleurs
  # Cela doit être fait AVANT que les contrôleurs Devise ne soient initialisés
  # Le mapping doit être dans request.env AVANT que prepend_before_action ne soit appelé
  config.before(:each, type: :controller) do
    @request.env["devise.mapping"] = Devise.mappings[:user]
    request.env["devise.mapping"] = Devise.mappings[:user]
    # Surcharger devise_mapping pour tous les contrôleurs Devise
    # Cela doit être fait AVANT que assert_is_devise_resource! ne soit appelé
    if described_class && described_class < Devise::DeviseController
      allow_any_instance_of(described_class).to receive(:devise_mapping).and_return(Devise.mappings[:user])
    end
  end

  # Bypass CSRF protection in request specs
  config.before(:each, type: :request) do
    allow_any_instance_of(ActionController::Base).to receive(:protect_against_forgery?).and_return(false)
  end

  # Configuration des emails en test
  config.before(:each) do
    ActionMailer::Base.delivery_method = :test
    # Activer les deliveries pour les tests de jobs (ils utilisent perform_enqueued_jobs)
    ActionMailer::Base.perform_deliveries = true
  end

  config.after(:each) do
    ActionMailer::Base.deliveries.clear
  end

  # Capybara configuration for system/feature tests
  # Use rack_test for non-JS tests (faster, no browser needed)
  config.before(:each, type: :system) do
    driven_by :rack_test
  end

  # Use headless Chrome for JS tests (modals, JavaScript interactions)
  config.before(:each, type: :system, js: true) do
    driven_by :selenium_chrome_headless
  end
end
