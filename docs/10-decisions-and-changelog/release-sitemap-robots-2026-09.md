# Release note — Sitemap + robots.txt (v2.4.6)

**Date:** 2026-09-07  
**Branch:** `feature/seo-sitemap-robots` → `Dev`  
**Scope:** Crawlability for SEO scanners (sitemap in robots + direct sitemap).

## Problem

External “analyse technique” tools flagged:

- ✗ Sitemap referenced from robots
- ✗ Sitemap direct (`/sitemap.xml` → 404)
- `public/robots.txt` was the empty Rails stub (no `Sitemap:` line)

Lighthouse SEO can still score 100 without these checks.

## Solution

| Path | Behavior |
|------|----------|
| `GET /robots.txt` | `SeoController#robots` — Allow public site, Disallow private areas, `Sitemap: {host}/sitemap.xml` |
| `GET /sitemap.xml` | `SeoController#sitemap` — urlset of public pages + `Product.active` + `Event`/`Initiation` `.visible` |

Host is taken from the request so staging and production each advertise their own sitemap URL.

## Migrations / ENV

None.

## QA

- [ ] `curl -sI https://staging…/robots.txt` → 200, `text/plain`
- [ ] Body contains `Sitemap: https://staging…/sitemap.xml`
- [ ] `curl -s https://staging…/sitemap.xml` → 200, `urlset`, includes `/`, `/shop`, `/events`
- [ ] Draft events / inactive products absent from sitemap
- [ ] `bundle exec rspec spec/requests/seo_spec.rb`
