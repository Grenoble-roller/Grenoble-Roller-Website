# PWA (Progressive Web App) – Grenoble Roller

**Dernière mise à jour** : 2026-08-14


Ce dossier documente l’étude et la mise en conformité PWA de l’application Grenoble Roller pour une cible **2025–2026**.

## Résumé

- **Objectif** : Rendre l’app installable et conforme aux attentes PWA 2026 (manifest, icônes, optionnellement service worker).
- **Déploiement** : Aucun changement obligatoire entre Kamal et les scripts `ops/` : la PWA est côté app (fichiers servis par Rails + meta/link dans les layouts).
- **État actuel** : **PWA validée** — routes actives, manifest (Grenoble Roller, G.Roller, icônes 192/512), layout (lien manifest + theme-color), service worker enregistré avec mise à jour auto. Installabilité testée (Chrome). HTTPS en place en production (Caddy).

> Les documents d'étude détaillés (`conformite-2026.md`, `actions-pwa.md`,
> `questions-manifest-layout.md`) ont été archivés — l'étude est conclue
> (« PWA validée ») et le code est la référence vivante.
