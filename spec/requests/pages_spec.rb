# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Pages', type: :request do
  describe 'GET / (home)' do
    it 'returns success' do
      get '/'
      expect(response).to have_http_status(:ok)
    end

    context 'when no active carousel slides exist' do
      it 'returns 200 and shows fallback hero (banner-hero, La communauté Roller Grenobloise)' do
        get '/'
        expect(response).to have_http_status(:ok)
        expect(response.body).to include('banner-hero')
        expect(response.body).to include('La communauté')
        expect(response.body).to include('Roller Grenobloise')
      end

      it 'does not show the carousel' do
        get '/'
        expect(response.body).not_to include('id="homepageCarousel"')
      end
    end

    context 'when at least one active carousel slide exists' do
      before do
        create(:homepage_carousel, :active, :with_image, title: 'Événements à venir', position: 1)
      end

      it 'returns 200 and shows the carousel' do
        get '/'
        expect(response).to have_http_status(:ok)
        expect(response.body).to include('id="homepageCarousel"')
        expect(response.body).to include('hero-carousel')
      end

      it 'includes aria-label for the carousel region' do
        get '/'
        expect(response.body).to include('aria-label="Carrousel des mises en avant"')
      end

      it 'does not enable autoplay by default (no data-bs-ride="carousel")' do
        get '/'
        expect(response.body).not_to include('data-bs-ride="carousel"')
      end

      it 'shows only active slides (active slide title in body)' do
        get '/'
        expect(response.body).to include('Événements à venir')
      end
    end

    context 'when an inactive or expired slide exists' do
      it 'does not show inactive slide in carousel' do
        create(:homepage_carousel, :with_image, title: 'Slide actif', position: 1, published: true, published_at: 1.day.ago, expires_at: nil)
        create(:homepage_carousel, title: 'Slide inactif', position: 2, published: false)
        get '/'
        expect(response.body).to include('Slide actif')
        expect(response.body).not_to include('Slide inactif')
      end
    end
  end

  describe 'GET /association' do
    it 'returns success or redirect' do
      get '/association'
      expect([ :success, :redirect, :moved_permanently ].include?(response.status / 100) || response.status == 200 || response.status == 301).to be true
    end
  end
end
