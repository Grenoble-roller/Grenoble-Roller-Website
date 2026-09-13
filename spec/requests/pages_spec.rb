# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Pages', type: :request do
  describe 'GET / (home)' do
    it 'returns success' do
      get '/'
      expect(response).to have_http_status(:ok)
    end

    # Regression: tag(:script, content: json) left <script> open and browsers
    # treated stylesheet + importmap as script text → unstyled site, broken JS.
    it 'keeps stylesheet and importmap outside the JSON-LD script' do
      get '/'
      body = response.body

      expect(body).to match(%r{<script type="application/ld\+json">\{.*?"@type":"Organization".*?</script>}m)
      expect(body).not_to match(%r{<script type="application/ld\+json" content=})
      expect(body).to include('stylesheet')
      expect(body).to include('application.bootstrap')
      expect(body).to include('type="importmap"')
    end

    context 'when no active carousel slides exist' do
      it 'returns 200 and shows hero (banner-hero, La communauté Roller Grenobloise)' do
        get '/'
        expect(response).to have_http_status(:ok)
        expect(response.body).to include('banner-hero')
        expect(response.body).to include('La communauté')
        expect(response.body).to include('Roller Grenobloise')
      end

      it 'does not show the announcement banner carousel' do
        get '/'
        expect(response.body).not_to include('id="announcementCarousel"')
      end

      it 'uses the default hero banner without a custom image class' do
        get '/'
        expect(response.body).to include('banner-hero mb-0')
        expect(response.body).not_to include('banner-hero--custom')
      end
    end

    context 'when at least one active carousel slide exists' do
      before do
        create(:homepage_carousel, :active, :with_image, title: 'Événements à venir', position: 1)
      end

      it 'returns 200, shows hero and announcement banner carousel' do
        get '/'
        expect(response).to have_http_status(:ok)
        expect(response.body).to include('banner-hero')
        expect(response.body).to include('id="announcementCarousel"')
        expect(response.body).to include('announcement-banner-carousel')
      end

      it 'includes aria-label for the announcement carousel region' do
        get '/'
        expect(response.body).to include('aria-label="Annonces importantes"')
      end

      it 'enables autoplay for the announcement carousel (data-bs-interval)' do
        get '/'
        expect(response.body).to include('data-bs-interval="6000"')
      end

      it 'shows only active slides (active slide title in body)' do
        get '/'
        expect(response.body).to include('Événements à venir')
      end
    end

    context 'when a custom hero image is configured' do
      before do
        settings = HomepageCarouselSetting.current
        test_image_path = Rails.root.join('spec', 'fixtures', 'files', 'test-image.jpg')
        settings.hero_image.attach(
          io: File.open(test_image_path),
          filename: 'test-image.jpg',
          content_type: 'image/jpeg'
        )
      end

      it 'renders the hero with the custom image class' do
        get '/'
        expect(response.body).to include('banner-hero--custom')
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
