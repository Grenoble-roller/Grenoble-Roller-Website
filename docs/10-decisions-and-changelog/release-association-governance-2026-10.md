# Release note — Association bureau/CA + initiations info (v2.4.12)

**Date:** 2026-10-01  
**Branch:** `Dev` (merged via [#291](https://github.com/Grenoble-roller/Grenoble-Roller-Website/pull/291) + follow-up polish)  
**Author:** GauthierF (`gautfou`) + follow-up UX polish on `Dev`  
**Scope:** Content-only update of association governance pages and initiations index copy. No application logic, migrations, or ENV changes.

## Summary

Refresh public association identity after the bureau/CA change, polish Bureau/CA presentation, and complete the initiations practical-info card (2×2 grid).

## Changes

### About page (`app/views/pages/about.html.erb`)

**Bureau**

| Role | Before | After |
| --- | --- | --- |
| Président | Stéphane S. | Gauthier F. |
| Secrétaire | Gauthier F. | Julien P. |
| Trésorier | Olivier V. | Olivier V. (unchanged) |

**Bureau card order (display)**

Left → center → right: **Secrétaire** | **Président** | **Trésorier** (president centered).

**Conseil d’Administration** (non-bureau seats)

| Before | After |
| --- | --- |
| Julien P. — Vice secrétaire | Stéphane S. — Staffeur |
| Clara V. — Staffeur | Clara V. — Staffeuse |
| Sylvain G. — Vice Trésorier | Sylvain G. — Staffeur |
| Christopher L. — Staffeur | Claire B. — Animatrice |
| Benjamin L. — Vice président | Julia O. — Vice trésorière |
| Renald B. — Staffeur | Rosa M. — Animatrice |
| David B. — Staffeur | Herry G. — Animateur |

Unchanged CA seats: Fabien D., Pascal F. (staffeurs).

**CA icons by role**

| Role | Icon |
| --- | --- |
| Staffeur / Staffeuse | `bi-shield-check` (success) |
| Animatrice / Animateur | `bi-people` (primary) |
| Vice trésorière | `bi-cash-coin` (warning) |

### Mentions légales (`app/views/legal_pages/mentions_legales.html.erb`)

- Directeur de publication: `SAVORNIN Stéphane (Président)` → `FOUSSE Gauthier (Président)`.

### Initiations index (`app/views/initiations/index.html.erb`)

Practical info card as a 2×2 grid:

| | |
| --- | --- |
| **Public :** Adhérents, enfants dès 6 ans (adulte obligatoire) | **Essai gratuit :** 1 essai sans adhésion |
| **Fréquence :** Tous les samedis matin, inscription obligatoire | **Horaires :** 10h15 – 12h00 |

## Migrations / ENV

No migrations.

No new environment variables.

## Tests

Content-only ERB changes. No new specs required for this patch.

## QA

- [ ] `/about` shows Gauthier F. as Président and Julien P. as Secrétaire.
- [ ] `/about` Bureau order is Secrétaire | Président | Trésorier.
- [ ] `/about` CA icons match roles (shield / people / cash).
- [ ] `/about` CA list matches the table above (roles + names).
- [ ] `/mentions-legales` shows FOUSSE Gauthier as directeur de publication.
- [ ] `/initiations` shows frequency + horaires 10h15–12h00 in a balanced 2×2 card.
- [ ] No layout/CSS regression on those three pages (desktop + mobile).

## Rollback

Revert PR #291 commits (`cb4c0822`, `a93efe90`) plus the follow-up about/initiations polish commits, or redeploy the previous release if the published association roster must be restored.
