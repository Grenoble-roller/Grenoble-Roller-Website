# Helper pour l'authentification dans les tests request
# ✅ Utiliser les helpers natifs de Devise pour les tests request
# sign_in est fourni par Devise::Test::IntegrationHelpers (déjà inclus dans rails_helper.rb)
module RequestAuthenticationHelper
  # Wrapper pour utiliser sign_in de Devise de manière cohérente
  # @param user [User] L'utilisateur à authentifier
  def login_user(user)
    # ✅ Utiliser sign_in natif de Devise (fonctionne avec DatabaseCleaner + truncation)
    # S'assurer que le mapping Devise est configuré
    sign_in user
  rescue RuntimeError => e
    # Fallback: si sign_in échoue, utiliser POST (comme avant)
    # Cela peut arriver si le mapping Devise n'est pas correctement configuré
    if e.message.include?("Could not find a valid mapping")
      post user_session_path, params: {
        user: {
          email: user.email,
          password: 'password12345'
        }
      }
    else
      raise
    end
  end

  def logout_user
    sign_out :user
  end
end

RSpec.configure do |config|
  config.include RequestAuthenticationHelper, type: :request
end
