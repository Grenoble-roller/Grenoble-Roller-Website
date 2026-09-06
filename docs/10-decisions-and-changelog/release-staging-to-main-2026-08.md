---
title: "Release staging → main (August 2026 production)"
status: "active"
version: "2.3.1"
created: "2026-08-03"
updated: "2026-08-03"
tags: ["release", "production", "main", "changelog", "unified-checkout", "discord-notifications", "memberships", "events"]
---

# Release staging → main (August 2026)

**Target:** merge `staging` → `main` (production = https://grenoble-roller.org)  
**Commit range:** `8fa153c1` … `092061d0` (`origin/main` … `origin/staging`)  
**Commits ahead of main:** **64** (includes merge commits from Dev → staging PRs **#245**, **#246**, **#247**)  
**Head on staging:** `092061d0` — `Merge pull request #247 from Grenoble-roller/Dev`

**Staging validation URL:** https://staging.grenoble-roller.org  
**Human sign-off required** before merge (see AGENTS.md). Do **not** merge this PR without Florian approval.

**Related staging note (detail):** [`release-dev-to-staging-2026-06.md`](release-dev-to-staging-2026-06.md)  
**Changelog:** [`CHANGELOG.md`](CHANGELOG.md)

---

## Patch note (human / Discord)

### Headline

**Grenoble Roller — Production release v2.3.1**  
Panier unifié permanent · notifications Discord admin · renouvellements août · correctifs événements

### What’s new (user-facing)

1. **Panier unifié + paiement HelloAsso (majeur)**  
   - Un seul panier compte pour **boutique**, **adhésions** et **randos payantes**  
   - Un seul passage en caisse HelloAsso, avec **paiement partiel** (cases à cocher) et **don optionnel**  
   - Initiations toujours gratuites ; adhésions espèces/chèque hors panier  
   - Plus d’ancien panier session ni de checkout HelloAsso « direct » (flag `UNIFIED_CART_ENABLED` **supprimé**)

2. **Notifications Discord (ops / admin)**  
   - Canaux webhook configurables dans l’admin (SUPERADMIN)  
   - ~65 types d’événements (contact, candidatures orga, paiements, actions admin…)  
   - En production : envoi dès qu’un canal est activé (pas besoin de `ALLOW_DISCORD_NOTIFICATIONS`)

3. **Adhésions — saison suivante**  
   - Ouverture des ventes / renouvellements dès le **1er août** (au lieu du 15)  
   - Liens mail de rappel → connexion → formulaire de renouvellement (plus de page cassée)  
   - Bouton **Renouveler** quand l’adhésion est renouvelable

4. **Événements / initiations**  
   - Images couverture + cartes de boucle : **mobile** = nouvel onglet (zoom natif) ; **desktop** = lightbox  
   - Organisateurs voient **leurs brouillons** sur la liste publique (visiteurs anonymes : non)  
   - Multi-boucles, organisateurs d’événement, viewer de parcours, badges en cours / passés  
   - Formulaires / UX événements (prix externe vs inscription payante, distances par boucle…)

5. **Admin panel**  
   - Layout mobile (offcanvas, KPIs compacts, navbar)  
   - Logs mails sortants, goodies adhésion, carousel homepage (autoplay + hero image)  
   - Canaux notifications Discord, audit checkouts

6. **Autres**  
   - Umami analytics (après consentement cookies)  
   - Turnstile sur le formulaire contact  
   - Réservations matériel roller par initiation (sans décrément stock physique)  
   - Correctifs sécurité (Rails / Puma / npm / Brakeman)

### Not in this release / still true

- Prod HelloAsso = **live** (staging = sandbox) — revalider un paiement réel après deploy  
- Discord : créer / activer les canaux **après** deploy, avec prudence (prod envoie vraiment)  
- Pas de merge automatique : validation humaine obligatoire

---

## Scope by slice (how it landed on staging)

| Slice | PR Dev→staging | Focus |
| --- | --- | --- |
| **v2.2 / v2.2.1** | #245 | Unified checkout epic (flagged), Discord DR-002, June admin/events batch, admin layout polish |
| **v2.3** | #246 | Unified cart **permanent** — remove legacy cart + `UNIFIED_CART_ENABLED` |
| **v2.3.1** | #247 | Membership renewals (1 Aug), event image viewer mobile/desktop, organizer draft index |

---

## Database migrations (9 — run on prod deploy)

| Migration | Purpose |
| --- | --- |
| `20260607021500_create_outbound_email_logs` | Outbound email metadata for admin |
| `20260607025621_create_event_organizers` | Organizer entities |
| `20260607025623_add_organizer_to_events` | Optional `events.organizer_id` |
| `20260607094750_add_goodies_distributed_to_memberships` | Goodies distribution flag |
| `20260607120000_create_homepage_carousel_settings` | Carousel autoplay settings |
| `20260607130200_add_payment_fields_to_events_and_attendances` | Paid events |
| `20260607205837_create_cart_lines` | Account cart lines |
| `20260608120000_create_checkouts` | Unified checkout sessions |
| `20260609120000_create_notification_tables` | Discord channels / subscriptions / deliveries |

Expect `DB_BOOT_TASK=prepare` (Dokploy) to apply them. **Take a DB backup before prod deploy.**

---

## Environment / Dokploy production checklist

| Action | Detail |
| --- | --- |
| **Remove** `UNIFIED_CART_ENABLED` | Variable no longer read; leave it unset (or delete if present) |
| **Do not set** `ALLOW_DISCORD_NOTIFICATIONS` | Only for staging/dev; production always dispatches when channels enabled |
| Confirm `SOLID_QUEUE_IN_PUMA=true` | Async Discord + jobs |
| Optional Umami | `UMAMI_SCRIPT_URL` + `UMAMI_WEBSITE_ID` (+ dashboard/share URLs) |
| Optional Turnstile ENV | Or rely on Rails credentials |
| HelloAsso | Production credentials / live mode (not sandbox) |

Templates: [`ops/dokploy/env/production.env.example`](../../ops/dokploy/env/production.env.example)

---

## Post-deploy (production)

1. Health: `https://grenoble-roller.org/up`  
2. Smoke cart: login → add shop / membership / paid event → `/checkout` (HelloAsso **live** — use a small real test or known sandbox-safe path if any)  
3. Membership renew: from 1 Aug, renew CTA + email link flow  
4. Event show: cover/loop images on mobile + desktop  
5. Organizer: draft event visible to creator only  
6. Superadmin → **Notifications**: create Discord channel(s) only when ready for real ops alerts  
7. Umami / Turnstile if configured  

---

## QA checklist (condensed — prod smoke)

- [ ] `/up` 200 after deploy  
- [ ] Homepage + login OK  
- [ ] Cart requires login; checkout reachable  
- [ ] Membership renew / sale season (1 Aug)  
- [ ] Event image viewer (phone + desktop)  
- [ ] Organizer draft on index  
- [ ] Admin panel loads (mobile + desktop)  
- [ ] Discord: either channels configured intentionally **or** none yet (no surprise spam)  
- [ ] No leftover `UNIFIED_CART_ENABLED` in Dokploy env  

Full staging QA history: [`release-dev-to-staging-2026-06.md`](release-dev-to-staging-2026-06.md) § QA.

---

## Risks and rollback

| Risk | Mitigation |
| --- | --- |
| Checkout / HelloAsso regression | Redeploy previous **main** image (`8fa153c1` / pre-merge SHA); restore DB from backup if migrations already applied and data corrupted |
| Discord spam | Disable channels in admin or rotate webhook URLs |
| Migration failure | Stop deploy; restore DB snapshot; redeploy previous SHA |
| Cart confusion for members | Communicate « un seul panier compte » in club channels |

**Rollback:** there is **no** ENV kill-switch for unified cart anymore. Rollback = **redeploy previous production release** (+ DB restore only if you must undo migrations).

---

## Commit highlights (non-exhaustive)

| Area | Example commits |
| --- | --- |
| Checkout epic | `85bb05e5` … `4e910dee` (waves + permanent cart) |
| Discord DR-002 | `e99fbbbc` |
| Admin UX | `f831da7a`, `54ebcd1b` |
| Memberships Aug | `9bc3ec70` |
| Event images | `28f55175`, `3316d428` |
| Organizer drafts | `0f16a913` |
| Security | `64138088`, `8c6adfd6` |

---

## Related documentation

- [`CHANGELOG.md`](CHANGELOG.md)  
- [`release-dev-to-staging-2026-06.md`](release-dev-to-staging-2026-06.md)  
- [`PLAN-unified-checkout-MASTER.md`](PLAN-unified-checkout-MASTER.md)  
- [`DR-001-unified-checkout-cart.md`](DR-001-unified-checkout-cart.md)  
- [`DR-002-discord-webhook-notifications.md`](DR-002-discord-webhook-notifications.md)  
- [`AGENTS.md`](../../AGENTS.md) — promotion path `Dev` → `staging` → `main`
