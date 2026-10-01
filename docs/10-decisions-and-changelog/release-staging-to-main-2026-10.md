# Release staging → main (October 2026 production) — v2.4.14

**Target:** merge `staging` → `main` (production = https://grenoble-roller.org)  
**Staging head:** `5d0a0c3e` — Merge PR #292 from `Dev`  
**Main baseline:** `9d77bb55` — last production merge (#287)

**Human sign-off required** before merge (see AGENTS.md). Do **not** merge this PR without Florian approval.

**Staging validation:** https://staging.grenoble-roller.org  
**Related Dev→staging note:** [`release-dev-to-staging-2026-06.md`](release-dev-to-staging-2026-06.md) (current promotion v2.4.12–v2.4.14)  
**Changelog:** [`CHANGELOG.md`](CHANGELOG.md)

---

## What’s shipping

| Version | Summary | Patch note |
| --- | --- | --- |
| v2.4.12 | Association bureau/CA + initiations hours | [`release-association-governance-2026-10.md`](release-association-governance-2026-10.md) |
| v2.4.13 | Contact Discord webhook UI + embed F | [`release-contact-discord-webhook-2026-10.md`](release-contact-discord-webhook-2026-10.md) |
| v2.4.14 | Dual waitlist member/discovery | [`release-dual-waitlist-2026-10.md`](release-dual-waitlist-2026-10.md) |

## Migrations (run on production deploy)

| Migration | Notes |
| --- | --- |
| `20261001204047_add_purpose_to_notification_channels.rb` | Nullable unique `purpose` for contact Discord channel |
| `20261001214912_add_pool_to_waitlist_entries.rb` | `waitlist_entries.pool` default `member` |

## ENV

| Variable | Action |
| --- | --- |
| New required ENV | **none** |
| `ALLOW_DISCORD_NOTIFICATIONS` | Production always dispatches when channels enabled (DR-002); no change |

## Delta audit (main-only vs staging)

Main-only commits are prior `staging` → `main` merge SHAs plus README refresh `#259` (`70276f2f`). Staging did not touch `README.md`; a normal merge keeps main’s README. No unique application code on `main` missing from `staging`.

## QA before merge (production)

- [ ] Staging smoke: dual waitlist (member vs discovery notify) OK on staging
- [ ] Staging smoke: contact Discord modal / test (if enabled)
- [ ] Staging smoke: about / mentions légales bureau OK
- [ ] Migrations dry-run / backup plan ready on prod host
- [ ] Florian sign-off to merge

## Rollback

Redeploy previous `main` image. Reverse migrations only if a full feature rollback is required (`pool` column / `purpose` column).

## Discord CI announce

Payload: [`.github/release-discord.yml`](../../.github/release-discord.yml) — v2.4.14 (posts to production salon on merge to `main`).
