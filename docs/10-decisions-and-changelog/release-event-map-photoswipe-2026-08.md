---
title: "Patch note — event map PhotoSwipe viewer (v2.3.4)"
status: "active"
version: "2.3.4"
created: "2026-08-04"
updated: "2026-08-04"
tags: ["release", "patchnote", "Dev", "staging", "events", "ux", "photoswipe", "changelog"]
---

# Patch note — v2.3.4 (Event map / cover viewer)

**Branch:** `fix/event-map-photoswipe-viewer` → `Dev` → `staging`  
**Changelog:** [`CHANGELOG.md`](CHANGELOG.md)

**Migrations:** none  
**ENV:** none  
**Rollback:** revert merge / redeploy previous image on the target env

---

## Patch note (human / Discord)

### Headline

**Grenoble Roller — v2.3.4**  
Cartes parcours + couverture événement : overlay zoomable (PhotoSwipe)

### What’s new

1. **Clic cover / carte de boucle** → overlay plein écran (reste sur la page)
2. **Mobile** — pinch-to-zoom, pan, swipe pour fermer / changer d’image
3. **Desktop** — zoom molette, Esc / backdrop, flèches entre cover et boucles
4. **Plus** d’ouverture en nouvel onglet sur le clic principal (`href` gardé pour no-JS / middle-click)

### Smoke checklist

- [ ] Événement 1 boucle — carte → overlay + zoom
- [ ] Événement N boucles — swipe / flèches cover ↔ boucles
- [ ] Mobile Safari/Chrome — **pas** de nouvel onglet
- [ ] Middle-click / sans JS — image full via `href`

---

## Discord message (staging)

```text
🎿 Grenoble Roller — staging v2.3.4

Cartes parcours / couverture événement :

• Overlay plein écran (PhotoSwipe) — plus de nouvel onglet
• Pinch-zoom mobile · molette desktop
• Swipe / flèches entre cover et boucles

À tester : fiche événement (1 boucle + multi-boucles), mobile + desktop.
Rollback : redeploy image staging précédente (pas de migration).
```
