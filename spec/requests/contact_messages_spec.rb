# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'ContactMessages (Public)', type: :request do
  describe 'GET /contact' do
    it 'returns success' do
      get contact_path
      expect(response).to have_http_status(:success)
    end

    it 'displays contact form' do
      get contact_path
      expect(response.body).to include('Contactez-nous')
      expect(response.body).to include('name')
      expect(response.body).to include('email')
      expect(response.body).to include('subject')
      expect(response.body).to include('message')
    end
  end

  describe 'POST /contact' do
    context 'with valid params' do
      let(:valid_params) do
        {
          contact_message: {
            name: 'John Doe',
            email: 'john@example.com',
            subject: 'Question sur les initiations',
            message: 'Bonjour, j aimerais en savoir plus sur les initiations.'
          }
        }
      end

      it 'creates a new contact message' do
        expect {
          post contact_path, params: valid_params
        }.to change(ContactMessage, :count).by(1)
      end

      it 'redirects to contact page with success message' do
        post contact_path, params: valid_params
        expect(response).to redirect_to(contact_path)
        expect(flash[:notice]).to include('envoyé avec succès')
      end
    end

    context 'with invalid params' do
      let(:invalid_params) do
        {
          contact_message: {
            name: '',
            email: 'invalid-email',
            subject: '',
            message: 'short'
          }
        }
      end

      it 'does not create a contact message' do
        expect {
          post contact_path, params: invalid_params
        }.not_to change(ContactMessage, :count)
      end

      it 'renders new template with errors' do
        post contact_path, params: invalid_params
        expect(response).to have_http_status(:unprocessable_entity)
        expect(response.body).to include('Erreurs à corriger')
      end
    end
  end
end
