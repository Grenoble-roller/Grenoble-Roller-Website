# Release Note: Perf bundle Dev → staging (v2.4.3–2.4.5)

**Date:** 2026-09-07  
**Promotion:** `Dev` → `staging`  
**Range:** `a36b4e3e` … `257dbd76`  
**Migrations / ENV:** none  

## Summary

Performance slice after the SEO JSON-LD hotfix (v2.4.2, already on staging via #266):

| Version | Change |
|---------|--------|
| **2.4.3** | PurgeCSS write-back — public CSS ~**344 KiB** (was ~1.8 MiB) |
| **2.4.4** | Navbar logos 200×80 + dims; custom hero AS ≤1280×720 WebP |
| **2.4.5** | Event/initiation cards use square 800×450; past-list thumbs 400×225 |

Traefik Brotli/gzip was already enabled; this release shrinks **parse weight** and image payloads.

## PRs merged on Dev

- #267 — PurgeCSS  
- #268 — Navbar logos + hero variant  
- #269 — Card / list cover variants  

## QA (staging)

- [ ] Hard-refresh `/` — Bootstrap styled; CSS asset ≪ 1.8 MiB (expect ~300–400 KiB uncompressed)
- [ ] Navbar logos sharp (light/dark); Network shows `*_nav.png` (~8–32 KiB)
- [ ] `/events`, `/initiations`, homepage cards — images OK; covers via square/thumb variants
- [ ] Event/initiation **show** hero still full banner
- [ ] Discord announce posts **v2.4.5** payload on merge to staging

## Rollback

Redeploy previous staging image / revert merge to `a36b4e3e`.

## Docs

- [`CHANGELOG.md`](CHANGELOG.md) §§ 2026-09-07 (v2.4.3–2.4.5)
- [`release-purgecss-2026-09.md`](release-purgecss-2026-09.md)
- Discord: [`.github/release-discord.yml`](../../.github/release-discord.yml)
