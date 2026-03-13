# docs/INDEX.md — Entry point Cursor

**Lire en premier.** Citer les chemins (ex: docs/05-testing/rspec/METHODE.md).

Projet: **Grenoble Roller** — Rails 8, phase production, fin de debug (specs, Rack::Attack, jobs).

**Doc vivante complète :** [docs/README.md](README.md) (sommaire, conventions, flux nouveau dev).

---

## Doc du projet

| Domaine | Chemin | Description |
|---------|--------|--------------|
| Overview | [00-overview/README.md](00-overview/README.md) | Vision, stack, état des features |
| Ways of working | [01-ways-of-working/](01-ways-of-working/) | Branches, PR, revues, commits |
| Shape Up | [02-shape-up/](02-shape-up/) | Cycles, building, cooldown |
| Architecture | [03-architecture/](03-architecture/) | C4, domaine, NFRs, ADRs |
| Rails & setup | [04-rails/](04-rails/), [04-rails/setup/local-development.md](04-rails/setup/local-development.md) | Conventions, admin, PWA, mailing, credentials |
| **Tests & RSpec** | [05-testing/](05-testing/), [05-testing/rspec/METHODE.md](05-testing/rspec/METHODE.md) | Stratégie, méthodologie correction erreurs |
| **Audit specs** | [05-testing/rspec/spec-failures-audit.md](05-testing/rspec/spec-failures-audit.md) | Échecs connus (InitiationParticipantsReportJob, 429, etc.) |
| Événements & initiations | [06-events/](06-events/) | Waitlist, essai gratuit, stock rollers |
| **Ops & runbooks** | [07-ops/runbooks/](07-ops/runbooks/) | Setup local, staging, production, troubleshooting |
| Sécurité & conformité | [08-security-privacy/](08-security-privacy/) | RGPD, accessibilité, pages légales |
| Produit | [09-product/](09-product/) | UX, backlog, HelloAsso |
| Décisions & changelog | [10-decisions-and-changelog/](10-decisions-and-changelog/) | ADR, changelog |
| Templates | [11-templates/](11-templates/) | Gabarits ADR, PR |
| Dev en cours | [development/](development/) | Fonctionnalités en cours |

---

## Règles Cursor

- S’appuyer sur cette doc uniquement (pas d’invention infra/DevOps).
- Tests : suivre [05-testing/rspec/METHODE.md](05-testing/rspec/METHODE.md) et [spec-failures-audit.md](05-testing/rspec/spec-failures-audit.md) pour les corrections.
- Déploiement / ops : [07-ops/runbooks/](07-ops/runbooks/). Qualité : [05-testing/](05-testing/), [08-security-privacy/](08-security-privacy/).
