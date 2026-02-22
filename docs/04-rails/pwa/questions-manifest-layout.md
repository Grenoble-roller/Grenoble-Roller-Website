# PWA – Questions pour le manifest et le layout

Document des questions à trancher pour finaliser le **manifest** (`app/views/pwa/manifest.json.erb`) et le **layout** (lien manifest + `theme-color`). Réponds à ces points et on pourra appliquer les réponses dans le code.

---

## 1. Nom et description

| Question | Contexte | Suggestion / valeur actuelle |
|----------|----------|------------------------------|
| **Nom complet** (`name`) | Affiché dans le bandeau d’installation et dans le gestionnaire d’applications. | ✅ **Grenoble Roller** (validé) |
| **Nom court** (`short_name`) | Affiché sous l’icône sur l’écran d’accueil (espace limité, ~12 caractères). | ✅ **G.Roller** (validé ; à confirmer avec le staff) |
| **Description** (`description`) | Optionnel ; peut apparaître dans l’UI d’installation. | ✅ **Communauté roller à Grenoble. Événements, initiations, sorties.** (validé) |

---

## 2. Couleurs

| Question | Contexte | Suggestion / valeur actuelle |
|----------|----------|------------------------------|
| **Couleur de thème** (`theme_color` + meta `theme-color`) | Barre de statut / barre d’URL sur mobile quand l’app est ouverte. | ✅ **#007bff** (validé ; à ajuster si besoin après test) |
| **Couleur de fond** (`background_color`) | Fond du splash au démarrage. Aligné au thème sombre pour éviter un flash blanc. | ✅ **#212529** (fond thème sombre Bootstrap 5.3) — validé |

---

## 3. Affichage

| Question | Contexte | Suggestion |
|----------|----------|------------|
| **Mode d’affichage** (`display`) | `standalone` = sans barre d’URL du navigateur, comme une app ; `minimal-ui` = barre minimale ; `browser` = onglet classique. | ✅ **standalone** (validé) |

---

## 4. Icônes (déjà en place)

Les icônes **192×192** et **512×512** avec fond sont en `public/icons/`. On les référencera ainsi dans le manifest :

- `/icons/icon-192.png` (sizes `192x192`, type `image/png`, purpose `any` et `maskable`)
- `/icons/icon-512.png` (sizes `512x512`, type `image/png`, purpose `any` et `maskable`)

Aucune question ouverte si tu valides ces chemins.

---

## 5. Layout

| Question | Contexte | Suggestion |
|----------|----------|------------|
| **Lien manifest** | À ajouter dans le `<head>` de `application.html.erb`. | `<link rel="manifest" href="<%= pwa_manifest_path %>" />` (route déjà activée) |
| **Meta theme-color** | Même couleur que `theme_color` du manifest. | `<meta name="theme-color" content="#007bff" />` (à aligner avec ta réponse § 2) |

---

## 6. Récap – Réponses à me donner

Pour qu’on puisse écrire le manifest et le layout sans ambiguïté, tu peux répondre ainsi (copier-coller et modifier) :

```
name:            Grenoble Roller  (ou autre)
short_name:      GR Roller  (ou autre)
description:     [reprendre la meta du site / ou phrase courte]
theme_color:     #007bff  (ou autre)
background_color: #007bff  ou  #f8f9fa
display:         standalone  (ou minimal-ui / browser)
```

Dès que tu as rempli ce récap (même en validant les suggestions), on met à jour `manifest.json.erb` et `application.html.erb` en conséquence.
