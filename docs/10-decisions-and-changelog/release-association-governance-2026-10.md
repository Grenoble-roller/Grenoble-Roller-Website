# Release note — Association bureau/CA + initiations info (v2.4.12)

**Date:** 2026-10-01  
**Branch:** `Dev` (merged via [#291](https://github.com/Grenoble-roller/Grenoble-Roller-Website/pull/291))  
**Author:** GauthierF (`gautfou`)  
**Scope:** Content-only update of association governance pages and initiations index copy. No application logic, migrations, or ENV changes.

## Summary

Refresh public association identity after the bureau/CA change, and surface the weekly initiation schedule on `/initiations`.

## Changes

### About page (`app/views/pages/about.html.erb`)

**Bureau**

| Role | Before | After |
| --- | --- | --- |
| Président | Stéphane S. | Gauthier F. |
| Secrétaire | Gauthier F. | Julien P. |
| Trésorier | Olivier V. | Olivier V. (unchanged) |

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

### Mentions légales (`app/views/legal_pages/mentions_legales.html.erb`)

- Directeur de publication: `SAVORNIN Stéphane (Président)` → `FOUSSE Gauthier (Président)`.

### Initiations index (`app/views/initiations/index.html.erb`)

- Added global info line: **Fréquence :** Tous les samedis matin, inscription obligatoire.

## Migrations / ENV

No migrations.

No new environment variables.

## Tests

Content-only ERB changes. No new specs required for this patch.

## QA

- [ ] `/about` shows Gauthier F. as Président and Julien P. as Secrétaire.
- [ ] `/about` CA list matches the table above (roles + names).
- [ ] `/mentions-legales` shows FOUSSE Gauthier as directeur de publication.
- [ ] `/initiations` shows the Saturday-morning frequency info.
- [ ] No layout/CSS regression on those three pages (desktop + mobile).

## Rollback

Revert PR #291 commits (`cb4c0822`, `a93efe90`) or redeploy the previous release if the published association roster must be restored.
