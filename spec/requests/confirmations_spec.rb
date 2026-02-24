require 'rails_helper'

RSpec.describe 'Confirmations', type: :request do
  describe 'GET /users/confirmation/new' do
    it 'returns success' do
      get new_user_confirmation_path
      expect(response).to have_http_status(:success)
    end
  end

  describe 'POST /users/confirmation (resend)' do
    it 'accepts request and responds (anti-enumeration: same response for existing or not)' do
      post user_confirmation_path, params: { user: { email: 'nonexistent@example.com' } }
      expect(response).to have_http_status(:success)
    end
  end
end
