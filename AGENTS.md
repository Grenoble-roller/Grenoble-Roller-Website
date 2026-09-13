# Grenoble Roller — Agent Guide

Community platform for the **Grenoble rollerblading association**: e-commerce shop, events & initiations, memberships (HelloAsso), and a custom admin panel.

**Repo:** [Grenoble-roller/Grenoble-Roller-Website](https://github.com/Grenoble-roller/Grenoble-Roller-Website) · **Submodule path:** `repositories/Grenoble-Roller-Website` in the WorkSpace monorepo.

---

## Language policy (mandatory)

| Context | Language |
| --- | --- |
| **Chat with Florian** | **French** |
| **Code, comments, commit messages, PR bodies** | **English** |
| **User-facing UI copy** | **French** (MVP — no i18n layer) |
| **Docs in `docs/`** | Mostly French (product/ops); agent-written repo artifacts in **English** |

### Docs language (MC#85 decision 2026-08-14)

`docs/` product and ops documentation is **French-first** — deliberate, not drift:
the audience is the association's French-speaking volunteers and maintainers,
Shape Up cycles run in French, and the user-facing UI is French.

- **French-first**: product, ops, domain, setup, runbook, and cycle documentation.
- **English**: agent-authored artifacts — decision records (DR-XXX), runbook
  templates, research/audit reports, restructure plans.
- Code, commits, and comments remain **English** (unchanged).
- Frontmatter stays **optional-but-recommended** for the FM-bearing clusters
  (`00-overview`, `08-security-privacy`, `10-decisions-and-changelog`,
  `12-development`, `09-product`, `06-events`); it is not enforced on repo product docs.

Do **not** translate existing French docs to English (or vice-versa) — the bilingual
index table above already routes agents to the right doc regardless.

---

## Documentation — read before you change things

Do **not** duplicate canonical docs here — use the index below.

| Role | Path | When to read |
| --- | --- | --- |
| **Project overview & status** | [`docs/00-overview/README.md`](docs/00-overview/README.md) | Always first — phases, feature completion, backlog |
| **Git workflow & PR rules** | [`docs/01-ways-of-working/README.md`](docs/01-ways-of-working/README.md) | Branches, commits, review checklist |
| **Shape Up methodology** | [`docs/02-shape-up/README.md`](docs/02-shape-up/README.md) | Cycle planning, appetite, cooldown |
| **System architecture** | [`docs/03-architecture/system-overview.md`](docs/03-architecture/system-overview.md) | Monolith boundaries, envs, NFRs |
| **Domain models** | [`docs/03-architecture/domain/models.md`](docs/03-architecture/domain/models.md) | Model relationships (verify against `db/schema.rb`) |
| **Rails conventions** | [`docs/04-rails/conventions/README.md`](docs/04-rails/conventions/README.md) | Controllers, models, CSS, security |
| **Local setup (Docker)** | [`docs/04-rails/setup/local-development.md`](docs/04-rails/setup/local-development.md) | Dev containers, credentials, seeds |
| **Admin panel** | [`docs/04-rails/admin-panel/README.md`](docs/04-rails/admin-panel/README.md) | Modules, migration from ActiveAdmin |
| **Admin permissions** | [`docs/04-rails/admin-panel/PERMISSIONS.md`](docs/04-rails/admin-panel/PERMISSIONS.md) | Pundit + role levels (cross-check `AdminPanel::BaseController`) |
| **RSpec** | [`docs/05-testing/rspec/README.md`](docs/05-testing/rspec/README.md) | Methodology, failure fiches, Docker command |
| **Events domain** | [`docs/06-events/README.md`](docs/06-events/README.md) | Waitlist, roller stock, free trial, reminders |
| **Ops & deploy** | [`docs/07-ops/deployment.md`](docs/07-ops/deployment.md) · [`ops/README.md`](ops/README.md) | Watchdog, rollback, modular deploy scripts |
| **Runbooks** | [`docs/07-ops/runbooks/`](docs/07-ops/runbooks/) | Local, staging, production, Dokploy |
| **Security / a11y / legal** | [`docs/08-security-privacy/README.md`](docs/08-security-privacy/README.md) | RGPD, cookies, WCAG, legal pages |
| **Umami analytics** | [`docs/08-security-privacy/umami-analytics.md`](docs/08-security-privacy/umami-analytics.md) | ENV vars, consent gate, custom events |
| **Product & UX** | [`docs/09-product/README.md`](docs/09-product/README.md) | HelloAsso, memberships, orders, backlog |
| **Unified cart UX** | [`docs/09-product/unified-cart-ux.md`](docs/09-product/unified-cart-ux.md) | Cart + checkout UX, partial pay, donation |
| **HelloAsso / shop flow** | [`docs/09-product/flux-boutique-helloasso.md`](docs/09-product/flux-boutique-helloasso.md) | Legacy + unified checkout paths |
| **HelloAsso setup** | [`docs/09-product/helloasso-setup.md`](docs/09-product/helloasso-setup.md) | OAuth credentials, polling, sandbox vs prod |
| **Unified checkout (agent SSOT)** | [`docs/10-decisions-and-changelog/PLAN-unified-checkout-MASTER.md`](docs/10-decisions-and-changelog/PLAN-unified-checkout-MASTER.md) | Waves 0–6, QA §G, rollback §H |
| **ADR unified cart** | [`docs/10-decisions-and-changelog/DR-001-unified-checkout-cart.md`](docs/10-decisions-and-changelog/DR-001-unified-checkout-cart.md) | Decision record |
| **DR Discord notifications** | [`docs/10-decisions-and-changelog/DR-002-discord-webhook-notifications.md`](docs/10-decisions-and-changelog/DR-002-discord-webhook-notifications.md) | **Implemented** on `Dev` — admin webhooks, ~65 event toggles, `ALLOW_DISCORD_NOTIFICATIONS` gate |
| **CI Discord release announce** | [`docs/07-ops/runbooks/discord-release-announce.md`](docs/07-ops/runbooks/discord-release-announce.md) | Auto post on push to `staging` / `main` — update [`.github/release-discord.yml`](.github/release-discord.yml); secrets `DISCORD_RELEASE_WEBHOOK_STAGING` (Captain Hook) + `DISCORD_RELEASE_WEBHOOK_PRODUCTION` (prod salon) |
| **Release Dev → staging** | [`docs/10-decisions-and-changelog/release-dev-to-staging-2026-06.md`](docs/10-decisions-and-changelog/release-dev-to-staging-2026-06.md) | **Update before each staging PR** — migrations, ENV, QA |
| **Changelog** | [`docs/10-decisions-and-changelog/CHANGELOG.md`](docs/10-decisions-and-changelog/CHANGELOG.md) | Release journal; links to release notes |
| **ADR template** | [`docs/11-templates/decision-record-template.md`](docs/11-templates/decision-record-template.md) | Significant architecture decisions (format DR-XXX, `tags: product/decision`) |
| **Root README** | [`README.md`](README.md) | Quick start, roles, Docker ports |
| **DB diagram** | [`ressources/db/dbdiagram.md`](ressources/db/dbdiagram.md) | Visual schema reference |
| **UI kit (Penpot)** | [`ressources/UI-Kit/penpot-exports/`](ressources/UI-Kit/penpot-exports/) | Design assets |

**Docs layout:** numbered sections `docs/00-overview/` → `docs/12-development/`. There is no top-level `docs/README.md` — use [`docs/00-overview/README.md`](docs/00-overview/README.md) as the index.

---

## Current status (distilled)

Rails **monolith** — shop, events, initiations, and memberships are **largely implemented** (not “Phase 2 planned” anymore). See [`docs/00-overview/README.md`](docs/00-overview/README.md) for percentages and open items.

| Area | State | Canonical doc |
| --- | --- | --- |
| E-commerce + HelloAsso checkout | ✅ Complete (legacy session cart) | [`docs/09-product/flux-boutique-helloasso.md`](docs/09-product/flux-boutique-helloasso.md) |
| **Unified account cart + checkout** | ✅ Permanent on `Dev` — account cart + `/checkout` only | [`PLAN-unified-checkout-MASTER.md`](docs/10-decisions-and-changelog/PLAN-unified-checkout-MASTER.md) · [`unified-cart-ux.md`](docs/09-product/unified-cart-ux.md) |
| Events, routes, attendances, waitlist | ✅ Core done | [`docs/06-events/README.md`](docs/06-events/README.md) |
| Initiations (`Event::Initiation` STI) | ✅ Core done (never paid online) | [`docs/06-events/logique-essai-gratuit.md`](docs/06-events/logique-essai-gratuit.md) |
| Memberships (adult/child, HelloAsso) | ✅ ~95% (cart path when flag on) | [`docs/09-product/adhesions-complete.md`](docs/09-product/adhesions-complete.md) |
| Admin panel (`/admin-panel`) | ✅ Replaces ActiveAdmin | [`docs/04-rails/admin-panel/README.md`](docs/04-rails/admin-panel/README.md) |
| RSpec | ✅ Green suite (see overview for count) | [`docs/05-testing/rspec/README.md`](docs/05-testing/rspec/README.md) |
| UX backlog (pagination, search, newsletter…) | 🚧 Open | [`docs/09-product/todo-restant.md`](docs/09-product/todo-restant.md) |

**Methodology:** Shape Up — fixed appetite, flexible scope ([`docs/02-shape-up/README.md`](docs/02-shape-up/README.md)). **Architecture:** YAGNI monolith, Docker Compose, no K8s/microservices.

---

## Stack (verify `Gemfile` / `package.json`)

| Layer | Choice | Notes |
| --- | --- | --- |
| Framework | **Ruby on Rails 8.1** | App Router N/A — classic MVC |
| Language | **Ruby 3.4.2** | RuboCop Rails Omakase |
| Database | **PostgreSQL 16** | `db/schema.rb` is SSOT for columns |
| Auth | **Devise** | Custom controllers under `app/controllers/` |
| Authorization | **Pundit** | Public policies + `admin_panel/*` policies |
| Admin UI | **Custom `AdminPanel`** | Path `/admin-panel` — **ActiveAdmin disabled** |
| Frontend | **Bootstrap 5.3**, **Turbo**, **Stimulus** | ERB views |
| CSS | **cssbundling-rails** (Sass + PostCSS + PurgeCSS) | `npm run build:css` / `watch:css` |
| Jobs | **Solid Queue** + **Mission Control** | Mounted at `/admin-panel/jobs` |
| Cache / Cable | **solid_cache**, **solid_cable** | DB-backed adapters |
| Pagination | **Pagy ~43** | No `Pagy::Backend` include needed |
| Payments | **HelloAsso** | [`HelloassoService`](app/services/helloasso_service.rb); secrets in credentials |
| Storage | **Active Storage** (+ S3/MinIO) | `image_processing`, `aws-sdk-s3` |
| Security | **rack-attack**, Cloudflare **Turnstile** | [`TurnstileVerifiable`](app/controllers/concerns/turnstile_verifiable.rb) |
| IDs in URLs | **hashid-rails** | Obfuscated public IDs |
| Containerization | **Docker Compose** | `ops/dev`, `ops/staging`, `ops/production` |
| Deploy | **Modular scripts** + watchdog cron | [`ops/README.md`](ops/README.md) |

---

## Project structure

```
app/
  controllers/
    admin_panel/          # Custom admin (dashboard, shop, events, users…)
    events/               # Nested attendances, waitlist
    initiations/          # Nested attendances, waitlist
    orders/, memberships/ # Checkout + HelloAsso payments
    checkouts/            # Unified checkout (partial pay + donation)
  models/
    cart_line.rb          # Account cart (DB per user)
    checkout.rb           # Unified HelloAsso checkout session
    unified_cart.rb       # Feature flag helper
    event.rb              # Base event
    event/initiation.rb   # STI: initiation sessions
  policies/               # Pundit (public + admin_panel + admin legacy)
  services/               # HelloAsso, CartLine, Checkout, fulfillment, exports
  views/                  # ERB + Bootstrap
config/
  routes.rb               # Public + admin-panel + Devise
  credentials.yml.enc     # HelloAsso, secrets (needs master.key)
db/
  schema.rb               # Canonical DB structure
  seeds.rb                # Test users, catalog
docs/                     # Numbered documentation (00–11)
ops/
  dev|staging|production/ # docker-compose per env
  deploy.sh, lib/         # Modular deploy pipeline
spec/                     # RSpec (not Minitest)
ressources/               # Design, DB diagrams, methodology notes
```

---

## Roles & authorization

Seven role **levels** (see [`README.md`](README.md)): `USER(10)` → `SUPERADMIN(70)`.

| Mechanism | Location |
| --- | --- |
| Role model | [`app/models/role.rb`](app/models/role.rb) |
| Public actions | Pundit policies in [`app/policies/`](app/policies/) |
| Admin panel gate | [`AdminPanel::BaseController`](app/controllers/admin_panel/base_controller.rb) — initiations/homepage **≥ 30**, other admin resources **≥ 60** |
| Fine-grained admin | `AdminPanel::*Policy` — see [`PERMISSIONS.md`](docs/04-rails/admin-panel/PERMISSIONS.md) |

**Do not** re-enable ActiveAdmin routes — commented out in [`config/routes.rb`](config/routes.rb).

---

## Key routes (public)

| Path | Purpose |
| --- | --- |
| `/` | Homepage |
| `/shop`, `/products` | Catalog |
| `/cart` | Account cart (`CartLine`) when unified flag on; else session cart |
| `/checkouts/new`, `/checkouts/:id` | Unified checkout (partial lines + donation) |
| `/orders` | Legacy shop checkout (session cart when flag off) |
| `/memberships` | Adhesions — add-to-cart per line when flag on |
| `/events`, `/initiations` | Events & initiation sessions |
| `/attendances` | “Mes sorties” |
| `/admin-panel` | Admin dashboard |
| `/up`, `/health` | Health checks |
| `/mentions-legales`, `/rgpd`, `/cgv`, `/cgu`, `/contact` | Legal & contact |

Full map: [`config/routes.rb`](config/routes.rb).

---

## Common workflows

### Local dev (native — dev-workstation)

Requires [mise](https://mise.jdx.dev/) with shell hook (`eval "$(mise activate bash)"` in `~/.bashrc`).

```bash
cp .env.example .env              # or: ./script/setup-local-env.sh
sudo ./script/setup-local-postgres.sh   # once: Postgres on localhost:5432
mise install
bundle config set --local path vendor/bundle
bundle install
npm install
bin/rails db:prepare db:seed
bin/dev                           # http://localhost:3000
```

`.env` sets `DATABASE_*` (port **5432**), `ACTIVE_STORAGE_SERVICE=local`, `SOLID_QUEUE_IN_PUMA=true`.  
Unified cart is always on — no feature flag required.  
Docker dev (`ops/dev/docker-compose.yml`) remains optional (DB on **5434**).

### Local dev (Docker — optional)

```bash
docker compose -f ops/dev/docker-compose.yml up -d --build
# App: http://localhost:3000 — DB: localhost:5434
```

Details: [`docs/04-rails/setup/local-development.md`](docs/04-rails/setup/local-development.md).

### Run tests (native)

```bash
bin/rails db:test:prepare
bundle exec rspec spec/
bundle exec rubocop
bundle exec brakeman --no-pager
bin/importmap audit
```

### Add a feature touching HelloAsso

1. Read [`docs/09-product/helloasso-setup.md`](docs/09-product/helloasso-setup.md).
2. If touching cart/checkout: read [`PLAN-unified-checkout-MASTER.md`](docs/10-decisions-and-changelog/PLAN-unified-checkout-MASTER.md) and [`unified-cart-ux.md`](docs/09-product/unified-cart-ux.md).
3. Store credentials via `bin/rails credentials:edit` — **never** commit `config/master.key`.
4. Use [`HelloassoService`](app/services/helloasso_service.rb); unified path via [`CheckoutService`](app/services/checkout_service.rb).

### Release to staging (human + agent)

1. Merge feature work into **`Dev`** (integration branch for this repo).
2. **Update** [`release-dev-to-staging-2026-06.md`](docs/10-decisions-and-changelog/release-dev-to-staging-2026-06.md): commit range, migrations, ENV, QA checklist.
3. Add a line in [`CHANGELOG.md`](docs/10-decisions-and-changelog/CHANGELOG.md) pointing to the release note.
4. Update [`.github/release-discord.yml`](.github/release-discord.yml) (`version` / `headline` / `bullets`) — CI posts to Discord on merge to `staging` / `main` ([runbook](docs/07-ops/runbooks/discord-release-announce.md)).
5. Open PR **`Dev` → `staging`**; run RSpec; deploy staging via Dokploy.
6. Staging checkout QA: complete MASTER plan §G before prod merge.
7. Production: merge `staging` → `main` only after human sign-off.

Full Git rules: [`docs/01-ways-of-working/README.md`](docs/01-ways-of-working/README.md).

### Before commit / push on `Dev` (session hygiene)

Global close loop (env check, promote reusable patterns, retain): WorkSpace [`WORKING.md`](../../../WORKING.md) § Session close.

Project-specific:

1. Prod = `grenoble-roller.org` (`main`) · staging = Dokploy `staging` · local = `Dev`.
2. Update [`CHANGELOG.md`](docs/10-decisions-and-changelog/CHANGELOG.md) (+ release-note addendum) before push.
3. `graphify update .` after Ruby/JS/view changes.
4. Domain gotchas → [Gotchas](#gotchas--read-before-changing-things) here; cross-repo habits → WorkSpace `WORKING.md`.

### Add / change admin panel behavior

1. Read module doc under [`docs/04-rails/admin-panel/`](docs/04-rails/admin-panel/).
2. Update controller + **`AdminPanel::*Policy`** + views.
3. Add request specs under `spec/requests/admin_panel/`.

### Significant architecture change

Create an ADR from [`docs/11-templates/decision-record-template.md`](docs/11-templates/decision-record-template.md) before large refactors or new infrastructure.

---

## Git workflow (distilled)

| Branch | Role |
| --- | --- |
| `main` | Production |
| `staging` | Pre-prod validation (Dokploy staging) |
| **`Dev`** | **Integration** — feature branches merge here first |
| `feature/*`, `fix/*`, `docs/*`, … | Feature work → PR into `Dev` |

**Promotion path:** `feature/*` → `Dev` → `staging` → `main`.

**Staging release doc (mandatory before `Dev` → `staging` PR):** [`release-dev-to-staging-2026-06.md`](docs/10-decisions-and-changelog/release-dev-to-staging-2026-06.md).

Conventional commits with scope: `feat(events): …`, `fix(cart): …`. PRs require green RSpec. Full rules: [`docs/01-ways-of-working/README.md`](docs/01-ways-of-working/README.md).

---

## Deployment (distilled)

- **Environments:** `ops/dev/` (3000), `ops/staging/` (3001), `ops/production/` (3002).
- **Pipeline:** git pull → backup → build → migrate → health check → rollback on failure ([`docs/07-ops/deployment.md`](docs/07-ops/deployment.md)).
- **Staging env template:** [`ops/dokploy/env/staging.env.example`](ops/dokploy/env/staging.env.example) — unified cart permanent (v2.3+).
- **Production:** merge `staging` → `main` only after human sign-off ([release note](docs/10-decisions-and-changelog/release-dev-to-staging-2026-06.md)).
- **Watchdog:** cron-driven auto-deploy ([`docs/07-ops/runbooks/watchdog/watchdog.md`](docs/07-ops/runbooks/watchdog/watchdog.md)).
- **Dokploy migration notes:** [`ops/dokploy/Migration.md`](ops/dokploy/Migration.md).

---

## Graphify (agent knowledge graph)

`graphify-out/` is **gitignored** — build locally when exploring architecture.

| Command | Purpose |
| --- | --- |
| `graphify update .` | AST-only rebuild after **code** changes (no API key) |
| `graphify query "<question>"` | Scoped subgraph for architecture questions |
| `graphify path "A" "B"` | Shortest path between concepts |
| `graphify explain "<symbol>"` | Node neighborhood summary |
| `/graphify .` (Cursor) | Full semantic extract — requires LLM API key |

**Agent workflow:**

1. Prefer `graphify query` over repo-wide grep for cross-module relationships.
2. Read [`docs/03-architecture/`](docs/03-architecture/) for human-written architecture; graph complements code structure.
3. After modifying Ruby/JS in a session, run `graphify update .` to refresh the local graph.

Setup: `pip install graphifyy` or `graphify install --platform cursor`.

---

## Gotchas — read before changing things

- **Admin is `AdminPanel`, not ActiveAdmin** — gem may remain for CSS legacy; routes are disabled.
- **Initiations are STI** — `Event::Initiation < Event`; shared tables and policies differ from generic events.
- **HelloAsso secrets** live in Rails credentials only — not `.env` in repo (except public Turnstile/Umami/flag vars).
- **Unified cart** — always on; `unified_cart_enabled?` helper returns true. Rollback = redeploy previous release ([MASTER §H](docs/10-decisions-and-changelog/PLAN-unified-checkout-MASTER.md)).
- **Initiations are never paid online** — do not add cart/checkout to `Event::Initiation` registration.
- **Never commit** `config/master.key` or `.env*` files.
- **UI copy is French**; **code comments and commit messages are English**.
- **Use RSpec** (`spec/`) — some older docs mention Minitest; ignore that.
- **Eager-load associations** in controllers (`includes`) — N+1 is a recurring issue; Bullet gem available in dev.
- **Role level in code** may differ from stale permission docs — trust `Role` seeds, `AdminPanel::BaseController`, and Pundit policies over outdated tables.
- **Default seed passwords** are for local dev only — do not reuse in production ([`README.md`](README.md)).
- **CSS requires watcher** in Docker dev — `watch:css` runs alongside Rails (same as `bin/dev`). Built CSS under `app/assets/builds/` is **gitignored** — rebuild on deploy / `npm run build:css`.
- **Umami** — `UMAMI_SCRIPT_URL` + `UMAMI_WEBSITE_ID` in deploy env; script only when `cookie_consent?(:analytics)`; public share link via `UMAMI_SHARE_URL` ([`docs/08-security-privacy/umami-analytics.md`](docs/08-security-privacy/umami-analytics.md)).
- **Membership sale season opens 1 August** (`Membership::NEXT_SEASON_SALE_OPENS_DAY`) — aligned with J-30 renewal reminder emails. Before that date, `sale_season` = running season; from 1–31 Aug, sale = next season while running season stays current until 1 Sep.
- **Renewal links** must use `type` + `renew_from` (`Membership#renewal_form_type`, `#renewable_now?`). Bare `/memberships/new` redirects to index; active same-season membership blocks `#new` unless sale season already advanced.
- **Event images (cover + N loop maps):** PhotoSwipe 5 gallery via `route-image-viewer` on the event show article (`a.pswp-gallery-item`). Overlay + pinch/wheel zoom on **mobile and desktop** (no native new-tab path). Keep `href` full-res for no-JS / middle-click. Do not put Stimulus `data-action` with `->` via Rails `tag` helpers (HTML-escaped).
- **Staging ≠ prod:** bug reports often come from **staging** (newer than `main`). Always check which branch/deploy the reporter used before blaming local `Dev` or prod HTML.
- **Event/initiation index visibility:** rely on `EventPolicy::Scope` only — never chain `.visible` after `policy_scope` in `#index` (that hides creators’ own drafts). Guests still see published/canceled only.

---

## Native Ruby on dev-workstation (mise)

Ruby **3.4.2** is pinned via `.ruby-version` + `mise.toml`. With the mise shell hook active, `ruby`, `bundle`, and `bin/rails` use the project toolchain — not Debian `/usr/bin/ruby` 3.2.

One-time system deps: `sudo ./script/install-native-deps.sh`

```bash
mise trust && mise install
bundle config set --local path vendor/bundle
bundle install
```

Use standard Rails commands ([Getting Started](https://guides.rubyonrails.org/getting_started.html)):

```bash
bundle install
bin/rails db:migrate
bin/rails db:seed
bin/dev
bundle exec rspec spec/
```

Copy `.env.example` → `.env` for local Postgres (5432). `dotenv-rails` loads it in development/test.

Requires **PostgreSQL** locally (`script/setup-local-postgres.sh`) for app + RSpec.

---

## Commands cheat sheet

```bash
# Dev
docker compose -f ops/dev/docker-compose.yml up -d
bin/dev                                    # native alternative

# DB
bin/rails db:migrate db:seed
bin/rails credentials:edit

# Quality
bundle exec rspec spec/
bundle exec rubocop
npm run test:a11y                            # Pa11y + Lighthouse scripts

# CSS
npm run build:css
npm run watch:css

# Deploy (on server)
./ops/staging/deploy.sh
./ops/production/deploy.sh
```

---

## External links

- [HelloAsso API docs](https://api.helloasso.com/v5/docs)
- [Rails 8 guides](https://guides.rubyonrails.org/)
- [Bootstrap 5 docs](https://getbootstrap.com/docs/5.3/)
