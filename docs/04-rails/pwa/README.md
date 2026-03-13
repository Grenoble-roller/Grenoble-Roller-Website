# PWA (Progressive Web App) – Grenoble Roller

Ce dossier documente l’étude et la mise en conformité PWA de l’application Grenoble Roller pour une cible **2025–2026**.

## Documents

| Fichier | Contenu |
|--------|---------|
| [conformite-2026.md](conformite-2026.md) | Critères PWA 2026, état actuel, écarts, modifications à prévoir, impact déploiement |
| [actions-pwa.md](actions-pwa.md) | Comparaison projet / doc (Rails, MDN, web.dev) et checklist d’actions pour rendre le site PWA |
| [questions-manifest-layout.md](questions-manifest-layout.md) | Questions à trancher pour le manifest et le layout (nom, couleurs, display) |

## Résumé

- **Objectif** : Rendre l’app installable et conforme aux attentes PWA 2026 (manifest, icônes, optionnellement service worker).
- **Déploiement** : Aucun changement obligatoire entre Kamal et les scripts `ops/` : la PWA est côté app (fichiers servis par Rails + meta/link dans les layouts).
- **État actuel** : **PWA validée** — routes actives, manifest (Grenoble Roller, G.Roller, icônes 192/512), layout (lien manifest + theme-color), service worker enregistré avec mise à jour auto. Installabilité testée (Chrome). HTTPS en place en production (Caddy).

Voir [conformite-2026.md](conformite-2026.md) pour le détail.
