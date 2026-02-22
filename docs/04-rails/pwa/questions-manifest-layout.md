# PWA – Questions pour le manifest et le layout

**PWA validée** (installabilité Chrome testée ; SW + mise à jour auto en place).

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

---

## 7. État final

| Élément | Statut |
|--------|--------|
| Nom, short_name, description | ✅ Validés et appliqués |
| theme_color, background_color | ✅ Validés et appliqués |
| display (standalone) | ✅ Validé et appliqué |
| Icônes 192 / 512 | ✅ En place et référencées dans le manifest |
| Lien manifest + meta theme-color | ✅ Ajoutés dans le layout |
| **Test d’installation (Chrome)** | ✅ Logo installé, PWA fonctionnelle |
| Service worker | ✅ Enregistré dans application.js ; SW install/activate (skipWaiting + claim) |
| Mises à jour PWA | ✅ Vérification toutes les 60 s ; rechargement auto quand un nouveau SW est actif |

---

## 8. Mises à jour de l’app (mobile, desktop)

**Ce n’est pas une mise à jour « en direct »** (pas de push vers tous les appareils). Comportement actuel :

- **À la prochaine visite** : dès qu’un utilisateur ouvre la PWA ou rafraîchit la page, le navigateur récupère le nouveau service worker (si tu as redéployé). Avec `skipWaiting()` dans le SW, la nouvelle version prend la main tout de suite.
- **Si l’app est déjà ouverte** : le script appelle `reg.update()` toutes les 60 secondes. Si une nouvelle version du SW est en ligne, elle s’installe et s’active ; l’événement `controllerchange` déclenche un **rechargement automatique** de la page, donc l’utilisateur voit la nouvelle version sans quitter l’app.

En résumé : après un déploiement, les mobiles et autres appareils ont la nouvelle version **au prochain lancement ou rafraîchissement**, ou **sous ~60 s** si la PWA est ouverte.
