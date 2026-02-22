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
| Bannière d’installation (mobile) | ✅ Bannière « Installer » sur mobile (Chrome : beforeinstallprompt ; iOS : instructions). Délai 2 s, rappel après 7 j si « Plus tard ». |

---

## 8. Mises à jour de l’app (mobile, desktop)

**Ce n’est pas une mise à jour « en direct »** (pas de push vers tous les appareils). Comportement actuel :

- **À la prochaine visite** : dès qu’un utilisateur ouvre la PWA ou rafraîchit la page, le navigateur récupère le nouveau service worker (si tu as redéployé). Avec `skipWaiting()` dans le SW, la nouvelle version prend la main tout de suite.
- **Si l’app est déjà ouverte** : le script appelle `reg.update()` toutes les 60 secondes. Si une nouvelle version du SW est en ligne, elle s’installe et s’active ; l’événement `controllerchange` déclenche un **rechargement automatique** de la page, donc l’utilisateur voit la nouvelle version sans quitter l’app.

En résumé : après un déploiement, les mobiles et autres appareils ont la nouvelle version **au prochain lancement ou rafraîchissement**, ou **sous ~60 s** si la PWA est ouverte.

---

## 9. Conditions d’installation et détection « déjà installé »

### 9.1 Quand le navigateur propose l’installation (critères installabilité)

Le navigateur (Chrome, Edge, etc.) considère la PWA **installable** si :

| Critère | Détail |
|--------|--------|
| **HTTPS** | Site servi en HTTPS (ou localhost en dev). |
| **Manifest** | Valide, avec `name` ou `short_name`, `start_url`, `display` (standalone / minimal-ui / etc.), icônes **192×192** et **512×512**. Pas de `prefer_related_applications: true`. |
| **Service worker** | Enregistré et qui contrôle la page et la `start_url` (Chrome peut assouplir selon les versions). |
| **Engagement utilisateur** | Souvent : au moins **~30 s** sur la page **et** au moins **un clic/tap** (critères heuristiques du navigateur). |

Quand tout est OK, le navigateur peut émettre **`beforeinstallprompt`** (Chrome/Edge) et/ou afficher sa propre UI « Installer ». Sur **iOS Safari**, il n’y a pas d’API : l’utilisateur doit utiliser **Partager > Sur l’écran d’accueil**.

### 9.2 Vérification « déjà installé » (dans notre bannière)

Pour **ne pas afficher** la bannière « Installer » si l’app est déjà installée, on utilise :

| Méthode | Utilisation dans le projet |
|--------|-----------------------------|
| **`display-mode: standalone`** | `window.matchMedia("(display-mode: standalone)").matches` — **true** quand l’utilisateur a ouvert la PWA depuis l’icône (mode standalone). |
| **`navigator.standalone`** | **iOS Safari** uniquement : `true` quand la page est ouverte depuis l’écran d’accueil. |

Si l’une des deux est vraie, on considère « déjà installé » et on **n’affiche pas** la bannière (voir `pwa_install_controller.js` → `#isAlreadyInstalled()`).

**Limite** : ces tests indiquent que l’app est **ouverte en mode app** à l’instant T. Ils ne disent pas si l’utilisateur a « installé » puis rouvre le site **dans l’onglet du navigateur** : dans ce cas `display-mode` n’est pas `standalone`, donc la bannière peut réapparaître. C’est le comportement habituel (on propose d’installer tant qu’il n’est pas en standalone).

**Option avancée** : l’API **`navigator.getInstalledRelatedApps()`** (Chrome Android, support limité) peut indiquer si une app liée (dont la PWA) est installée, même quand on est en navigation « onglet ». On ne l’utilise pas encore dans le projet ; on peut l’ajouter plus tard pour affiner (ex. ne plus proposer l’install si l’app est déjà dans la liste).
