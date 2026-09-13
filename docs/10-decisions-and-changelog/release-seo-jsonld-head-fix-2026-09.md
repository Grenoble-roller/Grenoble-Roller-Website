# Release Note: SEO JSON-LD head fix (v2.4.2)

**Date:** 2026-09-07  
**Branch:** `Dev` → `staging`  
**Severity:** P0 — public layout CSS/JS broken on every page using `seo_head`

## Summary

`SeoHelper#seo_json_ld` used `tag(:script, content: json)`, which puts JSON in a `content=` **attribute** and leaves `<script>` open. Browsers then treat the rest of `<head>` (stylesheet, importmap, modulepreload) as script text → unstyled site + `Failed to resolve module specifier "application"`.

Introduced in `92e0e2bf` (SEO helper), shipped to staging via PR #263.

## Changes

### Fixed
- JSON-LD emitted as `<script type="application/ld+json">{…}</script>` body via `content_tag`.
- `og:description` / `twitter:description` no longer empty (stop re-parsing meta HTML; use plain text helpers).

### Tests
- `spec/helpers/seo_helper_spec.rb` — script body vs `content=` attribute; non-empty OG description.
- `spec/requests/pages_spec.rb` — homepage keeps stylesheet + importmap outside JSON-LD script.

## Migrations / ENV

None.

## QA (staging)

- [ ] Hard refresh homepage: Bootstrap styles apply (dark theme), not browser defaults.
- [ ] DevTools → Network: `application.bootstrap-*.css` 200 and applied; no console importmap error.
- [ ] View source: `<script type="application/ld+json">{…}</script>` then stylesheet / importmap.
- [ ] `og:description` meta non-empty on `/`.

## Rollback

Redeploy previous staging image, or revert the merge commit of this release.

## Related

- Root cause commit: `92e0e2bf`
- CI unblock (unrelated): PR #264
- Changelog: [`CHANGELOG.md`](CHANGELOG.md) § `[2026-09-07]`
