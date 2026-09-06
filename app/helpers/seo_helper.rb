# == Schema Information
#
# Helper for generating SEO-related meta tags and structured data.
# All comments are in English as required; only user-facing strings may stay in French.
#
# Usage in layouts:
#   <%= seo_head %>
#
# In views you can override defaults with content_for:
#   <% provide(:title, "Custom title") %>
#   <% provide(:description, "Custom description") %>
#   <% provide(:og_image, url_for("logo.png")) %>
#   <% provide(:event_name, @event.name) %>
#   <% provide(:event_start_date, @event.starts_at.iso8601) %>
#   etc.

module SeoHelper
  # Returns a <title> tag with content between 30 and 60 characters.
  # Uses content_for :title if set, otherwise a default.
  def seo_title
    title = content_for?(:title) ? content_for(:title) : "Grenoble Roller – Official site"
    # Ensure length between 30 and 60 characters
    title = title.truncate(60, omission: "") if title.length > 60
    title = title.ljust(30, " – ") if title.length < 30
    content_tag(:title, title)
  end

  # Returns a meta description tag (max 160 characters).
  def seo_description
    desc = content_for?(:description) ? content_for(:description) :
           "Boutique en ligne, événements roller, adhésions HelloAsso pour le club de roller de Grenoble."
    desc = desc.truncate(160, separator: " ", omission: "…")
    tag(:meta, name: "description", content: desc)
  end

  # Returns a canonical link tag.
  def seo_canonical
    url = request.original_url
    tag(:link, rel: "canonical", href: url)
  end

  # Returns Open Graph meta tags.
  def seo_og_tags
    og_title   = content_for?(:og_title)   ? content_for(:og_title)   : seo_title.gsub(/<\/?title>/, "").strip
    og_desc    = content_for?(:og_description) ? content_for(:og_description) : seo_description.gsub(/<\/?meta[^>]*>/, "").strip
    og_image   = content_for?(:og_image)   ? content_for(:og_image)   : image_url("logo/logo_grenobleroller_color.png")
    og_url     = request.original_url
    og_type    = "website"

    safe_join [
      tag(:meta, property: "og:title",       content: og_title),
      tag(:meta, property: "og:description", content: og_desc),
      tag(:meta, property: "og:image",       content: og_image),
      tag(:meta, property: "og:url",         content: og_url),
      tag(:meta, property: "og:type",        content: og_type)
    ], "\n"
  end

  # Returns Twitter Card meta tags.
  def seo_twitter_card
    safe_join [
      tag(:meta, name: "twitter:card", content: "summary_large_image"),
      tag(:meta, name: "twitter:site", content: "@grenobleroller"),
      tag(:meta, name: "twitter:creator", content: "@grenobleroller"),
      tag(:meta, name: "twitter:title", content: seo_title.gsub(/<\/?title>/, "").strip),
      tag(:meta, name: "twitter:description", content: seo_description.gsub(/<\/?meta[^>]*>/, "").strip),
      tag(:meta, name: "twitter:image", content: content_for?(:og_image) ? content_for(:og_image) : image_url("logo/logo_grenobleroller_color.png"))
    ], "\n"
  end

  # Returns JSON-LD structured data.
  # Base Organization schema; if view provides event details via content_for,
  # an Event node is added to @graph.
  def seo_json_ld
    org = {
      "@context": "https://schema.org",
      "@type": "Organization",
      "name": "Grenoble Roller",
      "url": root_url,
      "logo": image_url("logo/logo_grenobleroller_color.png"),
      "sameAs": [
        "https://www.facebook.com/GrenobleRoller",
        "https://www.instagram.com/grenobleroller/",
        "https://twitter.com/grenobleroller"
      ],
      "contactPoint": [ {
        "@type": "ContactPoint",
        "telephone": "+33-4-XX-XX-XX-XX",
        "contactType": "Customer service",
        "areaServed": "FR"
      } ]
    }

    if content_for?(:event)
      event = {
        "@type": "Event",
        "name": content_for(:event_name),
        "startDate": content_for(:event_start_date),
        "endDate": content_for(:event_end_date),
        "location": {
          "@type": "Place",
          "name": content_for(:event_location_name),
          "address": content_for(:event_location_address)
        },
        "offers": {
          "@type": "Offer",
          "url": content_for(:event_ticket_url),
          "price": content_for(:event_price),
          "priceCurrency": "EUR",
          "availability": "https://schema.org/InStock"
        }
      }
      org = { "@context": "https://schema.org", "@graph": [ org, event ] }
    end

    tag(:script, type: "application/ld+json", content: org.to_json)
  end

  # Convenience method to output all SEO tags at once.
  def seo_head
    safe_join [
      seo_title,
      seo_description,
      seo_canonical,
      seo_og_tags,
      seo_twitter_card,
      seo_json_ld
    ], "\n"
  end
end
