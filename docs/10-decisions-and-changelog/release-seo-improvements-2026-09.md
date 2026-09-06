# Release Note: SEO/GEO Improvements & Lazy Loading (v2.4.0)

**Date:** 2026-09-05  
**Branch:** `Dev` → Target: `staging`  
**Related PR:** (to be created)  

## Summary
This release focuses on improving search engine optimization (SEO), generative engine optimization (GEO), and front-end performance via lazy-loading of images. All changes are backward‑compatible and do not modify existing business logic.

## Changes

### SEO Helper (`app/helpers/seo_helper.rb`)
- New helper that dynamically builds:
  - `<title>` (with `content_for` override, fallback to site name).
  - `<meta name="description">` (with `content_for` override, ≤160 chars).
  - `<link rel="canonical">` (based on current URL).
  - Open Graph tags (`og:title`, `og:description`, `og:image`, `og:url`, `og:type`).
  - Twitter Card tags (`twitter:card`, `twitter:site`, `twitter:creator`, `twitter:title`, `twitter:description`, `twitter:image`).
  - JSON‑LD structured data:
    * Base `@type Organization` (logo, URL, founding date, address, socials, contactPoint, sport, memberOf).
    * Optional `@type Event` injected via `content_for :event` on event show pages.
- Exposes a single method `seo_head` returning the concatenated tags, to be placed in `<head>`.

### Layout Integration (`app/views/layouts/application.html.erb`)
- Replaced static `<title>` and `<meta name="description">` with `<%= seo_head %>`.

### SEO/GEO Content Improvements
- **Homepage FAQ** (`app/views/pages/index.html.erb`): added an accordion with three Q&R items (Comment adhérer ?, Quels sont les tarifs ?, Puis-je essayer avant de m’inscrire ?) to target featured snippets.
- **Descriptive anchor text**: replaced all occurrences of non‑descriptive links like “cliquez ici” with meaningful labels in:
  - `app/views/admin_panel/products/_image_upload.html.erb`
  - `app/views/devise/confirmations/confirmed.html.erb`
  - `app/views/event_mailer/waitlist_spot_available.text.erb`
  - `app/views/memberships/_health_questionnaire.html.erb`
  - `app/views/pages/welcome.html.erb`
- **Heading hierarchy**: corrected the hero banner (`app/views/pages/_hero.html.erb`) so the main title is a proper `<h1>` (was wrapped in a `<div>`), ensuring a single H1 per page and correct downstream H2/H3 usage.

### Event Structured Data & OG Image (`app/views/events/show.html.erb`)
- Added `content_for` entries consumed by the SEO helper:
  - `:og_image` (event cover image, resized).
  - `:event`, `:event_name`, `:event_start_date`, `:event_end_date`, `:event_location_name`, `:event_location_address`, `:event_ticket_url`, `:event_price`.
- These allow the helper to render accurate Open Graph metadata and JSON‑LD `@type Event` nodes.

### Performance – Lazy Loading (`app/helpers/media_helper.rb`)
- Existing helper `lazy_image_tag` adds `loading="lazy"` by default (wrapper around `image_tag`).
- **Extended to all images**: every `image_tag` call in view files (excluding admin panel, but applied there as well for consistency) has been replaced with `lazy_image_tag`.
  - Exceptions where eager loading is required (e.g., LCP‑critical images) retain explicit options (`loading: "eager"`, `fetchpriority: "high"`). Example: the main history image on `/about`.
- Added a CSS skeleton placeholder via the `lazy-skeleton` class (added automatically by the helper) for a smoother loading experience (pulsing animation).
- Added a fade‑in transition (`opacity` + `transition`) when the image finishes loading (class `lazy-loaded`).
- Result: all non‑critical images now load lazily with a visual placeholder that fades in, improving LCP and reducing initial payload.

## Files Modified

### Code
- `app/helpers/seo_helper.rb` *(new)*
- `app/views/layouts/application.html.erb`
- `app/views/pages/index.html.erb` *(FAQ)*
- `app/views/pages/_hero.html.erb` *(heading fix)*
- `app/views/events/show.html.erb` *(OG/JSON‑LD)*
- `app/views/admin_panel/products/_image_upload.html.erb`
- `app/views/devise/confirmations/confirmed.html.erb`
- `app/views/event_mailer/waitlist_spot_available.text.erb`
- `app/views/memberships/_health_questionnaire.html.erb`
- `app/views/pages/welcome.html.erb`
- `app/helpers/media_helper.rb` *(unchanged, usage extended)*
- 17 view files (pages, events, initiations, products, carts, layouts, etc.) – batch replace `image_tag` → `lazy_image_tag`

### Documentation
- `docs/10-decisions-and-changelog/CHANGELOG.md` – added v2.4.0 entry
- `docs/10-decisions-and-changelog/release-seo-improvements-2026-09.md` *(this file)*

## Testing Checklist (for staging)
- [ ] Verify source code of homepage contains dynamic `<title>` and `<meta name="description">` matching the helper output.
- [ ] Confirm OG tags (`og:title`, `og:description`, `og:image`) appear on an event page (`/events/:id`).
- [ ] Validate JSON‑LD script contains both Organization and Event nodes (use Google Rich Results Test).
- [ ] Ensure no regression in existing Stimulus/Turbo behavior (click events, navigation).
- [ ] Confirm lazy-loading attribute (`loading="lazy"`) present on `<img>` tags in HTML (except where overridden).
- [ ] Run Lighthouse on staging to confirm performance improvement (especially LCP and SEO score).
- [ ] Run the test suite: `bundle exec rspec` (should pass).

## Rollback Procedure
If needed, revert the commit `3dc78faa` (lazy‑loading extension) and prior SEO commits:
- `git revert <commit‑sha>` for each of the commits in this feature chain, or redeploy the previous stable image (see `release-dev-to-staging-2026-06.md`).

## References
- Original SEO audit: `docs/09-product/seo-audit.md`
- Shape‑up sprint plan: `docs/02-shape-up/sprint-plan-seo-improvements.md`