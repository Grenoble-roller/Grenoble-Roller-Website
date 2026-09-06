# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Password Reset', type: :request do
  let!(:role) { ensure_role(code: 'USER', name: 'Utilisateur', level: 10) }
  let(:user) do
    user = build(:user,
                 email: 'test@example.com',
                 password: 'password12345',
                 confirmed_at: Time.current,
                 role: role)
    # Stub les callbacks d'email pour éviter d'envoyer des emails lors de la création
    allow(user).to receive(:send_confirmation_instructions).and_return(true)
    allow(user).to receive(:send_welcome_email_and_confirmation).and_return(true)
    user.save!
    user
  end

  describe 'POST /users/password (demande de réinitialisation)' do
    context 'avec vérification Turnstile réussie' do
      before do
        # Nettoyer les emails AVANT le test pour éviter de compter les emails de création de user
        ActionMailer::Base.deliveries.clear
        # Simuler une vérification Turnstile réussie
        allow_any_instance_of(PasswordsController).to receive(:verify_turnstile).and_return(true)
        # Configurer ActionMailer pour les tests
        ActionMailer::Base.delivery_method = :test
        ActionMailer::Base.perform_deliveries = true
      end

      it 'envoie un email de réinitialisation' do
        # Nettoyer les emails AVANT le test pour éviter de compter les emails de création de user
        ActionMailer::Base.deliveries.clear
        expect do
          post user_password_path, params: { user: { email: user.email } }
        end.to change { ActionMailer::Base.deliveries.count }.by(1)
      end

      it 'redirige avec un message de succès' do
        post user_password_path, params: { user: { email: user.email } }
        expect(response).to have_http_status(:redirect)
        expect(flash[:notice]).to be_present
      end
    end

    context 'avec vérification Turnstile échouée' do
      before do
        # Simuler une vérification Turnstile échouée
        allow_any_instance_of(PasswordsController).to receive(:verify_turnstile).and_return(false)
      end

      it 'ne envoie pas d\'email de réinitialisation' do
        expect do
          post user_password_path, params: { user: { email: user.email } }
        end.not_to change { ActionMailer::Base.deliveries.count }
      end

      it 'affiche un message d\'erreur' do
        post user_password_path, params: { user: { email: user.email } }
        expect(response).to have_http_status(:unprocessable_content)
        expect(response.body).to include('Vérification de sécurité échouée')
      end

      it 'ne crée pas de session utilisateur' do
        post user_password_path, params: { user: { email: user.email } }
        expect(controller.current_user).to be_nil
      end
    end

    context 'sans token Turnstile' do
      before do
        # Simuler l'absence de token Turnstile
        allow_any_instance_of(PasswordsController).to receive(:verify_turnstile).and_return(false)
      end

      it 'bloque la demande de réinitialisation' do
        post user_password_path, params: { user: { email: user.email } }
        expect(response).to have_http_status(:unprocessable_content)
        expect(response.body).to include('Vérification de sécurité échouée')
      end
    end
  end

  describe 'PUT /users/password (changement de mot de passe)' do
    let(:reset_token) { user.send(:set_reset_password_token) }

    context 'avec vérification Turnstile réussie' do
      before do
        # Simuler une vérification Turnstile réussie
        allow_any_instance_of(PasswordsController).to receive(:verify_turnstile).and_return(true)
      end

      it 'réinitialise le mot de passe avec un token valide' do
        new_password = 'newpassword123456'
        put user_password_path, params: {
          user: {
            reset_password_token: reset_token,
            password: new_password,
            password_confirmation: new_password
          }
        }
        expect(response).to have_http_status(:redirect)
        expect(flash[:notice]).to be_present
        # Vérifier que le mot de passe a été changé
        user.reload
        expect(user.valid_password?(new_password)).to be true
      end

      it 'rejette un mot de passe trop court' do
        old_encrypted_password = user.encrypted_password
        put user_password_path, params: {
          user: {
            reset_password_token: reset_token,
            password: 'short',
            password_confirmation: 'short'
          }
        }
        # Vérifier que le mot de passe n'a pas été changé
        user.reload
        expect(user.encrypted_password).to eq(old_encrypted_password)
        # Vérifier que la réponse indique une erreur de validation
        expect(response).to have_http_status(:unprocessable_content)
      end
    end

    context 'avec vérification Turnstile échouée' do
      before do
        # Simuler une vérification Turnstile échouée
        allow_any_instance_of(PasswordsController).to receive(:verify_turnstile).and_return(false)
      end

      it 'ne réinitialise pas le mot de passe' do
        old_encrypted_password = user.encrypted_password
        new_password = 'newpassword123456'
        put user_password_path, params: {
          user: {
            reset_password_token: reset_token,
            password: new_password,
            password_confirmation: new_password
          }
        }
        user.reload
        expect(user.encrypted_password).to eq(old_encrypted_password)
      end

      it 'affiche un message d\'erreur' do
        old_encrypted_password = user.encrypted_password
        new_password = 'newpassword123456'
        put user_password_path, params: {
          user: {
            reset_password_token: reset_token,
            password: new_password,
            password_confirmation: new_password
          }
        }
        # Vérifier que le mot de passe n'a pas été changé
        user.reload
        expect(user.encrypted_password).to eq(old_encrypted_password)
        # Vérifier que la réponse indique une erreur
        expect(response).to have_http_status(:unprocessable_content)
      end
    end

    context 'sans token Turnstile' do
      before do
        # Simuler l'absence de token Turnstile
        allow_any_instance_of(PasswordsController).to receive(:verify_turnstile).and_return(false)
      end

      it 'bloque la réinitialisation du mot de passe' do
        old_encrypted_password = user.encrypted_password
        new_password = 'newpassword123456'
        put user_password_path, params: {
          user: {
            reset_password_token: reset_token,
            password: new_password,
            password_confirmation: new_password
          }
        }
        # Vérifier que le mot de passe n'a pas été changé
        user.reload
        expect(user.encrypted_password).to eq(old_encrypted_password)
        # Vérifier que la réponse indique une erreur
        expect(response).to have_http_status(:unprocessable_content)
      end
    end
  end

  describe 'GET /users/password/new' do
    it 'affiche le formulaire de demande de réinitialisation' do
      get new_user_password_path
      expect(response).to have_http_status(:success)
      expect(response.body).to include('Mot de passe oublié')
    end
  end

  describe 'GET /users/password/edit' do
    let(:reset_token) { user.send(:set_reset_password_token) }

    context 'avec un token valide' do
      it 'affiche le formulaire de réinitialisation' do
        get edit_user_password_path, params: { reset_password_token: reset_token }
        expect(response).to have_http_status(:success)
        expect(response.body).to include('Réinitialiser le mot de passe')
      end
    end

    context 'sans token' do
      it 'redirige vers la demande de réinitialisation ou la connexion' do
        get edit_user_password_path
        expect(response).to have_http_status(:redirect)
      end
    end

    context 'avec un utilisateur connecté' do
      before { sign_in user }

      it 'redirige vers le profil si pas de token' do
        get edit_user_password_path
        expect(response).to have_http_status(:redirect)
      end

      it 'permet la réinitialisation si un token est présent' do
        get edit_user_password_path, params: { reset_password_token: reset_token }
        expect(response).to have_http_status(:success)
        expect(response.body).to include('Réinitialiser le mot de passe')
      end
    end
  end
end
