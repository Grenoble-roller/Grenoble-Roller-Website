---
title: "Release Dev → staging (June 2026)"
status: "active"
version: "2.4.5"
created: "2026-06-07"
updated: "2026-09-07"
tags: ["release", "staging", "changelog", "unified-checkout", "discord-notifications", "admin-panel", "memberships", "events", "ux", "seo", "perf"]
---

# Release Dev → staging (June 2026)

> **Current slice (2026-09-07) — perf v2.4.3 → v2.4.5**  
> **Range:** `a36b4e3e` (`origin/staging`) … `257dbd76` (`Dev`) — 6 commits  
> **Patch note:** [`release-perf-bundle-staging-2026-09.md`](release-perf-bundle-staging-2026-09.md)  
> **Migrations:** none · **ENV:** none · rebuild CSS on deploy (`npm run build:css`)  
> **Discord:** `.github/release-discord.yml` → **2.4.5**  
> Includes: PurgeCSS write-back (~344 KiB CSS), navbar nav logos, hero AS 1280×720, card/list cover variants.  
> SEO JSON-LD hotfix **v2.4.2** already on staging (#266).

> **v2.4.3 (2026-09-07) — PurgeCSS write-back**  
> Public CSS ~**344 KiB** (was ~1.8 MiB): purge now writes output; tighter safelist.  
> **Patch note:** [`release-purgecss-2026-09.md`](release-purgecss-2026-09.md)

> **v2.4.2 hotfix (2026-09-07)** — SEO JSON-LD head fix (already on staging via #266).  
> **Patch note:** [`release-seo-jsonld-head-fix-2026-09.md`](release-seo-jsonld-head-fix-2026-09.md)

**Target branch:** merge `Dev` → `staging` (PR)  
**Commit range (this promo):** `a36b4e3e` … `257dbd76`  
**Head on Dev:** `257dbd76` — merge #269 card image variants

**Agent SSOT for checkout epic:** [`PLAN-unified-checkout-MASTER.md`](PLAN-unified-checkout-MASTER.md) (Waves 0–6 complete on `Dev`).  
**Agent SSOT for Discord notifications:** [`DR-002-discord-webhook-notifications.md`](DR-002-discord-webhook-notifications.md) (implemented 2026-06-09).

> **v2.3 addendum (2026-07-03):** legacy session cart and `UNIFIED_CART_ENABLED` flag **removed** on `Dev`. Unified cart is permanent. Rollback = redeploy previous release (no ENV toggle). See [`CHANGELOG.md`](CHANGELOG.md) § `[2026-07-03]`.

> **v2.3.1 addendum (2026-08-02):** membership renewal email / login return / early August sale window. Next-season sales open **1 August** (was 15). No migrations, no new ENV. See [`CHANGELOG.md`](CHANGELOG.md) § `[2026-08-02]`.

> **v2.3.1 addendum (2026-08-02 b):** event cover + loop map image viewer — mobile opens native image tab; desktop lightbox. Works for N loops. See [`CHANGELOG.md`](CHANGELOG.md) § event image viewer.

> **v2.3.1 addendum (2026-08-03):** organizers see their own `draft` events/initiations on public index (no more `.visible` wipe after `policy_scope`). No migrations, no new ENV. See [`CHANGELOG.md`](CHANGELOG.md) § `[2026-08-03]`.

> **v2.3.2 addendum (2026-08-03):** UX memberships + shop catalog shelf (`ux/pages-verification` → `Dev`). Adult **Réadhérer**, square listing thumbs, clickable product cards. Full patch note: [`release-ux-pages-verification-2026-08.md`](release-ux-pages-verification-2026-08.md).
### v2.3.1 slice — commits (`staging`…`Dev`)

| Commit | Summary |
|--------|---------|
| `9bc3ec70` | Membership renewal email → login return; next-season sales open **1 August** |
| `28f55175` | Event cover + loop maps: native image tab on mobile, lightbox on desktop |
| `0f16a913` | Organizers see own draft events (and initiations) on index |

**Migrations:** none  
**ENV:** none  
**Rollback:** redeploy previous staging image / revert merge to `2201eefa`

---

## Summary / scope

This release bundles:

1. **Discord webhook notifications (DR-002 — new in v2.2)** — SUPERADMIN-configured Discord channels, ~65 event toggles, HelloAsso + admin + public hooks, QA sample embeds, staging gate via `ALLOW_DISCORD_NOTIFICATIONS`.
2. **Unified account cart + checkout (major)** — feature-flagged via `UNIFIED_CART_ENABLED`; shop, memberships, and paid events share one cart and one HelloAsso checkout with **partial payment** (per-line checkboxes) and **optional donation** on every checkout. Initiations remain free; cash/check memberships bypass the cart.
3. **June 2026 public/admin batch** — events lifecycle/UI, admin panel (organizers, goodies, mail logs, carousel), Umami analytics, Turnstile on contact, roller stock reservations (v2.3), homepage hero image, dev tooling (mise, dotenv).
4. **Post-checkout hardening (June 8)** — membership sale-season gate, admin panel mobile-first UX, collapsed sidebar rail fix, dependency security patches, full RSpec green on `Dev`.
5. **Admin layout polish (v2.2.1 — June 30)** — offcanvas sidebar outside flex container, compact dashboard KPI cards, public navbar mobile band fix, navbar height sync on Turbo navigation.

**Rollback (checkout):** set `UNIFIED_CART_ENABLED=false` and redeploy — see [Rollback](#rollback) and MASTER plan §H.  
**Rollback (Discord):** disable channels in admin or unset `ALLOW_DISCORD_NOTIFICATIONS` on staging — no data loss; deliveries stop immediately.

---

## Discord webhook notifications (DR-002 — v2.2)

| Area | Change |
| --- | --- |
| Admin UI | `/admin-panel/notification-channels` — CRUD, grouped event checkboxes, test webhook, QA sample (single + all) |
| Access | SUPERADMIN only (level ≥ 70); sidebar **Notifications** after **Logs Mails** |
| Catalog | ~65 keys in `NotificationEventRegistry` (contact, organizer, payments, admin CRUD, maintenance, etc.) |
| Defaults | New webhooks: `contact_message.received` + `organizer_application.submitted` **on**; `payment.failed` **off** |
| Dispatch | `NotificationDispatchService` → `DiscordWebhookDeliveryJob` (Solid Queue); audit in `notification_deliveries` |
| Payment trigger | After HelloAsso confirmation in `HelloassoService` — not bare ActiveRecord callbacks |
| Staging gate | Dispatch no-op unless `Rails.env.production?` **or** `ALLOW_DISCORD_NOTIFICATIONS=true` |

**Canonical doc:** [`DR-002-discord-webhook-notifications.md`](DR-002-discord-webhook-notifications.md)

### DR-002 migrations (new)

| Migration | Purpose |
| --- | --- |
| `20260609120000_create_notification_tables` | `notification_channels`, `notification_subscriptions`, `notification_deliveries` |

Run via `DB_BOOT_TASK=prepare` on deploy (Dokploy default).

### DR-002 environment variables

| Variable | Staging | Production |
| --- | --- | --- |
| `ALLOW_DISCORD_NOTIFICATIONS` | **`true`** only when QA/testing Discord (optional) | Not required — production dispatches when channels enabled |
| `SOLID_QUEUE_IN_PUMA` | **`true`** recommended for async delivery + batch QA samples | Same if using in-Puma Solid Queue |

Template: `.env.example` (commented `ALLOW_DISCORD_NOTIFICATIONS`).

### DR-002 — post-deploy (staging)

1. Run migrations (automatic if `prepare`).
2. Superadmin → **Notifications** → create channel with Discord webhook URL.
3. Enable desired event toggles; use **Tester** to verify embed.
4. Optional QA: **Envoyer un exemple** / batch samples (watch Discord rate limits).
5. Set `ALLOW_DISCORD_NOTIFICATIONS=true` only when staging should receive real dispatches.

### DR-002 — automated tests

```bash
bundle exec rspec spec/models/notification_channel_spec.rb \
  spec/models/notification_subscription_spec.rb \
  spec/models/notification_delivery_spec.rb \
  spec/services/notification_event_registry_spec.rb \
  spec/services/notification_dispatch_service_spec.rb \
  spec/services/discord_webhook_client_spec.rb \
  spec/services/notification_channel_sample_service_spec.rb \
  spec/services/helloasso_service_discord_spec.rb \
  spec/jobs/discord_webhook_delivery_job_spec.rb \
  spec/requests/admin_panel/notification_channels_spec.rb
```

### DR-002 — known gaps

- `organizer_application.submitted` — no public submit controller on `Dev` yet (toggle exists).
- `event.cancelled` — no dedicated admin cancel action wired yet.

---

## Unified checkout (epic — merged on `Dev`)

| Area | Change |
| --- | --- |
| Account cart | `CartLine` model — product, membership, event line types per user |
| Checkout | `Checkout` + `CheckoutLine`; partial line selection; donation block |
| HelloAsso | Single unified payload via `CheckoutService` / `CheckoutFulfillmentService` |
| Paid events | Registration → cart hold (15 min) → pay; waitlist blocked when payment required |
| Memberships | Add-to-cart per adhesion (alert block on index); no grouped HelloAsso when flag on |
| Feature flag | `UnifiedCart.enabled?` — `ENV["UNIFIED_CART_ENABLED"]` (default `false`) |
| Admin | Read-only `/admin-panel/checkouts` audit |
| UX | Navbar cart badge, Mes sorties pending banner, mobile sticky cart/checkout footers |

**Canonical docs:**

- [`DR-001-unified-checkout-cart.md`](DR-001-unified-checkout-cart.md)
- [`PLAN-unified-checkout-MASTER.md`](PLAN-unified-checkout-MASTER.md) — QA §G, rollback §H
- [`docs/09-product/unified-cart-ux.md`](../09-product/unified-cart-ux.md)
- [`docs/09-product/flux-boutique-helloasso.md`](../09-product/flux-boutique-helloasso.md) (updated flow)

### Checkout migrations (new)

| Migration | Purpose |
| --- | --- |
| `20260607130200_add_payment_fields_to_events_and_attendances` | Paid event fields, attendance payment expiry |
| `20260607205837_create_cart_lines` | Account cart lines |
| `20260608120000_create_checkouts` | Checkout sessions + checkout lines |

Run via `DB_BOOT_TASK=prepare` on deploy (Dokploy default).

### Checkout environment variables

| Variable | Staging | Production (initial) |
| --- | --- | --- |
| `UNIFIED_CART_ENABLED` | **`true`** (QA) | **`false`** until human sign-off after staging QA |

Template: [`ops/dokploy/env/staging.env.example`](../../ops/dokploy/env/staging.env.example).

### Checkout — post-deploy (staging)

1. Set `UNIFIED_CART_ENABLED=true` in Dokploy staging env; redeploy.
2. Run migrations (automatic if `prepare`).
3. Execute **QA manual checklist** below (MASTER §G).
4. HelloAsso **sandbox** credentials must be active for E2E payment tests.
5. Do **not** enable flag in production until Florian signs off staging QA.

### Checkout — automated tests (green on `Dev`)

```bash
bundle exec rspec spec/models/cart_line_spec.rb spec/models/checkout_spec.rb \
  spec/services/cart_line_service_spec.rb spec/services/checkout_service_spec.rb \
  spec/services/checkout_fulfillment_service_spec.rb spec/requests/carts_spec.rb \
  spec/requests/checkouts_spec.rb spec/requests/memberships/payments_spec.rb \
  spec/lib/unified_cart_spec.rb
```

---

## Features by domain (June batch — prior commits)

### Events

| Change | Description |
| --- | --- |
| Past/upcoming lifecycle | Events classified as past when **end time** has passed; **ongoing** badge while in progress |
| Multi-loop UI | Overlay loop cards; per-loop distance labels; compact practical info grid |
| Route map viewer | Fullscreen pinch-zoom viewer on route/loop map images |
| Event organizers | `EventOrganizer` model; optional `organizer_id`; admin CRUD + public display |
| Registration emails | Participant name (parent or child) in confirmation emails |
| Paid registration | Wave 2: paid randos → cart + timer (with unified checkout epic) |

### Admin panel

| Change | Description |
| --- | --- |
| Events read access | Level ≥ 40 can **view** randos; write ≥ 60 |
| Event organizers | CRUD at `/admin-panel/event-organizers` |
| Goodies distribution | `memberships.goodies_distributed` flag |
| Mail logs | `OutboundEmailLog` + admin mail-logs panel |
| Homepage carousel | Autoplay on/off and interval (2–30 s) |
| Homepage hero | Admin-customizable hero banner image |
| Checkouts audit | `/admin-panel/checkouts` (read-only, unified checkout) |
| Role guards | Prevent admins from editing/deleting super admins |

### Memberships

- Goodies distributed flag.
- Unified cart: per-child « Ajouter au panier » in pending alert; compact mini-cards (WCAG `aria-label` on icon actions).
- **Sale season gate (June 8):** before **15 August**, cart and membership flows use the **running** season (e.g. 2025–2026 in June 2026); next season opens 15 Aug–31 Aug; from 1 Sep the new running season applies. `Membership#align_to_sale_season!` + specs.

### Admin panel — mobile-first UX (June 8)

| Change | Description |
| --- | --- |
| Mobile chrome | Sticky bar « Menu admin » + « Site » on small screens |
| Page headers | Shared `admin-page-header` — title and actions stack on mobile |
| Tables | Card layout up to **991px**; auto `data-label` from `<th>` on Turbo load |
| Breadcrumbs | Compact/truncated mobile breadcrumb |
| Scope tabs | Horizontal scroll tabs on memberships index |
| Layout | Site navbar toggler and admin footer hidden on mobile in admin panel |
| **Collapsed sidebar rail** | Icon rail 48×48 centered; white ring on active item (no left accent bar); `--admin-sidebar-spacing` scoped to expanded mode only; Stimulus fixes for `.admin-menu-label` / `.admin-menu-chevron`; rail vertical spacing (`0.5rem` gap, `1rem` nav padding) |
| **Offcanvas outside flex (v2.2.1)** | `_offcanvas_sidebar.html.erb` rendered after `.admin-container` in `layouts/admin.html.erb` — fixes empty gap / layout hole on mobile |
| **Dashboard KPI cards (v2.2.1)** | `_stat_card.html.erb` partial; `.admin-dashboard-kpis` compact grid (2 columns mobile, `fit-content` cards desktop) |
| **Navbar height sync (v2.2.1)** | `syncAdminNavbarHeight` on `DOMContentLoaded`, `turbo:load`, `resize`; `getBoundingClientRect` (collapsed menu must not inflate `--navbar-height`) |
| **Public navbar mobile (v2.2.1)** | Collapsed `.navbar-collapse` hidden with zero height — no empty band when burger is closed |

**Dev note:** after `assets:precompile`, run `bin/rails assets:clobber && npm run build:css` locally so Propshaft does not serve stale `public/assets/application.bootstrap-*.css`.

### Security & dependencies (June 8)

| Package | Change |
| --- | --- |
| Rails | **8.1.3** |
| Puma | **7.2.1** (`~> 7.2`) |
| Gems | Transitive security patches via `bundle update` |
| npm | Partial `npm audit fix` on dev deps |
| Dev | `bundler-audit` added to Gemfile |

### Tests (June 8)

- Full suite green on `Dev`: **1462 examples, 0 failures** (`72cfaa11`).
- Fixes: French i18n event validation message, admin dashboard access level 40, legacy session cart specs with `with_unified_cart_disabled`, event attendance Capybara selector, `ActiveJob` test adapter in `rails_helper`.

### i18n (June 8)

- French validation messages for event creation form (`b5ef5336`).

### Homepage

- Configurable carousel; customizable hero image.

### Analytics & security

- **Umami** — consent-gated tracking (`UMAMI_*`).
- **Turnstile** on contact form (`TURNSTILE_*` ENV or credentials).

### Dev tooling

- mise + Ruby 3.4.2, `.env.example`, Dependabot → `Dev`.
- `AGENTS.md` agent guide (replaces `CLAUDE.md`; formerly `AGENT.md`).

### Roller stock reservations (v2.3)

- Physical stock vs active reservations model; « Clôturer les prêts terminés »; `ReturnRollerStockJob` enabled.

---

## Database migrations (full list for this release)

| Migration | Purpose |
| --- | --- |
| `20260607021500_create_outbound_email_logs` | Outbound email metadata for admin |
| `20260607025621_create_event_organizers` | Organizer entities |
| `20260607025623_add_organizer_to_events` | Optional `events.organizer_id` |
| `20260607094750_add_goodies_distributed_to_memberships` | Goodies flag |
| `20260607120000_create_homepage_carousel_settings` | Carousel autoplay settings |
| `20260607130200_add_payment_fields_to_events_and_attendances` | Paid events (checkout epic) |
| `20260607205837_create_cart_lines` | Account cart |
| `20260608120000_create_checkouts` | Unified checkout sessions |
| `20260609120000_create_notification_tables` | Discord notification channels, subscriptions, deliveries (DR-002) |

**No migration** for roller stock reservations (logic-only). `stock_returned_at` on events unchanged.

---

## Environment variables (new/changed)

| Variable | Required | Notes |
| --- | --- | --- |
| `UNIFIED_CART_ENABLED` | No | `true` on staging for QA; **`false` in prod** until sign-off |
| `UMAMI_SCRIPT_URL` | No | Umami tracker URL |
| `UMAMI_WEBSITE_ID` | No | Both Umami vars required for tracking |
| `UMAMI_SHARE_URL` | No | Public stats link |
| `TURNSTILE_SITE_KEY` | No* | Contact form + login |
| `TURNSTILE_SECRET_KEY` | No* | Server-side verification |
| `ALLOW_DISCORD_NOTIFICATIONS` | No | **`true`** on staging only when Discord QA/dispatch desired; prod ignores (always allows when channels enabled) |

\* Turnstile falls back to Rails credentials if ENV unset.

**Templates:** `.env.example`, `ops/dokploy/env/staging.env.example`, `ops/dokploy/env/production.env.example`.

---

## Post-deploy actions

### Unified checkout (staging — required)

1. Confirm `UNIFIED_CART_ENABLED=true` in Dokploy staging.
2. Complete QA checklist (section below).
3. Verify HelloAsso sandbox return URLs and webhook/polling still work for mixed carts.

### Roller stock (if not done on prior deploy)

1. Admin Panel → Stock Rollers — reconcile physical quantities.
2. « Clôturer les prêts terminés » for finished initiations.

### Optional

- Configure `UMAMI_*` on staging for analytics validation.
- Confirm Turnstile on `/contact`.

### Discord notifications (DR-002 — if enabled on staging)

1. Superadmin → `/admin-panel/notification-channels` — create channel, paste webhook URL.
2. Verify **Tester** sends embed to Discord.
3. Toggle a subset of events; trigger real action (e.g. contact form) with `ALLOW_DISCORD_NOTIFICATIONS=true`.
4. Optional: run per-event QA samples; expect Discord rate limits on batch « all events ».

---

## QA / test plan (staging)

### Unified checkout (MASTER §G — human gate)

#### Core flows

- [ ] Add product → cart → checkout (all selected) → HelloAsso sandbox → order paid, stock correct
- [ ] Adult membership → cart → pay → active
- [ ] Two child memberships → two cart lines → one payment (both selected) → both active
- [ ] Paid rando: reserve → cart timer → pay → registered; timer expiry releases seat

#### Partial payment

- [ ] Cart with product + membership + event → uncheck membership → pay → membership remains in cart
- [ ] Select only event line → product and membership still in cart
- [ ] Zero lines or expired event line → rejected with flash

#### Donation

- [ ] Membership-only cart → donation 5 € → HelloAsso total correct
- [ ] Mixed cart + custom donation → metadata contains donation

#### Edge cases

- [ ] Initiation registration unchanged (free, member gate)
- [ ] Cash/check membership → no cart line
- [ ] Login merges legacy session cart (one-time)
- [ ] Unconfirmed email blocked at POST checkout
- [ ] Mobile cart + checkout layout OK
- [ ] Membership index: « Ajouter au panier » per child in pending alert; mini-cards without duplicate CTA

### Events (public)

- [ ] Upcoming / ongoing / past badges use end time
- [ ] Multi-loop event: loop cards, fullscreen map viewer
- [ ] Registration email shows correct participant name

### Admin panel

- [ ] Level 40: read-only events; level 60: full CRUD
- [ ] Mail logs after test registration
- [ ] `/admin-panel/checkouts` lists checkout attempts
- [ ] **Mobile (≤991px):** page headers stack; tables as cards; offcanvas menu via mobile chrome
- [ ] **Desktop collapsed sidebar:** active icon centered in 48×48 blue tile with white ring (no left bar)
- [ ] **Mobile offcanvas (v2.2.1):** no empty band between navbar and content when menu closed; offcanvas opens/closes cleanly
- [ ] **Dashboard KPIs (v2.2.1):** stat cards compact grid; readable on mobile (2-col) and desktop

### Discord notifications (DR-002)

- [ ] SUPERADMIN (≥ 70): access **Notifications** in sidebar
- [ ] Create channel — URL masked after save; test button sends embed
- [ ] Event toggles persist (group select all / clear all)
- [ ] HelloAsso sandbox payment → `payment.succeeded` embed (if toggle on + `ALLOW_DISCORD_NOTIFICATIONS=true`)
- [ ] Public contact form → `contact_message.received` (default on for new channels)
- [ ] Staging without `ALLOW_DISCORD_NOTIFICATIONS` → no outbound Discord (silent no-op)

### Memberships

- [ ] Before 15 Aug: cart shows **current** season label (not next season)
- [ ] From 15 Aug: next season available for purchase

### Roller stock

- [ ] Equipment reservation without physical decrement; closure releases sizes

### Security & analytics

- [ ] Contact form Turnstile; Umami consent-gated

---

## Risks and rollback

| Risk | Mitigation / rollback |
| --- | --- |
| Unified checkout regression | `UNIFIED_CART_ENABLED=false` → immediate legacy session cart + direct HelloAsso |
| Mid-flight HelloAsso checkouts | Pending `Checkout` rows remain; manual admin review |
| Orphan `CartLine` rows | Admin clear or optional rake (MASTER §H) |
| Roller stock quantities wrong | Manual admin adjustment |
| Migration failure | DB snapshot + redeploy previous staging SHA |
| Discord spam / wrong channel | Disable channel in admin or rotate webhook URL in Discord settings |
| Discord rate limit (QA batch) | Retry failed samples individually; batch job is best-effort |

**Production cutover:** enable `UNIFIED_CART_ENABLED=true` only after staging QA sign-off (Florian).  
**Discord on prod:** configure channels in admin; no extra ENV required beyond production deploy.

---

## Commit reference (checkout epic — highlights)

```
e99fbbbc feat(notifications): DR-002 Discord webhook admin channels
5b48e999 fix(admin): center collapsed sidebar rail and active icon highlight
f831da7a refactor(admin-panel): enhance mobile responsiveness and UI consistency
72cfaa11 test: fix specs for i18n, admin panel, and unified cart
64138088 chore(security): patch Rails, Puma, and npm audit fixes
17866966 fix(memberships): enforce sale season gate before 15 August
b5ef5336 fix(i18n): French validation messages for event creation form
417eb809 docs(release): update staging release notes and AGENT workflow
db0f091b fix(checkout): membership cart UX and UnifiedCart autoload
f01e7b38 docs(checkout): mark Waves 5–6 DoD complete in MASTER plan
67dec0d2 chore(checkout): wave 6 cleanup and regression specs
4231ed18 feat(checkout): wave 5 UX polish and staging cutover prep
50d00d2d feat(checkout): wave 4 unified checkout partial payment and fulfillment
e7c7b75c feat(checkout): wave 3 memberships via account cart
85bb05e5 feat(checkout): wave 1 account cart and feature flag
0d0f9289 feat(checkout): wave 2 paid event registration via cart
18e0debe docs(checkout): add MASTER plan and unified cart UX spec
4ceced13 docs: add DR-001 unified checkout decision
```

Full Dev log since `origin/staging`: `git log origin/staging..Dev --oneline`

---

## Related documentation

- [`DR-002-discord-webhook-notifications.md`](DR-002-discord-webhook-notifications.md)
- [`PLAN-unified-checkout-MASTER.md`](PLAN-unified-checkout-MASTER.md)
- [`DR-001-unified-checkout-cart.md`](DR-001-unified-checkout-cart.md)
- [`docs/09-product/unified-cart-ux.md`](../09-product/unified-cart-ux.md)
- [`docs/06-events/roller-stock.md`](../06-events/roller-stock.md)
- [`docs/08-security-privacy/umami-analytics.md`](../08-security-privacy/umami-analytics.md)
- [`AGENTS.md`](../../AGENTS.md) — agent workflow & staging release process

---

## Maintaining this file

When preparing the next **Dev → staging** PR:

1. Update **commit range** and **head SHA** at the top.
2. Add new features / migrations / ENV vars / QA items.
3. Add a line in [`CHANGELOG.md`](CHANGELOG.md) pointing here.
4. Cross-check [`AGENTS.md`](../../AGENTS.md) § Release to staging.
