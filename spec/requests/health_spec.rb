require 'rails_helper'

RSpec.describe 'Health', type: :request do
  describe 'GET /health' do
    it 'returns JSON with status, database and migrations (200 or 503 if migrations pending)' do
      get health_check_path
      expect(response.status).to be_in([ 200, 503 ])
      expect(response.media_type).to include('application/json')

      json = JSON.parse(response.body)
      expect(json).to have_key('status')
      expect(json).to have_key('database')
      expect(json).to have_key('migrations')
      expect(json['migrations']).to have_key('pending_count')
      expect(json).to have_key('timestamp')
    end

    it 'does not require authentication' do
      get health_check_path
      expect([ 200, 503 ]).to include(response.status)
    end
  end
end
