# Release Note: PurgeCSS write-back + tighter safelist (v2.4.3)

**Date:** 2026-09-07  
**Branch:** `Dev` → (staging when promoted)  
**Related:** Lighthouse unused-CSS / render-blocking CSS

## Summary

`npm run build:css:purge` called the PurgeCSS CLI with `--config` only; results were never written back, so deploys kept the full ~1.8 MiB Bootstrap bundle. Fixed write-back via `scripts/purge-css.mjs`, tightened the safelist (no more `/^btn-/`, `/^bg-/`, `/^text-/` …), and scan Pagy gem templates for pagination classes.

## Results (local build)

| Metric | Before | After |
|--------|--------|-------|
| `application.bootstrap.css` | ~1 788 KiB | **~344 KiB** (~−81 %) |
| gzip (estimate) | ~301 KiB | ~58 KiB |

Lighthouse may still report “unused CSS” on a single page (~295 KiB of the shared bundle) — expected for a site-wide stylesheet; further cuts need modular Sass / critical CSS, not more Traefik compression.

## Migrations / ENV

None. CSS is rebuilt on deploy (`npm run build:css`).

## QA

- [ ] Homepage / events / shop / admin: layout intact after hard refresh
- [ ] Pagination (Pagy) styled
- [ ] Modals / offcanvas / PhotoSwipe still work
- [ ] Served CSS digest ~300–400 KiB uncompressed (not ~1.8 MiB)

## Rollback

Redeploy previous image / revert this commit; rebuild CSS.
