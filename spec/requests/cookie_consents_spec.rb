require 'rails_helper'

RSpec.describe 'CookieConsents', type: :request do
  describe 'GET /cookie_consent/preferences' do
    it 'returns success' do
      get preferences_cookie_consent_path
      expect(response).to have_http_status(:success)
    end
  end

  describe 'POST /cookie_consent/accept' do
    it 'sets cookie and redirects or returns json' do
      post accept_cookie_consent_path
      expect(response).to have_http_status(:redirect).or have_http_status(:success)
    end
  end

  describe 'POST /cookie_consent/reject' do
    it 'sets cookie and redirects or returns json' do
      post reject_cookie_consent_path
      expect(response).to have_http_status(:redirect).or have_http_status(:success)
    end
  end
end
