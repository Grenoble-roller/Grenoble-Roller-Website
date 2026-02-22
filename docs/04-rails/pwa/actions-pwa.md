# PWA – Comparaison projet / doc et actions à faire

Comparaison entre l’état actuel du projet Grenoble Roller, les exigences PWA (MDN, web.dev, Chrome) et la doc Rails 8, puis liste d’actions pour rendre le site installable en PWA.

---

## 1. Références

| Source | Contenu utile |
|--------|----------------|
| **Rails 8** | `Rails::PwaController` intégré ; vues dans `app/views/pwa/` ; routes à activer dans `routes.rb`. |
| **MDN – Making PWAs installable** | HTTPS, manifest (name, short_name, icons 192+512, start_url, display), lien manifest dans le HTML. |
| **web.dev – Service workers** | Optionnel pour installabilité ; utile pour cache / offline. |
| **Projet** | [conformite-2026.md](conformite-2026.md) : critères 2025–2026, écarts, impact déploiement. |

---

## 2. Comparaison projet vs exigences PWA

### 2.1 Manifest (obligatoire pour installabilité)

| Exigence | Doc / standard | Projet actuel | Action |
|----------|-----------------|---------------|--------|
| Fichier manifest valide | JSON avec name, short_name, icons, start_url, display | `app/views/pwa/manifest.json.erb` existe mais **générique** ("App", "red", "/icon.png") | Adapter le contenu (nom, couleurs, URLs d’icônes). |
| Icônes 192×192 et 512×512 | Chrome / web.dev | Manifest pointe vers `/icon.png` ; projet a `public/icon.svg` uniquement | Ajouter (ou générer) icon 192 et 512, exposer en `/icons/` ou `public/`. |
| Servi en HTTPS | Obligatoire | Routes PWA **commentées** → pas de URL manifest | Décommenter les routes PWA. |
| Lien dans le HTML | `<link rel="manifest" href="...">` sur les pages | **Absent** dans `application.html.erb` | Ajouter le lien + `theme-color`. |

### 2.2 Layout et meta

| Exigence | Doc / standard | Projet actuel | Action |
|----------|----------------|---------------|--------|
| Viewport | Recommandé | Présent | Rien. |
| theme-color | Recommandé (barre de statut) | Absent | Ajouter `<meta name="theme-color" content="...">`. |
| apple-mobile-web-app-capable | iOS | Présent | Rien. |

### 2.3 Service worker (optionnel pour installabilité)

| Exigence | Doc / standard | Projet actuel | Action |
|----------|----------------|---------------|--------|
| Fichier SW servi | Recommandé pour offline/cache | `app/views/pwa/service-worker.js` existe, route **commentée** | Décommenter la route. |
| Enregistrement côté client | `navigator.serviceWorker.register(...)` | **Absent** dans `app/javascript/application.js` | Ajouter l’enregistrement au chargement de l’app. |
| Contenu du SW | Cache / offline (optionnel) | Squelette vide (push commenté) | Optionnel : garder squelette ou ajouter cache basique. |

### 2.4 Rails 8

| Élément | Doc Rails 8 | Projet | Action |
|---------|-------------|--------|--------|
| Contrôleur | `Rails::PwaController` (#manifest, #service_worker) | Routes pointent vers `rails/pwa#manifest` / `rails/pwa#service_worker` (commentées) | Décommenter ; si 404, créer `PwaController` et adapter les routes. |
| Vues | `app/views/pwa/manifest.json.erb`, `service-worker.js` | Présentes | Adapter manifest ; SW peut rester minimal. |

---

## 3. Checklist d’actions (ordre recommandé)

### Obligatoire pour “installable”

- [ ] **Routes** : décommenter dans `config/routes.rb` :
  - `get "manifest" => "rails/pwa#manifest", as: :pwa_manifest`
  - `get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker`
- [ ] **Manifest** : modifier `app/views/pwa/manifest.json.erb` :
  - `name` : "Grenoble Roller"
  - `short_name` : "GR Roller" (ou court)
  - `description` : phrase type “Communauté roller Grenoble…”
  - `theme_color` / `background_color` : couleurs du site (pas "red")
  - `icons` : au moins deux entrées avec `src` pointant vers des URLs réelles (192×192 et 512×512), type `image/png`, `sizes` et si possible `purpose: "any"` et `"maskable"`
- [ ] **Icônes** : avoir au moins un fichier 512×512 et un 192×192 (ex. `public/icons/icon-192.png`, `public/icons/icon-512.png`) et les référencer dans le manifest. **Recommandation** : icônes avec **fond opaque** (voir § 5).
- [ ] **Layout** : dans `app/views/layouts/application.html.erb` (dans le `<head>`) :
  - `<link rel="manifest" href="<%= pwa_manifest_path %>" />` (ou `url_for` équivalent)
  - `<meta name="theme-color" content="#XXXXXX" />` (même couleur que `theme_color` du manifest)

### Recommandé (fiabilité / UX)

- [ ] **Service worker** : dans `app/javascript/application.js` (après chargement du DOM ou au top-level), enregistrer le SW :
  - `if ('serviceWorker' in navigator) { navigator.serviceWorker.register('/service-worker').catch(console.error); }`
  - Vérifier que l’URL correspond à la route (ex. `/service-worker` sans `.js` si la route est ainsi).
- [ ] **Tester** : en HTTPS (ou localhost), Chrome DevTools > Application > Manifest + onglet “Install” / Lighthouse > PWA.

### Optionnel

- [ ] Cache basique dans le service worker (shell ou assets critiques).
- [ ] Screenshots / description enrichie dans le manifest pour l’UI d’installation.
- [ ] Ne pas définir `prefer_related_applications: true` (ou l’omettre).

---

## 4. Résumé

| Bloc | À faire |
|------|--------|
| **Routes** | Décommenter manifest + service-worker. |
| **Manifest** | Nom, description, couleurs, icônes 192+512 (fichiers + entrées dans le JSON). |
| **Layout** | Lien manifest + meta theme-color. |
| **SW** | Enregistrement dans application.js ; optionnellement contenu de cache. |

Une fois ces points faits, le site sera éligible à l’installation PWA (bouton “Installer” dans Chrome / Edge, etc.). Le déploiement (Kamal ou scripts `ops/`) n’a pas besoin d’être modifié : manifest et service worker sont servis par Rails comme le reste de l’app.

Voir aussi : [conformite-2026.md](conformite-2026.md) pour les détails critères 2025–2026 et impact déploiement.

---

## 5. Bonnes pratiques – Icônes PWA (fond opaque / maskable)

### Pourquoi un fond opaque ?

- **Icônes transparentes** : sur Android 8+ et certains launchers, les zones transparentes sont remplacées par un fond (souvent blanc) dont le rendu varie selon l’appareil et le navigateur.
- **Icônes maskable** (recommandé) : l’icône doit **remplir tout le carré** avec un **fond opaque**. Le logo/contenu important doit rester dans la **safe zone** : cercle au centre d’environ **80 %** de la taille (les ~10 % de marge sur chaque bord peuvent être rognés selon la forme affichée : cercle, squircle, etc.).

Références : [web.dev – Maskable icons](https://developer.chrome.com/docs/capabilities/maskable-icon), [Maskable.app](https://maskable.app/) pour prévisualiser et générer.

### Comment obtenir des icônes avec fond

1. **Même visuel que le favicon** (logo Grenoble Roller), en PNG **192×192** et **512×512**, avec un **fond plein** (couleur du site, ex. bleu primaire `#007bff`).
2. **Génération** :
   - **Option A** : script fourni dans le projet (nécessite ImageMagick) : `scripts/generate-pwa-icons.sh` — part du favicon, ajoute un fond bleu, centre le logo et respecte la safe zone.
   - **Option B** : outil en ligne [Maskable.app Editor](https://maskable.app/editor) — upload du logo, réglage du fond et du padding, export 192 et 512.
3. Placer les fichiers dans `public/icons/` (ex. `icon-192.png`, `icon-512.png`) et les référencer dans le manifest avec `purpose: "any"` et `purpose: "maskable"` (ou une seule entrée `"any maskable"`).
