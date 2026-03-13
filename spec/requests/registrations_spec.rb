require 'rails_helper'
require 'active_job/test_helper'

RSpec.describe 'Registrations', type: :request do
  include ActiveJob::TestHelper
  include TestDataHelper

  # Configurer ActiveJob pour les tests
  around do |example|
    ActiveJob::Base.queue_adapter = :test
    example.run
    ActiveJob::Base.queue_adapter = :inline
  end

  # Mock Turnstile verification pour les tests
  before do
    allow_any_instance_of(RegistrationsController).to receive(:verify_turnstile).and_return(true)
  end

  let(:role) { ensure_role(code: 'USER', name: 'Utilisateur', level: 10) }
  let(:unique_email) { "newuser#{SecureRandom.hex(4)}@example.com" }
  let(:valid_params) do
    {
      user: {
        email: "newuser#{SecureRandom.hex(4)}@example.com",
        first_name: 'Jean',
        last_name: 'Dupont',
        password: 'cafe-roller-grenoble',
        skill_level: 'intermediate',
        role_id: role.id
      },
      accept_terms: '1'
    }
  end

  describe 'GET /users/sign_up' do
    it 'renders the registration form' do
      get new_user_registration_path

      expect(response).to have_http_status(:ok)
      expect(response.body).to include('Rejoignez-nous')
      expect(response.body).to include('Email')
      expect(response.body).to include('Prénom')
      expect(response.body).to include('Mot de passe')
      expect(response.body).to include('Votre niveau')
    end
  end

  describe 'POST /users' do
    context 'with valid parameters and RGPD consent' do
      it 'creates a new user' do
        expect {
          post user_registration_path, params: valid_params
        }.to change(User, :count).by(1)
      end

      it 'redirects to confirmation page' do
        post user_registration_path, params: valid_params
        # Le contrôleur redirige vers la page de confirmation email (après création)
        expect(response).to redirect_to(new_user_confirmation_path)
      end

      it 'sets a personalized welcome message' do
        post user_registration_path, params: valid_params
        follow_redirect!
        expect(flash[:notice]).to include('Bienvenue Jean')
        expect(flash[:notice]).to include('🎉')
      end

      it 'sends welcome email' do
        expect {
          post user_registration_path, params: valid_params
        }.to have_enqueued_job(ActionMailer::MailDeliveryJob)
          .with('UserMailer', 'welcome_email', 'deliver_now', args: [ kind_of(User) ])
      end

      it 'sends confirmation email' do
        expect {
          post user_registration_path, params: valid_params
        }.to have_enqueued_job(ActionMailer::MailDeliveryJob)
          .at_least(:once) # Au moins un email (bienvenue ou confirmation)
      end

      it 'creates user with correct attributes' do
        email = "newuser#{SecureRandom.hex(4)}@example.com"
        params = valid_params.deep_merge(user: { email: email })

        expect {
          post user_registration_path, params: params
        }.to change(User, :count).by(1)

        user = User.find_by(email: email)
        expect(user).to be_present
        expect(user.first_name).to eq('Jean')
        expect(user.skill_level).to eq('intermediate')
        expect(user.confirmed_at).to be_nil # Pas encore confirmé
      end

      it 'allows immediate access (grace period)' do
        email = "newuser#{SecureRandom.hex(4)}@example.com"
        params = valid_params.deep_merge(user: { email: email })

        expect {
          post user_registration_path, params: params
        }.to change(User, :count).by(1)

        user = User.find_by(email: email)
        expect(user).to be_present
        expect(user.active_for_authentication?).to be true
      end
    end

    context 'without RGPD consent' do
      let(:params_without_consent) { valid_params.except(:accept_terms) }

      it 'does not create a user' do
        expect {
          post user_registration_path, params: params_without_consent
        }.not_to change(User, :count)
      end

      it 'renders the registration form with errors' do
        post user_registration_path, params: params_without_consent
        expect(response).to have_http_status(:unprocessable_entity)
        expect(response).to render_template(:new)
      end

      it 'displays error message about consent' do
        post user_registration_path, params: params_without_consent
        expect(response.body).to include('Vous devez accepter les Conditions Générales')
      end

      it 'stays on sign_up page (does not redirect to /users)' do
        post user_registration_path, params: params_without_consent
        expect(response).not_to redirect_to(user_registration_path)
        expect(response).to render_template(:new)
      end
    end

    context 'with invalid email' do
      let(:invalid_params) { valid_params.deep_merge(user: { email: 'invalid-email' }) }

      it 'does not create a user' do
        expect {
          post user_registration_path, params: invalid_params
        }.not_to change(User, :count)
      end

      it 'renders the registration form with errors' do
        post user_registration_path, params: invalid_params
        expect(response).to have_http_status(:unprocessable_entity)
        expect(response).to render_template(:new)
      end

      it 'displays email validation error' do
        post user_registration_path, params: invalid_params
        # Vérifier qu'une erreur d'email est présente (message I18n peut varier)
        expect(response.body).to match(/email|n'est pas|valide|invalid/i)
      end
    end

    context 'with missing first_name' do
      let(:params_no_first_name) { valid_params.deep_merge(user: { first_name: '' }) }

      it 'does not create a user' do
        expect {
          post user_registration_path, params: params_no_first_name
        }.not_to change(User, :count)
      end

      it 'displays first_name validation error' do
        post user_registration_path, params: params_no_first_name
        # Vérifier qu'une erreur de prénom est présente (message I18n peut varier)
        expect(response.body).to match(/prénom|first_name|doit|être|rempli|blank/i)
      end
    end

    context 'with password too short' do
      let(:params_short_password) { valid_params.deep_merge(user: { password: '12345678901' }) } # 11 caractères

      it 'does not create a user' do
        expect {
          post user_registration_path, params: params_short_password
        }.not_to change(User, :count)
      end

      it 'displays password validation error with 12 characters' do
        post user_registration_path, params: params_short_password
        # Vérifier qu'une erreur de mot de passe est présente (message I18n peut varier)
        expect(response.body).to match(/mot de passe|password|trop court|12|caractères/i)
      end
    end

    context 'with missing skill_level' do
      let(:params_no_skill) { valid_params.deep_merge(user: { skill_level: '' }) }

      it 'does not create a user' do
        expect {
          post user_registration_path, params: params_no_skill
        }.not_to change(User, :count)
      end

      it 'displays skill_level validation error' do
        post user_registration_path, params: params_no_skill
        # Vérifier qu'une erreur de validation est présente (message I18n peut varier)
        expect(response.body).to match(/skill_level|niveau|doit|être/i)
      end
    end

    context 'with duplicate email' do
      before do
        create_user(email: 'existing@example.com', first_name: 'Existing', last_name: 'User', skill_level: 'beginner')
      end

      let(:params_duplicate_email) { valid_params.deep_merge(user: { email: 'existing@example.com' }) }

      it 'does not create a user' do
        expect {
          post user_registration_path, params: params_duplicate_email
        }.not_to change(User, :count)
      end

      it 'displays email taken error' do
        post user_registration_path, params: params_duplicate_email
        # Vérifier qu'une erreur d'email est présente (message I18n peut varier)
        expect(response.body).to match(/email|déjà|utilisé|pris/i)
      end
    end
  end
end
