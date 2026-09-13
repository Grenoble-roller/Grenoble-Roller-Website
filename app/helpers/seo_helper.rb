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
  DEFAULT_TITLE = "Grenoble Roller – Official site"
  DEFAULT_DESCRIPTION =
    "Boutique en ligne, événements roller, adhésions HelloAsso pour le club de roller de Grenoble."

  # Returns a <title> tag with content between 30 and 60 characters.
  # Uses content_for :title if set, otherwise a default.
  def seo_title
    content_tag(:title, seo_title_text)
  end

  # Returns a meta description tag (max 160 characters).
  def seo_description
    tag(:meta, name: "description", content: seo_description_text)
  end

  # Returns a canonical link tag.
  def seo_canonical
    url = request.original_url
    tag(:link, rel: "canonical", href: url)
  end

  # Returns Open Graph meta tags.
  def seo_og_tags
    og_image = content_for?(:og_image) ? content_for(:og_image) : image_url("logo/logo_grenobleroller_color.png")

    safe_join [
      tag(:meta, property: "og:title", content: seo_og_title_text),
      tag(:meta, property: "og:description", content: seo_og_description_text),
      tag(:meta, property: "og:image", content: og_image),
      tag(:meta, property: "og:url", content: request.original_url),
      tag(:meta, property: "og:type", content: "website")
    ], "\n"
  end

  # Returns Twitter Card meta tags.
  def seo_twitter_card
    og_image = content_for?(:og_image) ? content_for(:og_image) : image_url("logo/logo_grenobleroller_color.png")

    safe_join [
      tag(:meta, name: "twitter:card", content: "summary_large_image"),
      tag(:meta, name: "twitter:site", content: "@grenobleroller"),
      tag(:meta, name: "twitter:creator", content: "@grenobleroller"),
      tag(:meta, name: "twitter:title", content: seo_og_title_text),
      tag(:meta, name: "twitter:description", content: seo_og_description_text),
      tag(:meta, name: "twitter:image", content: og_image)
    ], "\n"
  end

  # Returns JSON-LD structured data.
  # Base Organization schema; if view provides event details via content_for,
  # an Event node is added to @graph.
  #
  # IMPORTANT: JSON must be the *body* of <script>, not a content= attribute.
  # `tag(:script, content: …)` puts JSON in an attribute and leaves the tag open,
  # so the browser treats the rest of <head> (CSS, importmap) as script text.
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

    # Escape </ to avoid prematurely closing the script element in HTML parsers.
    json = org.to_json.gsub("</", '<\/')
    content_tag(:script, json.html_safe, type: "application/ld+json")
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

  private

  def seo_title_text
    title = content_for?(:title) ? content_for(:title) : DEFAULT_TITLE
    title = title.truncate(60, omission: "") if title.length > 60
    title = title.ljust(30, " – ") if title.length < 30
    title
  end

  def seo_description_text
    desc = content_for?(:description) ? content_for(:description) : DEFAULT_DESCRIPTION
    desc.truncate(160, separator: " ", omission: "…")
  end

  def seo_og_title_text
    content_for?(:og_title) ? content_for(:og_title) : seo_title_text
  end

  def seo_og_description_text
    content_for?(:og_description) ? content_for(:og_description) : seo_description_text
  end
end
