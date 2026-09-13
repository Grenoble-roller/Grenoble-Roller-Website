# frozen_string_literal: true

# Public crawlability endpoints for search engines and SEO scanners.
# Served dynamically so Sitemap: uses the current request host (prod vs staging).
class SeoController < ApplicationController
  layout false

  # GET /robots.txt
  def robots
    expires_in 12.hours, public: true
    render plain: robots_body, content_type: "text/plain; charset=utf-8"
  end

  # GET /sitemap.xml
  def sitemap
    expires_in 1.hour, public: true
    @entries = sitemap_entries
    respond_to do |format|
      format.xml
    end
  end

  # GET /llms.txt — guidance for AI agents (https://llmstxt.org/)
  def llms
    expires_in 12.hours, public: true
    render plain: llms_body, content_type: "text/plain; charset=utf-8"
  end

  private

  def robots_body
    <<~ROBOTS
      # Grenoble Roller
      User-agent: *
      Allow: /

      # Private / account areas
      Disallow: /admin-panel
      Disallow: /users/
      Disallow: /cart
      Disallow: /checkout
      Disallow: /orders
      Disallow: /attendances
      Disallow: /cookie_consent

      Sitemap: #{request.base_url}/sitemap.xml
    ROBOTS
  end

  def llms_body
    base = request.base_url
    <<~LLMS
      # Grenoble Roller

      > Official website of the Grenoble Roller association (inline skating club in Grenoble, France).

      Public content is in French. The site covers the shop, roller events (randos), free initiation sessions, memberships (HelloAsso), and association info.

      Do not invent prices, event dates, or membership rules — prefer the linked pages and the live sitemap.

      ## Main pages

      - [Home](#{base}/): Association overview and news
      - [About](#{base}/a-propos): Who we are
      - [Shop](#{base}/shop): Merch and products catalog
      - [Events](#{base}/events): Public roller outings (randos)
      - [Initiations](#{base}/initiations): Free beginner sessions (never paid online)
      - [Memberships](#{base}/memberships): Adult and child adhesions
      - [Contact](#{base}/contact): Contact form
      - [FAQ](#{base}/faq): Frequently asked questions

      ## Legal

      - [Legal notice](#{base}/mentions-legales)
      - [Privacy / RGPD](#{base}/politique-confidentialite)
      - [Terms of sale (CGV)](#{base}/cgv)
      - [Terms of use (CGU)](#{base}/cgu)

      ## Machine-readable

      - [Sitemap](#{base}/sitemap.xml): Index of public URLs
      - [Robots](#{base}/robots.txt): Crawl rules
    LLMS
  end

  def sitemap_entries
    entries = []

    add_static_pages!(entries)
    add_products!(entries)
    add_events!(entries)
    add_initiations!(entries)

    entries
  end

  def add_static_pages!(entries)
    static = [
      [ root_path, "1.0", "daily" ],
      [ about_path, "0.8", "monthly" ],
      [ shop_path, "0.9", "weekly" ],
      [ events_path, "0.9", "daily" ],
      [ initiations_path, "0.8", "weekly" ],
      [ memberships_path, "0.8", "weekly" ],
      [ contact_path, "0.6", "monthly" ],
      [ faq_path, "0.6", "monthly" ],
      [ mentions_legales_path, "0.3", "yearly" ],
      [ politique_confidentialite_path, "0.3", "yearly" ],
      [ cgv_path, "0.3", "yearly" ],
      [ cgu_path, "0.3", "yearly" ]
    ]

    static.each do |path, priority, changefreq|
      entries << entry(path, priority: priority, changefreq: changefreq)
    end
  end

  def add_products!(entries)
    Product.active.find_each do |product|
      entries << entry(
        product_path(product.slug),
        lastmod: product.updated_at,
        priority: "0.7",
        changefreq: "weekly"
      )
    end
  end

  def add_events!(entries)
    Event.not_initiations.visible.find_each do |event|
      entries << entry(
        event_path(event),
        lastmod: event.updated_at,
        priority: "0.7",
        changefreq: "weekly"
      )
    end
  end

  def add_initiations!(entries)
    Event::Initiation.visible.find_each do |initiation|
      entries << entry(
        initiation_path(initiation),
        lastmod: initiation.updated_at,
        priority: "0.6",
        changefreq: "weekly"
      )
    end
  end

  def entry(path, lastmod: nil, priority: "0.5", changefreq: "weekly")
    {
      loc: "#{request.base_url}#{path}",
      lastmod: lastmod&.utc&.iso8601,
      changefreq: changefreq,
      priority: priority
    }
  end
end
