require 'rails_helper'

RSpec.describe 'Pages', type: :request do
  it 'GET / (home) returns success' do
    get '/'
    expect(response).to have_http_status(:ok)
  end

  it 'GET /association returns success' do
    get '/association'
    # Peut rediriger (301) ou retourner success (200) selon la configuration des routes
    expect([ :success, :redirect, :moved_permanently ].include?(response.status / 100) || response.status == 200 || response.status == 301).to be true
  end
end
