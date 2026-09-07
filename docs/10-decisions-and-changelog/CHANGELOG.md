# Changelog

Ce fichier documente les changements significatifs du projet Grenoble Roller.

## [2026-09-07] - PurgeCSS actually applied (v2.4.3)

### Fixed
- **CSS build:** `build:css:purge` never wrote PurgeCSS output (CLI no-op) → deploys kept ~1.8 MiB Bootstrap. Write results via `scripts/purge-css.mjs`.

### Changed
- Tighter PurgeCSS safelist (runtime/JS/Pagy/PhotoSwipe only); drop broad `/^btn-/`, `/^bg-/`, `/^text-/` prefixes.
- Public CSS only purged; leave `active_admin.css` unpurged.
- Local build: `application.bootstrap.css` **~344 KiB** (was ~1.8 MiB).

### Documentation
- Patch note: [`release-purgecss-2026-09.md`](release-purgecss-2026-09.md) (v2.4.3)

## [2026-09-07] - Fix SEO JSON-LD breaking CSS/JS head (v2.4.2)

### Fixed
- **P0 layout:** `seo_json_ld` used `tag(:script, content: …)` so JSON sat in a `content=` attribute and left `<script>` open; browsers swallowed stylesheet + importmap → unstyled pages and broken JS. Emit JSON-LD as the script **body** instead.
- **SEO meta:** restore non-empty `og:description` / `twitter:description` (no longer strip the whole meta tag when deriving OG/Twitter copy).

### Tests
- Helper + homepage request regression covering script shape and head asset tags.

### Documentation
- Patch note: [`release-seo-jsonld-head-fix-2026-09.md`](release-seo-jsonld-head-fix-2026-09.md) (v2.4.2)

## [2026-09-06] - Attendance Audit Trail (v2.4.1)

### Added
- Audit trail for attendance create/update/destroy actions via `AuditLog` model, tracking user, event, status changes, etc.

## [2026-09-05] - SEO/GEO Improvements & Lazy Loading (v2.4.0)

### Added
- **SEO Helper:** New `seo_head` helper for dynamic meta, OG, Twitter, JSON-LD (Organization+Event).
- **SEO/GEO Content:** FAQ section (homepage), descriptive anchor text replacements, heading hierarchy fixes.
- **Performance:** Lazy loading (`loading="lazy"`) extended to all images (`lazy_image_tag`).

### Documentation
- Patch note: [`release-seo-improvements-2026-09.md`](release-seo-improvements-2026-09.md) (v2.4.0)

## [2026-08-04] - Event map viewer: PhotoSwipe overlay (v2.3.4)

### Changed
- **Event cover + loop maps:** PhotoSwipe 5 overlay gallery (pinch/wheel zoom) on mobile and desktop — replaces native new-tab open on coarse/narrow viewports and the custom non-zoom lightbox.
- Importmap pins `photoswipe` + `photoswipe/lightbox`; CSS vendored + PurgeCSS safelist `/^pswp/`.

### Documentation
- AGENT.md gotcha updated; Discord announce payload bumped to v2.3.4 in `.github/release-discord.yml`.
- Patch note: [`release-event-map-photoswipe-2026-08.md`](release-event-map-photoswipe-2026-08.md) (v2.3.4)

## [2026-08-03] - Storefront stock badges (honest + low-stock)

### Fixed
- Product stock badge used `stock_qty` when inventory was out of sync — could show **En stock** while add-to-cart stayed disabled.

### Changed
- Storefront badges: **En stock** (>5) · **Plus que N** / orange (1–5) · **Rupture** (0); PDP badge updates with selected variant.
- Threshold `ProductsHelper::LOW_STOCK_THRESHOLD = 5` (aligned with events/admin cues).

## [2026-08-03] - Production release staging → main (v2.3.3)

### Documentation
- Production release / patch note: [`release-staging-to-main-v2.3.3-2026-08.md`](release-staging-to-main-v2.3.3-2026-08.md) — 34 commits (`764095dd`…`ba965598`), **no migrations**, rollback = redeploy previous `main` image.

Bundles staging-validated UX slices **v2.3.2 + v2.3.3**: memberships polish, shop catalog/PDP, orders density, glass/WCAG chips, stock badges, cart stale-membership fix.

## [2026-08-03] - Orders density + PDP + glass + WCAG chips (v2.3.3)

### Changed
- **Orders (`/orders`):** dense billing-style rows (`#id · date · product · status chip · price · Payer/Voir`); FR icon chips; inline actions (no full-width Détails).
- **Product detail (`/shop/:slug`):** pro PDP — square 1:1 gallery + variant image thumbs; compact buy column (size tiles, price, qty, CTA); long description below; nav `Boutique / product` (no Accueil).
- **Glass:** solid light/dark `--bs-body-bg`; theme-agnostic `--liquid-glass-bg: #969ca114`; reduced-transparency drops blur only (never paints cards with `body-bg`).
- **A11y soft status:** `--status-*-fg/bg/border` dual-theme (≥4.5:1); order chips + `.status-badge` no longer use `--bs-warning` as text on pastel fills.
- **Images:** `square_image_variant` true 1:1 `resize_to_fill` for storefront.

### Fixed
- Theme flash / broken dark text when body bg was nearly transparent.
- Stimulus `route_image_viewer`: declare `#escapeHandler` (private field SyntaxError).
- **Cart:** `refresh_membership_lines!` destroys stale membership lines when status is no longer `pending` (avoids `InvalidMembershipStatusError` on `/cart`).

### Documentation
- Patch note: [`release-orders-density-ux-2026-08.md`](release-orders-density-ux-2026-08.md) (v2.3.3)
- Plan: [`PLAN-orders-density-ux.md`](PLAN-orders-density-ux.md)
- Image formats: [`image-formats-and-variants.md`](../04-rails/setup/image-formats-and-variants.md)

## [2026-08-03] - UX memberships + shop catalog (v2.3.2 → Dev)

### Changed
- **Memberships:** remaining-days progress bar; **Réadhérer** on adult card (not hero-only); hide renew once sale-season active/pending successor exists; skip misleading sidebar « Pas d'adhésion active » during renew window; button/icon vertical centering.
- **Shop catalog:** fixed **1:1** listing thumbnails (PDP stays **16:9**); denser shelf cards; whole-card links (no listing CTA buttons); floating filter rail + mobile chips; HelloAsso migration banner kept; product count in controller; cart shortcut in header.
- **Orders / checkout:** hero balance + hide empty-state sidebar shop link; checkout uses site `container`.

### Tests
- Membership `#renewable_now?` successor cases; request specs for adult/child Réadhérer; shop catalog clickable cards.

### Documentation
- Patch note: [`release-ux-pages-verification-2026-08.md`](release-ux-pages-verification-2026-08.md) (v2.3.2)
- PLAN tracker: [`PLAN-ux-pages-verification.md`](PLAN-ux-pages-verification.md)
- Image formats: listing 1:1 CSS exception — [`image-formats-and-variants.md`](../04-rails/setup/image-formats-and-variants.md)

## [2026-08-03] - Shop index uses site container width

### Fixed
- Public boutique (`/shop`) used `container-fluid` and stretched edge-to-edge on desktop; aligned with `container` like product show, events, and cart.

## [2026-08-03] - Production release staging → main (v2.3.1)

### Documentation
- Added production release / patch note: [`release-staging-to-main-2026-08.md`](release-staging-to-main-2026-08.md) — 64 commits (`8fa153c1`…`092061d0`), 9 migrations, ENV checklist, rollback (redeploy previous main; unified cart has no ENV kill-switch).

Bundles staging-validated slices **v2.2 → v2.3.1**: permanent unified checkout, Discord admin notifications (DR-002), June admin/events batch, membership renewals from **1 August**, event image viewer (mobile/desktop), organizer draft index.

## [2026-08-03] - Organizer sees own draft events on index

### Fixed
- Organizers (and creators) see their unpublished (`draft`) events on `/events` (and same fix for initiations index). `EventPolicy::Scope` already allowed it; `EventsController#index` / `InitiationsController#index` incorrectly re-applied `.visible`.
- Draft badge shown to the creator on event/initiation cards (not only moderators).

## [2026-08-02] - Event image viewer (cover + N loop maps)

### Fixed
- Clicking event cover or loop map images opens a viewer again (any number of loops).
- **Mobile / coarse pointer:** open the full image in a new tab (native browser zoom + landscape rotation).
- **Desktop:** in-page lightbox (Esc / backdrop / close), full-resolution source.

### Changed
- Loop map thumbnails are `<a href="full-image" target="_blank">` with Stimulus lightbox intercept on desktop only.

## [2026-08-02] - Membership renewal email → login → form

### Fixed
- Renewal reminder emails now link to `/memberships/new?type=…&renew_from=…` (not bare `/memberships/new`).
- Guest hitting a membership renewal URL is redirected to login, then returned to the same URL (Devise stored location).
- Login page shows a short hint when the return URL is under `/memberships`.
- Early renewal no longer blocked in early August: next-season sales open on **1 August** (aligned with J-30 reminder emails), instead of 15 August.
- `renew_from` prefills the form for **expired** memberships and **active** ones within 30 days of `end_date` (`Membership#renewable_now?`).
- Index / show / membership cards expose a « Renouveler » CTA when `renewable_now?`.

### Changed
- `Membership::NEXT_SEASON_SALE_OPENS_DAY` : `15` → `1` (recurring every year; season calendar remains 1 Sep – 31 Aug).

### Tests
- Model sale-season thresholds (1 August), `#renewable_now?`, mailer link params, sessions return-to renewal URL, request early renewal after 1 August.

## [2026-07-03] - Unified cart permanent (v2.3)

### Changed
- **Unified cart always on** — removed legacy session cart, direct HelloAsso membership/order checkout, and `UNIFIED_CART_ENABLED` feature flag.
- Account cart + `/checkout` are the only payment path for shop, memberships, and paid events.
- Views simplified (no `unified_cart_enabled?` branches); removed `orders/new` legacy template.

### Removed
- `UnifiedCart` module, `app/views/orders/new.html.erb`, `redirect_to_helloasso_checkout!` membership flow.
- `UNIFIED_CART_ENABLED` env var (no longer read).


### Fixed
- Admin mobile: offcanvas sidebar moved **outside** `.admin-container` — eliminates flex gap / empty band below navbar.
- Public navbar mobile: collapsed burger menu no longer reserves flex height (empty strip when closed).
- `syncAdminNavbarHeight`: re-run on `turbo:load` and `resize`; use `getBoundingClientRect` for stable `--navbar-height`.

### Changed
- Admin dashboard KPIs: `_stat_card` partial + compact `.admin-dashboard-kpis` grid (2-col mobile, fit-content desktop).
- Admin mobile layout: `admin-container` / `admin-main-content` block display, `overflow: visible`.

**Full release notes:** [`release-dev-to-staging-2026-06.md`](release-dev-to-staging-2026-06.md) (v2.2.1).

## [2026-06-09] - DR-002: Discord webhook notifications (implemented)

### Added
- Admin **Notification channels** — CRUD Discord webhooks at `/admin-panel/notification-channels` (SUPERADMIN ≥ 70).
- `NotificationEventRegistry` (~65 event keys), per-channel toggles, test button, QA sample embeds (single + batch).
- `NotificationDispatchService` + `DiscordWebhookDeliveryJob`; delivery audit log (`notification_deliveries`).
- Hooks: HelloAsso payment confirmation, public contact, registrations, admin panel actions via `AdminPanel::NotifiesDiscord`.
- Migration `20260609120000_create_notification_tables`.
- ENV gate: `ALLOW_DISCORD_NOTIFICATIONS` (required on staging/dev; production always dispatches when channels enabled).

### Tests
- RSpec: models, registry, dispatch, Discord client, delivery job, admin requests, HelloAsso discord hook, sample service.

**Full release notes:** [`release-dev-to-staging-2026-06.md`](release-dev-to-staging-2026-06.md) (v2.2).

**Decision record:** [DR-002-discord-webhook-notifications.md](DR-002-discord-webhook-notifications.md) (status: implemented).

## [2026-06-08] - DR-002: Discord webhook notifications (proposed)

### Documentation
- **Accepted** [DR-002-discord-webhook-notifications.md](DR-002-discord-webhook-notifications.md) v1.1: full Discord webhook catalog, Florian scope (contact + organizer + all admin toggles).
- Added [DR-002-discord-webhook-notifications.md](DR-002-discord-webhook-notifications.md) v1.0 (proposed).

## [2026-06-08] - Release Dev → staging (June 2026 batch v2.1)

Unified checkout epic + June batch + post-checkout hardening (membership season, admin mobile UX, sidebar rail, security patches, RSpec green).

**Full release notes:** [`release-dev-to-staging-2026-06.md`](release-dev-to-staging-2026-06.md) (v2.1).

### Fixed
- Membership sale season: before 15 August, cart uses running season (not next season).
- Admin collapsed sidebar: centered 48×48 active icon rail; spacing scoped to expanded mode.
- i18n: French validation messages on event creation form.

### Changed
- Admin panel mobile-first: sticky chrome, `admin-page-header`, responsive tables (cards ≤991px), scope tabs.
- Rails 8.1.3, Puma 7.2.1, npm audit fixes; `bundler-audit` in dev Gemfile.

### Tests
- 1462 examples, 0 failures on `Dev` (i18n, admin panel, unified cart spec fixes).

## [2026-06-08] - Release Dev → staging (June 2026 batch v2)

Unified checkout epic merged on `Dev` + prior June batch (events, admin, roller stock, Umami, Turnstile).

**Full release notes:** [`release-dev-to-staging-2026-06.md`](release-dev-to-staging-2026-06.md) (v2.0 — includes checkout migrations, `UNIFIED_CART_ENABLED`, QA §G).

## [2026-06-08] - Unified checkout Waves 5–6 (UX polish + cleanup)

### Added
- Navbar badge counts all `CartLine` types when unified cart enabled.
- Pending payment banner on Mes sorties with cart CTA.
- Cart section empty states, expiry warnings (< 5 min), mobile sticky checkout/cart footers.
- `AdminPanel::CheckoutsController` read-only audit (`/admin-panel/checkouts`).
- Staging env documents `UNIFIED_CART_ENABLED=true` in `ops/dokploy/env/staging.env.example`.

### Changed
- Flash toasts use `flash[:notice_type]`; cart CTA on membership/event add flashes.
- `CartsController` / `OrdersController#build_cart_items` skip `session[:cart]` when flag on.
- `Memberships::PaymentsController` redirects to cart when flag on (legacy HelloAsso when off).
- Updated `docs/09-product/flux-boutique-helloasso.md` for unified flow.

### Tests
- Wave 5 specs: `application_helper`, `unified_cart` UX, mailer timing, checkout sticky footer.
- Wave 6: checkout-related RSpec regression suite (see MASTER Appendix J).

## [2026-06-08] - Unified checkout MASTER plan (agent SSOT)

### Documentation
- Added authoritative [PLAN-unified-checkout-MASTER.md](PLAN-unified-checkout-MASTER.md) v1.1: Waves 0–6, partial payment (per-line checkboxes), donation on every checkout, initiations out of scope, file checklist, RSpec matrices + appendix J, QA staging, rollback, orchestration.
- **Accepted** [DR-001-unified-checkout-cart.md](DR-001-unified-checkout-cart.md) v1.1: account cart + unified HelloAsso checkout.
- Updated [PLAN-unified-checkout-3-phases.md](PLAN-unified-checkout-3-phases.md) v1.2: index pointing to MASTER as SSOT.
- Updated [../09-product/unified-cart-ux.md](../09-product/unified-cart-ux.md) v0.3: checkout checkboxes, donation always, resolved open questions.

## [2026-06-08] - Unified checkout plan + UX spec (initial)

### Documentation
- **Accepted** [DR-001-unified-checkout-cart.md](DR-001-unified-checkout-cart.md): account cart + single HelloAsso checkout for shop, memberships, paid events.
- Added [PLAN-unified-checkout-3-phases.md](PLAN-unified-checkout-3-phases.md): 6-wave AI implementation plan.
- Added draft [../09-product/unified-cart-ux.md](../09-product/unified-cart-ux.md).

## [2026-06-08] - DR-001: Unified checkout (proposed)

### Documentation
- Added [`DR-001-unified-checkout-cart.md`](DR-001-unified-checkout-cart.md): phased checkout strategy (paid events Phase 1; harmonized cart Phase 2); manual `payment_required` flag.

## [2026-06-07] - Release Dev → staging (June 2026 batch)

Consolidated release: events lifecycle/UI, admin panel (event read access, organizers, goodies, mail logs, carousel settings), Umami analytics, Turnstile on contact form, roller stock reservations (v2.3), dev tooling (mise, dotenv).

**Full release notes:** [`release-dev-to-staging-2026-06.md`](release-dev-to-staging-2026-06.md)

## [2025-12-11] - Correction installation crontab et health check HTTP en staging

### Corrigé
- **Installation crontab dans les scripts de déploiement** :
  - `whenever --update-crontab` retournait un succès même quand le crontab n'était pas installé
  - Le message "your crontab file was not updated" n'était pas détecté
  - **Impact** : Le crontab n'était pas réellement installé malgré le message de succès
  - Détection du message d'erreur "your crontab file was not updated"
  - Méthode alternative avec `crontab -` si `whenever --update-crontab` échoue
  - Vérification que le crontab est réellement installé après l'installation

- **Health check HTTP dans les scripts de déploiement** :
  - Le health check utilisait le port externe (3001) pour tester depuis l'intérieur du conteneur
  - Le conteneur écoute sur le port interne (3000) défini par la variable d'environnement PORT
  - **Impact** : Le health check échouait en staging avec le code "000000" (connexion impossible)
  - Détection automatique du port interne depuis la variable d'environnement PORT du conteneur
  - Le health check teste maintenant sur le port interne (3000) depuis le conteneur

### Fichiers modifiés
- `ops/lib/deployment/cron.sh` (lignes 39-110)
- `ops/lib/health/checks.sh` (lignes 55-69)

### Détails techniques
- **Crontab** :
  - Capture de la sortie de `whenever --update-crontab` pour détecter les échecs silencieux
  - Méthode alternative : génération du crontab avec `whenever --set` puis installation via `crontab -`
  - Vérification post-installation avec `crontab -l` pour confirmer l'installation
- **Health check** :
  - **AVANT** : Test HTTP sur `http://localhost:${port}/up` où `port` = port externe (3001)
  - **APRÈS** : Détection automatique du port interne via `${PORT:-3000}` et test sur ce port
  - Le port externe (3001) reste utilisé pour l'affichage dans les logs
  - Compatible avec staging (3001:3000) et production (80:3000)

## [2025-12-11] - Correction installation Node.js dans Dockerfile

### Corrigé
- **Installation Node.js dans Dockerfile** :
  - Remplacement de l'installation via `node-build` (GitHub) par téléchargement direct depuis `nodejs.org`
  - Détection automatique de l'architecture système (x64, arm64)
  - **Impact** : Résout l'erreur "gzip: stdin: not in gzip format" lors du build Docker
  - Installation plus fiable et plus rapide (pas de compilation)

### Fichiers modifiés
- `Dockerfile` (lignes 39-44)

### Détails techniques
- **AVANT** : `curl -sL https://github.com/nodenv/node-build/archive/master.tar.gz | tar xz`
- **APRÈS** : Téléchargement direct depuis `nodejs.org/dist/v${NODE_VERSION}/`
- Détection automatique de l'architecture avec `uname -m`
- Support des architectures x86_64 (x64) et aarch64/arm64
- Utilisation de `.tar.xz` au lieu de `.tar.gz` pour les binaires officiels Node.js

## [2025-01-20] - Correction scripts de déploiement : exclusion fichiers de logs

### Corrigé
- **Vérification post-pull dans les scripts de déploiement** :
  - Les fichiers de logs (`logs/` et `ops/logs/`) sont maintenant exclus de la vérification Git
  - Les fichiers de logs peuvent être créés/modifiés sans bloquer le déploiement
  - Les autres modifications non commitées continuent de bloquer le déploiement (comportement attendu)
  - **Impact** : Évite les blocages inutiles lors des déploiements automatiques

### Fichiers modifiés
- `ops/staging/deploy.sh` (ligne 248-249)
- `ops/production/deploy.sh` (ligne 248-249)

### Détails techniques
- **AVANT** : `GIT_STATUS=$(git status --porcelain 2>/dev/null || echo "")`
- **APRÈS** : `GIT_STATUS=$(git status --porcelain 2>/dev/null | grep -vE "(logs/|ops/logs/)" || echo "")`
- Les fichiers de logs sont ignorés par Git (`.gitignore`) mais peuvent apparaître dans `git status` s'ils sont créés/modifiés localement
- La commande `grep -vE` filtre les lignes contenant `logs/` ou `ops/logs/` pour exclure ces fichiers de la vérification

## [2025-12-07] - Finalisation Complète Feature Email (OrderMailer + Tests)

### Ajouté
- **Templates texte OrderMailer** : ✅ 7 fichiers `.text.erb` créés (2025-12-07)
  - `order_confirmation.text.erb`
  - `order_paid.text.erb`
  - `order_cancelled.text.erb`
  - `order_preparation.text.erb`
  - `order_shipped.text.erb`
  - `refund_requested.text.erb`
  - `refund_confirmed.text.erb`
- **Tests RSpec OrderMailer** : ✅ `spec/mailers/order_mailer_spec.rb` créé (2025-12-07)
  - Tests complets pour les 7 méthodes OrderMailer
  - Vérification headers, subject, body, HTML/text parts
- **Tests d'intégration emails** : ✅ `spec/requests/event_email_integration_spec.rb` créé (2025-12-07)
  - Vérification envoi emails lors de l'inscription/désinscription aux événements
  - Tests avec ActiveJob pour vérifier l'envoi asynchrone

### Modifié
- **Documentation clarifiée** :
  - `cycle-01-building-log.md` : Mentions "non validé en production" corrigées → Notifications email ✅ TERMINÉ
  - `cycle-01-phase-2-plan.md` : Tests d'intégration marqués comme créés
  - `emails-recapitulatif.md` : Statut OrderMailer mis à jour (⚠️ 50% → ✅ 100%)
- **Statistiques globales** : 75% → **100%** de complétion (tous les emails ont HTML + Texte)

### Notes
- Tous les emails de l'application sont maintenant complets (HTML + Texte) : **16/16 emails**
- Tous les mailers ont des tests RSpec complets : **5/5 mailers testés**
- Tests d'intégration ajoutés pour vérifier l'envoi réel des emails

## [2025-12-07] - Consolidation Documentation Confirmation Email

### Modifié
- **Documentation consolidée** : 8 fichiers → 1 document principal unique
  - ✅ [`04-rails/setup/email-confirmation.md`](../04-rails/setup/email-confirmation.md) - Document principal consolidé (tous les éléments)
  - ✅ [`04-rails/setup/emails-recapitulatif.md`](../04-rails/setup/emails-recapitulatif.md) - Référence mise à jour vers le nouveau document
  - 🗑️ Supprimé : `EMAIL-CONFIRMATION-FEATURE-LIVRAISON.md`, `implementation-email-confirmation-summary.md`, `email-confirmation-security-audit.md`, `README-email-confirmation.md`, `email-security-consolidation.md`, `plan-implementation-email-security.md`
- **Structure** : Single source of truth selon les meilleures pratiques de documentation
- **README principal** : Références mises à jour
- **CHANGELOG** : Références mises à jour
- **Building logs** : Références mises à jour

### Notes
- Le guide de sécurité Devise (`devise-email-security-guide.md`, 1930 lignes) est conservé comme référence technique approfondie
- Réduction de **75% du nombre de fichiers** (8 → 2 documents essentiels)

## [2025-11-24] - Intégration changement mot de passe dans profil

### Modifié
- **Formulaire de profil unifié** :
  - **Changement de mot de passe intégré** : Plus besoin de page séparée, tout dans `/users/edit`
  - Formulaire unique pour modifier profil ET mot de passe en une seule fois
  - Section "Modifier le mot de passe" avec indicateur de force (conforme 2025)
  - Toggle pour afficher/masquer les mots de passe (accessibilité WCAG 2.2)
  - `current_password` requis pour toute modification (sécurité renforcée)

- **RegistrationsController** :
  - `update_resource` : Gère changement de mot de passe optionnel
  - Vérifie `current_password` même si le mot de passe n'est pas changé
  - Si password vide → vérifie `current_password` puis `update_without_password`
  - Si password rempli → utilise `update_with_password` (vérifie automatiquement)

- **PasswordsController** :
  - Simplifié : Gère uniquement "Mot de passe oublié" (reset via email)
  - Surcharge `require_no_authentication` pour permettre aux utilisateurs connectés d'accéder à `edit`/`update`
  - Redirection vers profil si utilisateur connecté tente d'utiliser "mot de passe oublié"

### Conformité
- ✅ **NIST 2025** : Mot de passe 12 caractères minimum
- ✅ **WCAG 2.2** : Indicateur de force, toggle password, cibles tactiles 44×44px
- ✅ **UX** : Formulaire unifié, pas de navigation entre pages
- ✅ **Sécurité** : `current_password` toujours requis pour modifications

### Fichiers modifiés
- `app/views/devise/registrations/edit.html.erb` (formulaire unifié avec changement mot de passe)
- `app/controllers/registrations_controller.rb` (gestion changement mot de passe optionnel)
- `app/controllers/passwords_controller.rb` (simplifié pour reset uniquement)

### Notes techniques
- Le formulaire de profil permet maintenant de modifier :
  - Informations personnelles (email, bio, etc.)
  - OU mot de passe (nouveau + confirmation)
  - OU les deux en même temps
- `current_password` est obligatoire pour toute modification (sécurité)
- Si les champs password sont vides, seul le profil est mis à jour
- L'indicateur de force du mot de passe est identique à celui de l'inscription

## [2025-11-24] - Simplification formulaire inscription + Confirmation email

### Ajouté
- **Formulaire d'inscription simplifié** :
  - Réduction à **4 champs obligatoires uniquement** : Email, Prénom, Mot de passe (12 caractères), Niveau
  - Prénom obligatoire pour personnaliser les interactions (événements, emails)
  - Skill level avec cards Bootstrap visuelles (Débutant, Intermédiaire, Avancé)
  - Header moderne avec icône dans cercle coloré
  - Labels avec icônes Bootstrap (envelope, person, shield-lock, speedometer)
  - Help text positif pour mot de passe avec exemple de passphrase

- **Confirmation email avec accès immédiat** (améliorée en 2025-12-07) :
  - Module `:confirmable` activé dans Devise
  - Blocage immédiat si email non confirmé (sécurité renforcée)
  - Confirmation **obligatoire** avant connexion (pas de période de grâce)
  - Email de confirmation avec QR code mobile (PNG)
  - Sécurité renforcée : logging sécurisé, audit trail, détection d'attaques
  - Rate limiting et anti-énumération
  - Documentation : [`04-rails/setup/email-confirmation.md`](../04-rails/setup/email-confirmation.md)

- **Email de bienvenue** :
  - `UserMailer.welcome_email` avec template HTML responsive
  - Template texte (fallback)
  - Envoyé automatiquement après création du compte
  - Lien direct vers les événements

- **Skill level** :
  - Nouveau champ `skill_level` (beginner, intermediate, advanced)
  - Validation obligatoire à l'inscription
  - Cards Bootstrap avec icônes et hover effects
  - Responsive (3 colonnes mobile-friendly)

### Modifié
- **Mot de passe** :
  - Longueur réduite : **14 → 12 caractères** (NIST 2025 standard)
  - Help text amélioré : "Astuce : Utilisez une phrase facile à retenir" + exemple
  - Placeholder : "12 caractères minimum"

- **Modèle User** :
  - `first_name` rendu obligatoire (important pour événements)
  - `skill_level` obligatoire avec validation inclusion
  - Callback `after_create :send_welcome_email_and_confirmation`
  - Méthode `active_for_authentication?` pour permettre accès non confirmé

- **CSS** :
  - Skill level cards avec styles Bootstrap `.btn-check`
  - Auth icon wrapper (header moderne)
  - Focus states WCAG 2.2 (outline 3px)
  - Compatible mode sombre

- **Controllers** :
  - `ApplicationController#ensure_email_confirmed` : méthode réutilisable
  - `EventsController` : exige confirmation pour `attend`
  - `OrdersController` : exige confirmation pour `create`
  - `ApplicationController#configure_permitted_parameters` : `first_name` et `skill_level` dans sign_up

### Conformité
- ✅ **NIST 2025** : Mot de passe 12 caractères (standard actuel)
- ✅ **WCAG 2.2** : Focus 3px visible, cibles tactiles 44×44px
- ✅ **RGPD** : Consentement explicite CGU + Politique
- ✅ **UX** : Formulaire simplifié (4 champs, 1 minute)
- ✅ **Sécurité** : Confirmation email pour actions critiques

### Fichiers créés
- `db/migrate/YYYYMMDDHHMMSS_add_skill_level_to_users.rb`
- `db/migrate/YYYYMMDDHHMMSS_add_confirmable_to_users.rb`
- `app/mailers/user_mailer.rb`
- `app/views/user_mailer/welcome_email.html.erb`
- `app/views/user_mailer/welcome_email.text.erb`

### Fichiers modifiés
- `app/models/user.rb` (confirmable, skill_level, first_name obligatoire)
- `app/views/devise/registrations/new.html.erb` (formulaire simplifié 4 champs)
- `app/controllers/application_controller.rb` (ensure_email_confirmed, sign_up params)
- `app/controllers/events_controller.rb` (exige confirmation pour attend)
- `app/controllers/orders_controller.rb` (exige confirmation pour create)
- `config/initializers/devise.rb` (password_length 12, allow_unconfirmed_access_for)
- `app/assets/stylesheets/_style.scss` (skill level cards, auth icon wrapper)

### Notes techniques
- Migration `skill_level` : colonne string avec index
- Migration `confirmable` : colonnes confirmation_token, confirmed_at, confirmation_sent_at, unconfirmed_email
- Email bienvenue + confirmation envoyés en parallèle (`deliver_later`)
- Période de grâce 2 jours : utilisateur peut explorer sans confirmer, mais doit confirmer pour actions critiques

### Corrections finales (2025-11-24)
- **Traductions I18n** : Messages d'erreur corrigés (12 caractères au lieu de 14)
- **Redirection erreurs** : Reste sur `/users/sign_up` en cas d'erreur (ne redirige plus vers `/users`)
- **CSS Input-group** : Contour rouge englobe tout le groupe (input + bouton toggle password)
- **Rack::Attack** : Correction de l'accès à `match_data` dans `throttled_responder`
- **Validation email temps réel** : Abandonnée (validation côté serveur suffisante)

## [2025-11-21] - Pages légales complètes + Gestion des cookies RGPD 2025

### Ajouté
- **Pages légales complètes** :
  - Mentions Légales (`/mentions-legales`) - Obligatoire (risque : 75 000€)
  - Politique de Confidentialité / RGPD (`/politique-confidentialite`, `/rgpd`) - Obligatoire (risque : 4% CA)
  - Conditions Générales de Vente (`/cgv`, `/conditions-generales-vente`) - Obligatoire (risque : 15 000€)
  - Conditions Générales d'Utilisation (`/cgu`, `/conditions-generales-utilisation`) - Recommandé
  - Page Contact (`/contact`) - Recommandé (email uniquement, pas de formulaire)
  - Toutes les pages basées sur les informations collectées de l'association
  - Contenu conforme aux obligations légales françaises (RGPD, Code de la consommation, loi pour la confiance en l'économie numérique)

- **Système de gestion des cookies conforme RGPD 2025** :
  - Banner de consentement automatique (Stimulus Controller)
  - Page de préférences détaillée (`/cookie_consent/preferences`)
  - Gestion granulaire des cookies (nécessaires, préférences, analytiques)
  - Stockage des préférences dans un cookie permanent (13 mois, conforme RGPD)
  - Compatibilité Turbo et Stimulus
  - Accessibilité complète (ARIA labels, navigation clavier)

- **Routes RESTful modernes** :
  - `resource :cookie_consent` avec actions `collection` (preferences, accept, reject, update)
  - Routes légales avec alias pour SEO (`/rgpd`, `/conditions-generales-vente`, etc.)
  - Architecture conforme aux conventions Rails 8

- **Helper Ruby** :
  - `CookieConsentHelper` pour vérifier le consentement côté serveur
  - Méthodes : `cookie_consent?(type)`, `has_cookie_consent?`, `cookie_preferences`

- **Documentation légale** :
  - Formulaire de collecte d'informations complété (`informations-a-collecter.md`)
  - Guide mis à jour avec les informations réelles de l'association (`legal-pages-guide.md`)

### Modifié
- **Footer** :
  - Ajout de tous les liens légaux dans le footer simple
  - Footer complet mis à jour avec les liens légaux (prêt pour utilisation future)

- **Documentation** :
  - Mention des cookies de session Rails utilisés pour le panier d'achat
  - Clarification que les cookies de session sont strictement nécessaires

- **Architecture** :
  - Contrôleur Stimulus `cookie_consent_controller.js` pour gestion moderne du banner
  - Compatibilité Turbo avec gestion des événements `turbo:load`

### Conformité
- ✅ **RGPD** : Conforme (politique de confidentialité complète, gestion des cookies)
- ✅ **Directive ePrivacy** : Conforme (banner de consentement, préférences détaillées)
- ✅ **Code de la consommation** : Conforme (CGV complètes avec exception légale L221-28)
- ✅ **Loi pour la confiance en l'économie numérique** : Conforme (mentions légales complètes)
- ✅ **Accessibilité** : WCAG 2.1 AA (ARIA labels, navigation clavier)

### Fichiers créés
- `app/controllers/legal_pages_controller.rb`
- `app/controllers/cookie_consents_controller.rb`
- `app/helpers/cookie_consent_helper.rb`
- `app/javascript/controllers/cookie_consent_controller.js`
- `app/views/legal_pages/mentions_legales.html.erb`
- `app/views/legal_pages/politique_confidentialite.html.erb`
- `app/views/legal_pages/cgv.html.erb`
- `app/views/legal_pages/cgu.html.erb`
- `app/views/legal_pages/contact.html.erb`
- `app/views/cookie_consents/preferences.html.erb`
- `app/views/layouts/_cookie_banner.html.erb`

### Fichiers modifiés
- `config/routes.rb` (routes RESTful pour pages légales et cookies)
- `app/views/layouts/application.html.erb` (intégration du banner de cookies)
- `app/views/layouts/_footer-simple.html.erb` (liens légaux)
- `app/views/layouts/_footer.html.erb` (liens légaux pour version complète)
- `docs/08-security-privacy/informations-a-collecter.md` (formulaire complété)
- `docs/08-security-privacy/legal-pages-guide.md` (guide mis à jour)

### Notes techniques
- Cookies de session Rails (panier, authentification) sont strictement nécessaires et toujours actifs
- Durée de conservation des cookies de consentement : 13 mois (conforme RGPD)
- Attributs de sécurité : `SameSite: Lax`, `Secure` en production
- Timestamp du consentement pour traçabilité

## [2025-01-20] - Job de rappel la veille à 19h + Option wants_reminder

### Ajouté
- **Job de rappel la veille à 19h** :
  - Job `EventReminderJob` exécuté quotidiennement à 19h via Solid Queue
  - Rappels envoyés pour les événements du lendemain (toute la journée, 00:00:00 à 23:59:59)
  - Planification via `config/recurring.yml` (Solid Queue native)
  - **Impact UX** : Réduction du taux d'absence, amélioration de l'expérience utilisateur

- **Option `wants_reminder` dans les attendances** :
  - Migration pour ajouter `wants_reminder` (boolean, default: false) à `attendances`
  - Index sur `wants_reminder` pour optimiser les requêtes
  - Case à cocher dans les modales d'inscription (activée par défaut)
  - Affichage du statut du rappel sur la page événement (alerte Bootstrap)
  - Bouton pour activer/désactiver le rappel après inscription
  - Action `toggle_reminder` dans `EventsController` pour gérer le rappel
  - Route `PATCH /events/:id/toggle_reminder`
  - Rappels envoyés uniquement aux utilisateurs avec `wants_reminder = true`

- **Tests** :
  - 8 tests pour le job de rappel (événements demain, aujourd'hui, après-demain, brouillons, multiple attendees)
  - 4 tests pour l'action `toggle_reminder` (activation, désactivation, erreur si non inscrit)
  - Trait `:with_reminder` dans la factory `Attendance`
  - **Total : 12 nouveaux tests, 0 échec** ✅

### Modifié
- **Job `EventReminderJob`** :
  - Modification de la logique : rappels pour les événements du lendemain (au lieu de 24h avant)
  - Filtrage par `wants_reminder = true` pour ne rappeler que les utilisateurs qui ont activé le rappel
  - Utilisation de `Time.zone.now.beginning_of_day + 1.day` pour définir la journée du lendemain

- **Configuration `config/recurring.yml`** :
  - Modification du schedule : exécution quotidienne à 19h (au lieu de 9h)
  - Configuration pour development et production

- **Vues** :
  - Mise à jour des messages : "la veille à 19h" au lieu de "24h avant"
  - Affichage du statut du rappel sur la page événement (alerte Bootstrap avec icône)
  - Case à cocher dans les modales d'inscription (show, index, _event_card)

- **Controller `EventsController`** :
  - Action `attend` : accepte le paramètre `wants_reminder` à l'inscription
  - Action `toggle_reminder` : active/désactive le rappel pour un utilisateur inscrit
  - Chargement de `@user_attendance` dans `set_event` pour la vue

- **Modèle `Attendance`** :
  - Ajout de `wants_reminder` dans `ransackable_attributes` pour ActiveAdmin

### Fichiers modifiés
- `app/jobs/event_reminder_job.rb`
- `config/recurring.yml`
- `app/controllers/events_controller.rb`
- `app/models/attendance.rb`
- `app/views/events/show.html.erb`
- `app/views/events/index.html.erb`
- `app/views/events/_event_card.html.erb`
- `config/routes.rb`
- `spec/jobs/event_reminder_job_spec.rb`
- `spec/factories/attendances.rb`

### Fichiers créés
- `db/migrate/20250120140000_add_wants_reminder_to_attendances.rb`

## [2025-11-10] - Optimisations DB + Feature max_participants + Correction bug boutons

### Ajouté
- **Counter cache `attendances_count`** :
  - Migration pour ajouter la colonne `attendances_count` sur `events`
  - `counter_cache: true` dans le modèle `Attendance`
  - Mise à jour automatique des compteurs lors de création/suppression d'inscriptions
  - Remplacement de `event.attendances.count` par `event.attendances_count` dans toutes les vues
  - **Impact performance** : Réduction des requêtes SQL (plus de COUNT(*) par événement)

- **Feature `max_participants`** :
  - Migration pour ajouter `max_participants` sur `events` (default: 0 = illimité)
  - Validation `max_participants >= 0` (0 = illimité)
  - Méthodes `unlimited?`, `full?`, `remaining_spots`, `has_available_spots?` dans `Event`
  - Validation dans `Attendance` pour empêcher l'inscription si événement plein
  - Comptage uniquement des inscriptions actives (non annulées)
  - Intégration dans `EventPolicy` (`attend?`, `can_attend?`, `user_has_attendance?`)
  - Affichage des places restantes dans les vues (badges "Complet", "X places disponibles", "Illimité")
  - Bouton "S'inscrire" désactivé si événement plein
  - **Popup de confirmation Bootstrap** avant inscription avec détails de l'événement
  - Champ `max_participants` dans le formulaire d'événement (public et ActiveAdmin)
  - Intégration dans ActiveAdmin (affichage dans index/show/form)

- **Tests** :
  - 3 tests pour le counter cache (incrémentation, décrémentation, échec)
  - 57 tests pour `max_participants` (validations, méthodes, policy, attendances)
  - **Total : 166 exemples, 0 échec** (106 + 60 nouveaux)

### Modifié
- **Modèle Event** :
  - Ajout de `max_participants` dans les validations et `ransackable_attributes`
  - Méthodes `full?`, `unlimited?`, `remaining_spots`, `has_available_spots?`, `active_attendances_count`
  - Comptage uniquement des inscriptions actives pour vérifier si plein

- **Modèle Attendance** :
  - Validation `event_has_available_spots` pour empêcher l'inscription si événement plein
  - Les inscriptions annulées ne comptent pas dans la limite

- **Policy EventPolicy** :
  - `attend?` retourne `false` si événement plein
  - Nouvelles méthodes `can_attend?` et `user_has_attendance?`
  - Ajout de `max_participants` dans `permitted_attributes`

- **Vues** :
  - Affichage des places restantes (badges, compteurs)
  - Boutons conditionnels (désactivés si plein)
  - Popup de confirmation Bootstrap pour l'inscription
  - Mise à jour de toutes les vues (cards, show, index, homepage)

- **ActiveAdmin** :
  - Affichage de `max_participants` dans l'index (avec "Illimité" si 0)
  - Affichage des places restantes dans le show
  - Champ `max_participants` dans le formulaire avec aide contextuelle

- **FactoryBot** :
  - Ajout de `max_participants: 0` par défaut (illimité)
  - Traits `:with_limit` (20 participants) et `:unlimited` (0)

### Corrigé
- **Bug des boutons dans les cards d'événements** :
  - Le `stretched-link` sur le titre interceptait tous les clics, y compris sur les boutons
  - **Solution** : Restructuration HTML avec zone cliquable séparée (`.card-clickable-area`) et zone des boutons (`.action-row-wrapper`)
  - Le `stretched-link` ne couvre plus que le contenu (titre, description, infos), pas les boutons
  - Tous les boutons fonctionnent correctement (S'inscrire, Voir plus, Modifier, Supprimer)
  - Ajout de styles CSS pour isoler les zones cliquables

### Fichiers modifiés
- `db/migrate/20251110141700_add_attendances_count_to_events.rb`
- `db/migrate/20251110142027_add_max_participants_to_events.rb`
- `app/models/event.rb`
- `app/models/attendance.rb`
- `app/policies/event_policy.rb`
- `app/controllers/events_controller.rb`
- `app/views/events/_event_card.html.erb`
- `app/views/events/show.html.erb`
- `app/views/events/index.html.erb`
- `app/views/pages/index.html.erb`
- `app/views/events/_form.html.erb`
- `app/admin/events.rb`
- `spec/models/event_spec.rb`
- `spec/models/attendance_spec.rb`
- `spec/policies/event_policy_spec.rb`
- `spec/factories/events.rb`
- `app/assets/stylesheets/_style.scss`

## [2025-11-10] - Upgrade Rails 8.1.1 + Ruby 3.4.2

### Ajouté
- **Tests RSpec complets** :
  - Factories FactoryBot pour tous les modèles (Role, User, Route, Event, Attendance)
  - Tests requests pour EventsController et AttendancesController
  - Tests policies pour EventPolicy (permissions, scopes)
  - **106 exemples, 0 échec** (75 models + 12 policies + 19 requests)

- **Documentation** :
  - Procédures de rebuild complet Docker
  - Gestion des assets Bootstrap et Bootstrap Icons
  - Documentation des factories FactoryBot

### Modifié
- **Upgrade Rails** : 8.0.4 → 8.1.1
- **Upgrade Ruby** : 3.4.1 → 3.4.2
- **Docker Compose** : Ajout de `BUNDLE_PATH=/rails/vendor/bundle` pour gestion correcte des gems
- **Documentation setup** : Commandes docker-compose mises à jour avec BUNDLE_PATH
- **Documentation testing** : Couverture mise à jour (106 exemples)

### Corrigé
- **Assets Bootstrap** : Restauration de `vendor/javascript/bootstrap.bundle.min.js` après rebuild
- **Fonts Bootstrap Icons** : Copie des fonts dans `app/assets/builds/fonts/` après rebuild
- **Tests** : Résolution des problèmes de frozen paths avec Rails 8.1.1

### Notes techniques
- Rails 8.1.1 résout les problèmes de compatibilité avec Ruby 3.4 (FrozenError)
- Support officiel Ruby 3.4.2 comme version recommandée
- Plus besoin de workarounds (Bootsnap, duplication paths)
- Warnings Sass dépréciés (`@import` → `@use`) : à migrer ultérieurement

## [2025-11-08] - Phase 2 : Events Public CRUD + Inscriptions

### Ajouté
- **CRUD Events public** :
  - Liste des événements (`/events`)
  - Détail événement (`/events/:id`)
  - Création/édition événement (organizers)
  - Suppression événement (créateur ou admin)
  - UI/UX conforme UI-Kit (cards, hero, auth-form, mobile-first)

- **Inscriptions** :
  - Route `POST /events/:id/attend` (inscription)
  - Route `DELETE /events/:id/cancel_attendance` (désinscription)
  - Page "Mes sorties" (`/attendances`)
  - Compteur de participants sur les cartes événements
  - Badge "Inscrit" pour les utilisateurs inscrits

- **Policies Pundit** :
  - EventPolicy (show, create, update, destroy, attend, cancel_attendance)
  - Scopes par rôle (guest, member, organizer, admin)

- **Navigation** :
  - Lien "Événements" dans la navbar
  - Lien "Mes sorties" dans le menu utilisateur

### Modifié
- **ActiveAdmin** : Installation et configuration avec Pundit
- **Routes** : Ajout des routes events et attendances
- **Helpers** : `event_cover_image_url` pour gestion des images événements

## [2025-01-XX] - Phase 1 : E-commerce

### Ajouté
- E-commerce complet (produits, panier, commandes, paiements)
- Authentification Devise
- Rôles et permissions (visitor, member, organizer, admin, superadmin)
- ActiveAdmin pour back-office
- Seeds complets (Phase 1 + Phase 2)

---

## Format

Les entrées suivent le format [Keep a Changelog](https://keepachangelog.com/fr/1.0.0/).

### Types de changements
- **Ajouté** : Nouvelles fonctionnalités
- **Modifié** : Changements dans les fonctionnalités existantes
- **Déprécié** : Fonctionnalités qui seront supprimées
- **Supprimé** : Fonctionnalités supprimées
- **Corrigé** : Corrections de bugs
- **Sécurité** : Vulnérabilités corrigées

