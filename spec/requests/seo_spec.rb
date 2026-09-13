# frozen_string_literal: true

require "rails_helper"

RSpec.describe "SEO crawlability", type: :request do
  describe "GET /robots.txt" do
    it "returns text/plain with Allow and Sitemap pointing at this host" do
      get robots_path

      expect(response).to have_http_status(:ok)
      expect(response.media_type).to eq("text/plain")
      expect(response.body).to include("User-agent: *")
      expect(response.body).to include("Allow: /")
      expect(response.body).to include("Disallow: /admin-panel")
      expect(response.body).to include("Sitemap: http://www.example.com/sitemap.xml")
    end
  end

  describe "GET /llms.txt" do
    it "returns text/plain with site summary and host-aware links" do
      get llms_path

      expect(response).to have_http_status(:ok)
      expect(response.media_type).to eq("text/plain")
      expect(response.body).to include("# Grenoble Roller")
      expect(response.body).to include("http://www.example.com/shop")
      expect(response.body).to include("http://www.example.com/sitemap.xml")
      expect(response.body).to include("Initiations")
    end
  end

  describe "GET /sitemap.xml" do
    let!(:active_product) do
      product = create(:product, is_active: true, slug: "sitemap-product")
      create(:product_variant, product: product, is_active: true)
      product
    end
    let!(:inactive_product) do
      product = create(:product, is_active: false, slug: "hidden-product")
      create(:product_variant, product: product, is_active: true)
      product
    end
    let!(:published_event) { create(:event, :published, title: "Sitemap Event") }
    let!(:draft_event) { create(:event, title: "Draft Event") }
    let!(:published_initiation) { create(:event_initiation, :published) }
    let!(:draft_initiation) { create(:event_initiation, :draft) }

    it "returns a valid urlset with public pages and visible resources only" do
      get sitemap_path

      expect(response).to have_http_status(:ok)
      expect(response.media_type).to include("xml")

      body = response.body
      expect(body).to include('xmlns="http://www.sitemaps.org/schemas/sitemap/0.9"')
      expect(body).to include("http://www.example.com/")
      expect(body).to include("http://www.example.com/shop")
      expect(body).to include("http://www.example.com/events")
      expect(body).to include("http://www.example.com/a-propos")
      expect(body).to include(product_url(active_product.slug, host: "www.example.com"))
      expect(body).not_to include(product_url(inactive_product.slug, host: "www.example.com"))
      expect(body).to include(event_url(published_event, host: "www.example.com"))
      expect(body).not_to include(event_url(draft_event, host: "www.example.com"))
      expect(body).to include(initiation_url(published_initiation, host: "www.example.com"))
      expect(body).not_to include(initiation_url(draft_initiation, host: "www.example.com"))
    end
  end
end
