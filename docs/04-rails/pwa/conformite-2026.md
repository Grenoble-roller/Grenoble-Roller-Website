# PWA – Conformité 2026 et modifications à prévoir

Document d’étude : passage de l’application Grenoble Roller en PWA conforme aux attentes 2025–2026, écarts actuels et plan de modifications. Impact sur le déploiement (Kamal vs scripts `ops/`).

---

## 1. Contexte PWA et critères 2025–2026

### 1.1 Définition

Une **Progressive Web App (PWA)** est une application web qui :

- Peut être **installée** sur l’appareil (écran d’accueil, menu applications).
- Est servie en **HTTPS**.
- Expose un **manifest** (nom, icônes, `start_url`, `display`, etc.).
- Optionnellement utilise un **service worker** (hors ligne, cache, push).

### 1.2 Critères d’installabilité (Chrome / web.dev, 2024–2025)

Pour que le navigateur propose l’installation (bouton “Installer”, `beforeinstallprompt`) :

| Critère | Détail |
|--------|--------|
| **HTTPS** | Application servie uniquement en HTTPS. |
| **Manifest** | Fichier manifest valide avec : |
| | • `name` ou `short_name` |
| | • `icons` : au moins **192×192** et **512×512** |
| | • `start_url` |
| | • `display` : `fullscreen`, `standalone`, `minimal-ui` ou `window-controls-overlay` |
| | • `prefer_related_applications` absent ou `false` |
| **Engagement utilisateur** | Au moins un clic/tap + ~30 s sur la page (heuristiques navigateur). |

**Service worker** : **non obligatoire** pour l’installabilité (Chrome 2024+), mais recommandé pour expérience hors ligne et fiabilité.

**Références** : [web.dev – Install criteria](https://web.dev/articles/install-criteria), [MDN – Making PWAs installable](https://developer.mozilla.org/en-US/docs/Web/Progressive_web_apps/Guides/Making_PWAs_installable).

### 1.3 Bonnes pratiques 2025–2026

- Lien `<link rel="manifest" href="...">` sur toutes les pages concernées.
- Meta `theme-color` et `apple-mobile-web-app-capable` déjà utiles (déjà partiellement présents).
- Icône **maskable** (safe zone) pour Android.
- Optionnel : `screenshots` et `description` dans le manifest pour une meilleure UI d’installation.
- Service worker : au minimum enregistrement + cache de base (shell / assets critiques) si on vise “installable + fiable”.

---

## 2. État actuel de l’application

### 2.1 Fichiers PWA existants (Rails 8)

| Élément | Emplacement | Statut |
|--------|------------|--------|
| **Manifest** | `app/views/pwa/manifest.json.erb` | Existe mais **générique** (name: "App", theme_color: "red"). |
| **Service worker** | `app/views/pwa/service-worker.js` | Existe, **vide** (push commenté). |
| **Routes** | `config/routes.rb` | **Commentées** : `get "manifest"`, `get "service-worker"`. |

### 2.2 Layout et meta

- **application.html.erb** : `viewport`, `apple-mobile-web-app-capable`, `mobile-web-app-capable` présents.
- **Aucun** `<link rel="manifest" ...>`.
- **Aucun** `theme-color` dédié PWA.

### 2.3 Icônes

- **app/assets/images/favicon-512.png** : 512×512 (utilisé comme favicon / apple-touch-icon).
- **public/icon.png** : présent (utilisé par le manifest actuel en `/icon.png`).
- **Manque** : icône **192×192** explicite pour le manifest (exigence Chrome).

### 2.4 HTTPS et déploiement

- **Production** : Caddy + Let’s Encrypt (HTTPS) → **OK** pour PWA.
- **Staging** : à vérifier selon config (HTTPS recommandé pour tester l’installabilité).

### 2.5 Synthèse conformité actuelle

| Critère PWA | État |
|-------------|------|
| HTTPS | OK (production). |
| Manifest avec name, short_name, icons 192+512, start_url, display | Partiel : fichier présent mais routes désactivées, contenu à adapter (nom, couleurs, icônes). |
| Lien manifest dans le HTML | Manquant. |
| Icône 192×192 | À ajouter / déclarer. |
| Service worker | Fichier présent, routes désactivées ; optionnel pour installabilité. |
| theme-color | À ajouter dans le layout. |

---

## 3. Modifications à prévoir

### 3.1 Routes PWA

- **Décommenter** dans `config/routes.rb` :
  - `get "manifest" => "rails/pwa#manifest", as: :pwa_manifest`
  - `get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker`
- Vérifier que le contrôleur Rails PWA par défaut (Rails 8) sert bien ces vues ; sinon, ajouter un contrôleur minimal qui rend `app/views/pwa/manifest.json.erb` et `service-worker.js` avec les bons content-types.

### 3.2 Manifest (`app/views/pwa/manifest.json.erb`)

- **name** : `"Grenoble Roller"`.
- **short_name** : `"GR Roller"` (ou équivalent court).
- **description** : reprise de la meta description du site (communauté roller Grenoble, événements, etc.).
- **start_url** : `"/"`.
- **scope** : `"/"`.
- **display** : `"standalone"` (recommandé pour une app type “site associatif”).
- **theme_color** : couleur principale du site (ex. `"#0d6efd"` ou la couleur “liquid” du thème).
- **background_color** : couleur de fond au lancement (ex. `"#ffffff"`).
- **icons** :
  - Au moins une entrée **192×192** et une **512×512**.
  - Une icône avec `"purpose": "maskable"` pour Android (512×512 avec safe zone).
- Ne pas mettre `prefer_related_applications: true` (sinon Chrome peut rediriger vers le Play Store).
- Optionnel : `screenshots`, `categories` pour une meilleure UI d’installation.

### 3.3 Icônes

- **192×192** : générer à partir de `favicon-512.png` (redimensionnement) et la placer en `public/` ou dans les assets, puis la référencer dans le manifest (URL absolue ou chemin public).
- **512×512** : déjà disponible (`/icon.png` ou asset favicon-512) ; s’assurer qu’une version maskable (safe zone) existe ou utiliser la même avec `purpose: "maskable"`.
- Garder **public/icon.png** (ou équivalent) pour que le manifest pointe vers des URLs stables (ex. `/icons/icon-192.png`, `/icons/icon-512.png`).

### 3.4 Layout (`app/views/layouts/application.html.erb`)

- Ajouter : `<link rel="manifest" href="<%= pwa_manifest_path %>" />` (après les favicons, dans le `<head>`).
- Ajouter : `<meta name="theme-color" content="#COULEUR_PRINCIPALE" />` (cohérent avec `theme_color` du manifest).
- Pour le layout **admin** : optionnel d’ajouter aussi le lien manifest si on souhaite que l’admin soit installable ; en général on ne lie le manifest que sur le layout public.

### 3.5 Service worker (optionnel mais recommandé)

- **Décommenter / activer** la route `service-worker`.
- Contenu minimal recommandé :
  - Enregistrement depuis la page (Rails 8 peut le faire via un script ou une gem).
  - Cache statique pour le shell (HTML de base, CSS/JS principaux) en “cache first” ou “stale-while-revalidate”.
  - Ne pas mettre en cache les réponses dynamiques sensibles (session, API) ou utiliser une stratégie “network first”.
- Le fichier actuel `app/views/pwa/service-worker.js` peut rester un squelette (sans push) dans un premier temps ; l’important est qu’il soit servi et enregistrable (pas d’erreur 404).
- S’assurer que le service worker est servi en **HTTPS** et que son scope est cohérent avec `scope` du manifest.

### 3.6 Contrôleur Rails PWA (si nécessaire)

Les routes commentées dans le projet pointent vers `rails/pwa#manifest` et `rails/pwa#service_worker` (support PWA intégré à Rails 8). Si, après décommentage, ces routes ne sont pas reconnues (contrôleur absent dans la version utilisée) :

- Créer un contrôleur (ex. `PwaController`) avec deux actions qui rendent les vues `app/views/pwa/manifest.json.erb` et `app/views/pwa/service-worker.js` avec les content-types :
  - `application/manifest+json` pour le manifest ;
  - `application/javascript` pour le service worker.
- Adapter les routes pour pointer vers ce contrôleur (ex. `get "manifest" => "pwa#manifest"`).

### 3.7 Checklist de mise en œuvre

- [ ] Décommenter les routes manifest et service-worker (ou les pointer vers un contrôleur dédié).
- [ ] Adapter `app/views/pwa/manifest.json.erb` (nom, couleurs, icônes 192+512, display, pas de `prefer_related_applications`).
- [ ] Ajouter une icône 192×192 et la référencer dans le manifest.
- [ ] Ajouter `<link rel="manifest" ...>` et `<meta name="theme-color" ...>` dans le layout principal.
- [ ] (Optionnel) Implémenter un cache basique dans le service worker et l’enregistrer côté client.
- [ ] Tester l’installabilité : Chrome DevTools > Application > Manifest + “Install” / Lighthouse PWA.

---

## 4. Impact sur le déploiement (Kamal vs scripts `ops/`)

### 4.1 Conclusion courte

**La PWA ne impose pas de changer d’outil de déploiement.** Que l’on déploie avec **Kamal** ou avec les **scripts `ops/`** (Docker Compose + Caddy), les changements sont uniquement dans l’application Rails (fichiers, routes, vues, layout). Le serveur continue à servir HTML, JS, CSS et désormais le manifest et le service worker comme des URLs de l’app.

### 4.2 Pourquoi aucun impact sur le choix Kamal vs script ?

- **Manifest** et **service worker** sont servis par Rails (routes → vues ou contrôleur). Ils passent par le même reverse proxy (Caddy avec `ops/`, ou proxy Kamal) que le reste de l’app.
- **HTTPS** : déjà géré en production (Caddy + Let’s Encrypt dans `ops/production`). Avec Kamal, le proxy gère aussi le SSL. Aucune contrainte PWA spécifique au-delà de “tout en HTTPS”.
- **Cache / headers** : si on veut des headers particuliers pour le manifest ou le service worker (ex. pas de cache agressif pour le SW), on peut les configurer soit dans Rails (headers dans le contrôleur), soit dans Caddy / Kamal proxy. Les deux chaînes de déploiement le permettent.
- **Assets (icônes)** : servis comme aujourd’hui (public ou asset pipeline). Aucun changement d’infra.

### 4.3 Points à garder en tête selon l’environnement

- **Scripts `ops/` (Docker Compose + Caddy)** : rien à modifier dans la chaîne de déploiement pour activer la PWA. Après déploiement, l’app exposera simplement deux URLs de plus (`/manifest`, `/service-worker`) tant que les routes et vues sont en place.
- **Kamal** : idem. Les secrets et variables (ex. `RAILS_MASTER_KEY`) restent les mêmes ; aucun nouveau service ni étape de build spécifique PWA. Si un jour on ajoute un cache CDN devant l’app, il faudra s’assurer de ne pas cacher le service worker de manière trop agressive (pour les mises à jour).

### 4.4 Recommandation

- Conserver la stratégie de déploiement actuelle (Kamal ou `ops/`) sans la modifier pour la PWA.
- Faire la conformité PWA côté code (manifest, icônes, layout, optionnellement service worker), puis déployer comme d’habitude.
- Après déploiement, vérifier en production que `https://<domaine>/manifest` et `https://<domaine>/service-worker` répondent correctement et que Lighthouse PWA / Chrome “Install” fonctionnent.

---

## 5. Références

- [web.dev – What does it take to be installable?](https://web.dev/articles/install-criteria)
- [MDN – Progressive Web Apps (PWA)](https://developer.mozilla.org/en-US/docs/Web/Progressive_web_apps)
- [MDN – Web app manifest](https://developer.mozilla.org/en-US/docs/Web/Progressive_web_apps/Manifest)
- [web.dev – Service workers](https://web.dev/learn/pwa/service-workers)
- Rails 8 : génération PWA par défaut (`app/views/pwa/`, routes commentées dans le projet).

---

*Dernière mise à jour : 2026-01 (étude initiale PWA 2026).*
