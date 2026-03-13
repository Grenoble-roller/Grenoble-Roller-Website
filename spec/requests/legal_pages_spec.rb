require 'rails_helper'

RSpec.describe 'LegalPages', type: :request do
  describe 'GET /mentions-legales' do
    it 'returns success' do
      get mentions_legales_path
      expect(response).to have_http_status(:success)
      expect(response.body).to include('Mentions')
    end
  end

  describe 'GET /politique-confidentialite' do
    it 'returns success' do
      get politique_confidentialite_path
      expect(response).to have_http_status(:success)
      expect(response.body).to include('Confidentialité').or include('RGPD')
    end
  end

  describe 'GET /cgv' do
    it 'returns success' do
      get cgv_path
      expect(response).to have_http_status(:success)
      expect(response.body).to include('Conditions').or include('vente')
    end
  end

  describe 'GET /cgu' do
    it 'returns success' do
      get cgu_path
      expect(response).to have_http_status(:success)
    end
  end

  describe 'GET /faq' do
    it 'returns success' do
      get faq_path
      expect(response).to have_http_status(:success)
    end
  end
end
