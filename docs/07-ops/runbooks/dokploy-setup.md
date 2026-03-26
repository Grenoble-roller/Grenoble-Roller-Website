---
title: "Déploiement Dokploy (staging & production)"
status: "active"
version: "0.7"
created: "2026-03-26"
updated: "2026-03-27"
authors: ["FlowTech Lab"]
tags: ["dokploy", "deployment", "docker", "staging", "production"]
---

# Déploiement Dokploy — staging & production

Document **vivant** : à compléter au fil des choix d’architecture et de la mise en place réelle sur Dokploy. Ne pas inventer de procédures non vérifiées sur la plateforme : chaque section marquée *À valider* doit être mise à jour après test.

---

## 1. Objectif

Déployer **Grenoble Roller** (Rails 8, Docker) sur **Dokploy** pour **staging** et **production**, avec un fonctionnement équivalent aux capacités actuelles (app, Postgres, stockage type S3/MinIO, HTTPS, jobs/cron, migrations).

Référence historique du modèle actuel (VPS + scripts) : [staging-setup.md](./staging-setup.md), [production-setup.md](./production-setup.md), [deploy-vps.md](../deploy-vps.md).

---

## 2. Ce qu’on sait déjà (état du dépôt)

- **Image applicative** : build via le [`Dockerfile`](../../../Dockerfile) à la racine (Ruby 3.4.2, multi-stage, `assets:precompile` sans `RAILS_MASTER_KEY` au build, Puma, port 3000 par défaut).
- **Modèle staging/prod actuel** : Docker Compose dans [`ops/staging/docker-compose.yml`](../../../ops/staging/docker-compose.yml) et [`ops/production/docker-compose.yml`](../../../ops/production/docker-compose.yml) — **web + PostgreSQL + MinIO** ; la prod ajoute **Caddy** (TLS).
- **Orchestration actuelle sur serveur** : [`ops/deploy.sh`](../../../ops/deploy.sh) + [`ops/config/staging.env`](../../../ops/config/staging.env) / [`ops/config/production.env`](../../../ops/config/production.env) (git pull, backup, build, migrations, health checks, maintenance, crontab via Whenever → fichier consommé par Supercronic dans l’image). Voir [`ops/README.md`](../../../ops/README.md).
- **Branches** : staging → branche `staging` ; production → branche `main` (voir fichiers `*.env` ci-dessus). **Dokploy (Q2)** : **une application Git par environnement**, chacune suivant **sa branche** (`staging` vs `main`) — aligné avec [`ops/config/staging.env`](../../../ops/config/staging.env) / [`production.env`](../../../ops/config/production.env). *Variante observée sur Dokploy* : **plusieurs environnements** (prod, staging, test, …) **dans le même projet**, puis ajout des **services** nécessaires par environnement — équivalent fonctionnel si chaque env a sa propre branche / ses propres secrets ; détail et cartographie **§3.1–3.4**.
- **CI GitHub** : [`.github/workflows/ci.yml`](../../../.github/workflows/ci.yml) — qualité sur PR / `main`, **sans** déploiement Dokploy aujourd’hui.
- **Piste parallèle** : le projet est aussi **Kamal-ready** ([`config/deploy.yml`](../../../config/deploy.yml), gem Kamal) — orthogonal à Dokploy ; ne pas confondre les procédures.

---

## 3. Fichiers et dossiers utiles (liens relatifs depuis ce runbook)

| Rôle | Chemin |
|------|--------|
| Image prod | [`Dockerfile`](../../../Dockerfile) |
| Ignore build | [`.dockerignore`](../../../.dockerignore) |
| Entrée conteneur | [`bin/docker-entrypoint`](../../../bin/docker-entrypoint) |
| Compose staging | [`ops/staging/docker-compose.yml`](../../../ops/staging/docker-compose.yml) |
| Compose production | [`ops/production/docker-compose.yml`](../../../ops/production/docker-compose.yml) |
| Config déploiement scripts | [`ops/config/staging.env`](../../../ops/config/staging.env), [`ops/config/production.env`](../../../ops/config/production.env) |
| Script orchestrateur | [`ops/deploy.sh`](../../../ops/deploy.sh) |
| Doc ops racine | [`ops/README.md`](../../../ops/README.md) |
| Caddy (prod actuelle) | [`ops/production/Caddyfile`](../../../ops/production/Caddyfile) |
| Credentials Rails | [`docs/04-rails/setup/credentials.md`](../../04-rails/setup/credentials.md) |
| Connexion DB | [`config/database.yml`](../../../config/database.yml) |
| Active Storage / MinIO | [`config/storage.yml`](../../../config/storage.yml) |
| Env production Rails | [`config/environments/production.rb`](../../../config/environments/production.rb) |

### 3.1 Environnements Dokploy et services

Sur Dokploy, le fonctionnement observé est : **un projet** peut contenir **plusieurs environnements** (ex. production, staging, test), et pour chaque environnement on **ajoute les services** dont il a besoin (base, stockage objet, application, etc.).

À faire correspondre avec le dépôt :

- **Objectif** : retrouver l’équivalent de [`ops/staging/docker-compose.yml`](../../../ops/staging/docker-compose.yml) / [`ops/production/docker-compose.yml`](../../../ops/production/docker-compose.yml) : **même filaire logique** (qui parle à qui), **noms d’hôte internes** et **variables** adaptés à ce que Dokploy injecte (souvent différents de `db` / `minio` en pur Compose — *à noter après configuration réelle*).

### 3.2 Services montés **en plus de `web`** dans Compose

| Compose | Service | Image / rôle | Dépend de | Notes pour Dokploy |
|---------|---------|--------------|-----------|-------------------|
| **Staging** | `db` | `postgres:16-alpine` | — | Postgres **16** ; volume données ; health `pg_isready`. |
| **Staging** | `minio` | `minio/minio` | — | API **9000**, console **9001** (interne en Compose). |
| **Staging** | `web` | build `Dockerfile` | `db`, `minio` | App Rails ; `env_file` `.env` possible. |
| **Production** | `db` | idem staging | — | Idem ; pas de port publié vers l’hôte. |
| **Production** | `minio` | idem | — | Idem. |
| **Production** | `web` | idem | `db`, `minio` | + `RAILS_MASTER_KEY`, option montage `master.key`. |
| **Production** | `caddy` | `caddy:2-alpine` | `web` healthy | TLS **80/443** + [`Caddyfile`](../../../ops/production/Caddyfile). **Sur Dokploy**, le rôle de Caddy est en principe **assumé par Traefik / la couche proxy** : **pas de service Caddy séparé** sauf choix explicite. |

**Filaire réseau actuel (Compose)** : seul `web` doit joindre `db:5432` et **`minio:9000`** (endpoint style S3). Les noms **`db`** et **`minio`** sont les **hostnames DNS** du réseau Compose ; sous Dokploy, reporter la même logique avec les **hostnames internes** fournis par la plateforme (à documenter ici une fois connus).

### 3.3 Variables d’environnement **hors** credentials chiffrés

Les secrets Rails chiffrés vivent dans `config/credentials*.yml.enc` et nécessitent **`RAILS_MASTER_KEY`** (voir **§3.4**). Le tableau ci-dessous liste surtout ce qui est déjà posé en **variables d’environnement** dans Compose ou en **fallback ENV** dans le code — utile pour remplir Dokploy (souvent : secrets sensibles dans l’UI « Secrets », le reste en « Environment »).

| Variable (exemples) | Utilisation dans le projet | Typique Dokploy |
|---------------------|----------------------------|-----------------|
| `DATABASE_URL` | [`config/database.yml`](../../../config/database.yml) (`production`) | **Secret** (contient user + mot de passe). Host/port doivent viser le **service Postgres** de l’environnement. |
| `DATABASE_HOST`, `DATABASE_PORT`, `DATABASE_USER`, `DATABASE_PASSWORD`, `DATABASE_NAME` | Si pas seulement `DATABASE_URL` | Mot de passe = **secret** ; le reste peut être non secret selon politique. |
| `RAILS_ENV` | En Compose staging/prod : `production` | Non secret ; **identique** sur les deux stacks Compose actuels (Rails « production » même pour staging Docker). |
| `APP_ENV`, `DEPLOY_ENV` | Staging vs prod sémantique, CORS ([`config/initializers/cors.rb`](../../../config/initializers/cors.rb)) | Non secret : ex. `staging` / `production`. |
| `MAILER_HOST`, `MAILER_PROTOCOL` | Liens dans les emails ([`config/environments/production.rb`](../../../config/environments/production.rb)) | Non secret : domaine public (ex. `grenoble-roller.org`, URL staging). |
| `PORT` | Puma (souvent `3000` dans l’image) | Non secret ; aligner avec ce que Dokploy attend derrière Traefik. |
| `TZ` | Fuseau | Ex. `Europe/Paris`. |
| `SOLID_QUEUE_IN_PUMA` | [`config/puma.rb`](../../../config/puma.rb) — Solid Queue dans Puma | Ex. `"true"` pour le modèle single-process actuel. |
| `RAILS_FORCE_SSL` | Compose prod (derrière proxy) | Optionnel selon proxy ; `production.rb` force déjà SSL côté Rails. |
| `RAILS_LOG_LEVEL` | [`production.rb`](../../../config/environments/production.rb) | Optionnel (`info` par défaut). |
| `MINIO_ENDPOINT` | [`config/storage.yml`](../../../config/storage.yml) service `:minio` | URL **interne** vers MinIO (ex. `http://minio:9000` en Compose) — souvent non secret ; **hostname à adapter** sous Dokploy. |
| `MINIO_ACCESS_KEY_ID`, `MINIO_SECRET_ACCESS_KEY` | `storage.yml` — **priorité sur** les clés `:minio` des credentials | **Secrets** si utilisés (souvent alignés sur `MINIO_ROOT_USER` / `MINIO_ROOT_PASSWORD` du conteneur MinIO). |
| `MINIO_ROOT_USER`, `MINIO_ROOT_PASSWORD` | Conteneur **MinIO** (serveur), pas Rails directement | **Secrets** du service MinIO. |

**Déjà dans les credentials chiffrés** (via `Rails.application.credentials.dig(...)` — pas à dupliquer en clair dans le repo) : notamment **SMTP** (`user_name`, `password`, `address`, `port`, `domain` dans [`production.rb`](../../../config/environments/production.rb)), et les clés **MinIO** si tu **ne** passes **pas** par `MINIO_*` en ENV. Référence : [credentials.md](../../04-rails/setup/credentials.md).

*Point d’attention* : dans [`config/storage.yml`](../../../config/storage.yml), le bucket est `grenoble-roller-<%= Rails.env %>`. Avec `RAILS_ENV=production` pour **staging et prod** en Docker, le **nom de bucket** est le même (`grenoble-roller-production`). Pour **isoler** staging et prod sur MinIO, prévoir soit **deux instances** MinIO, soit **surcharge** (credentials / évolution config) — *à trancher avec §5.1 / choix infra*.

### 3.4 `RAILS_MASTER_KEY` — rôle et bonnes pratiques

- **Rôle** : permet à Rails de déchiffrer **`config/credentials.yml.enc`** (et fichiers credentials d’environnement s’il y en a). Sans elle, l’app ne lit pas SMTP, clés API éventuelles dans les credentials, etc.
- **Bonnes pratiques sur Dokploy** : définir **`RAILS_MASTER_KEY`** comme **secret** dans **chaque environnement** (staging, prod, test) concerné — **pas** de commit dans Git ; éviter de la coller dans des logs.
- **Alternative observée en Compose prod** : montage du fichier [`config/master.key`](../../../config/master.key) en lecture seule. Fonctionne, mais **moins portable** qu’une variable d’environnement ; sur Dokploy, **préférer le secret `RAILS_MASTER_KEY`** si l’UI le permet.
- **Fichiers** : ne jamais versionner `master.key` ; rotation et procédure : [credentials.md](../../04-rails/setup/credentials.md).

---

## 4. Build Type Dokploy — options et recommandation

Dokploy propose typiquement : **Dockerfile**, Railpack, Nixpacks, Heroku Buildpacks, Paketo Buildpacks, **Static**.

| Option | Pertinence pour ce repo |
|--------|-------------------------|
| **Dockerfile** | **Recommandé** : même pipeline que Compose/Kamal ; contrôle Ruby/Node, gems, `assets:precompile`. |
| Nixpacks / Railpack / Buildpacks | Possible mais **redondant** avec un Dockerfile déjà maintenu ; risque d’écart de versions (Ruby, Node). |
| Static | **Non applicable** (application Rails dynamique). |

**Décision proposée** : utiliser le **Build Type = Dockerfile** et pointer le contexte/build vers la racine du dépôt (où se trouve le `Dockerfile`).

*À valider sur l’UI Dokploy* : chemin du Dockerfile, arguments de build (`BUILD_ID`, etc.). **Build & images (Q3–Q4)** : tout **interne** à Dokploy (serveur de build + déploiement), sans registre externe.

---

## 5. Écarts modèle actuel ↔ Dokploy (à traiter)

| Sujet | Aujourd’hui (Compose + scripts) | Sur Dokploy (à décider) |
|-------|----------------------------------|-------------------------|
| **Code / build** | `git pull` + build sur le serveur VPS | **Build exécuté dans Dokploy** sur l’hôte (Dockerfile), déclenché par webhook / déploiement depuis la branche **`staging`** ou **`main`** — pas d’image poussée depuis une CI externe (Q3) |
| **PostgreSQL** | Service dans le même Compose | DB **managée** Dokploy, **conteneur Postgres** séparé, ou **externe** ? |
| **MinIO / S3** | Service MinIO dans Compose | Service Dokploy dédié, **S3 externe**, ou MinIO sur un autre stack ? |
| **TLS / domaine** | Caddy + Let’s Encrypt en prod | **Proxy / certificats Dokploy** (Traefik) — voir §7 *Réponses* : prod `grenoble-roller.org` ; staging URL Traefik par défaut **ou** sous-domaine dédié |
| **Secrets** | `.env`, `RAILS_MASTER_KEY`, `config/master.key` (montage prod) | **Secrets Dokploy** + variables par environnement — inventaire **§3.3** et **`RAILS_MASTER_KEY`** **§3.4** |
| **Migrations** | `docker exec … bin/rails db:migrate` dans `deploy.sh` | **Commande post-déploiement** Dokploy, job one-shot, ou hook CI |
| **Backups DB** | Scripts `ops/lib/database/` | Politique Dokploy / cron hôte / service externe |
| **Jobs planifiés** | Whenever → fichier + Supercronic dans l’image ; install via `deploy.sh` | **Même image** (un process Supercronic ?) ou **worker** séparé, ou **cron Dokploy** appelant une commande |
| **Solid Queue** | `SOLID_QUEUE_IN_PUMA=true` dans Compose | Conserver **in-process** dans Puma ou **process dédié** (scale horizontal) ? |
| **Health check** | `curl /up` dans Compose | Réutiliser le même **chemin `/up`** dans la config santé Dokploy |

---

## 5.1 PostgreSQL, réseau et `DATABASE_URL` (Q5 — réflexion)

La checklist parle de « même host » : l’important n’est pas l’OS sous-jacent, mais que le **conteneur Rails** puisse joindre **PostgreSQL** sur le **réseau Docker** (ou équivalent) avec une **`DATABASE_URL` correcte**, sans exposer la base sur Internet si on peut l’éviter.

### Référence actuelle (Compose)

Dans [`ops/staging/docker-compose.yml`](../../../ops/staging/docker-compose.yml) et [`ops/production/docker-compose.yml`](../../../ops/production/docker-compose.yml) :

- Service Postgres **16** (`postgres:16-alpine`), hostname de service **`db`**, port **5432** interne.
- Exemple d’URL côté app : `postgresql://postgres:postgres@db:5432/grenoble_roller_production` (mot de passe à remplacer en prod par des secrets forts).
- En **production** Compose, le port Postgres **n’est pas publié** vers l’hôte (accès réseau Docker uniquement) — bon réflexe à conserver.

### Options architecturales (à faire correspondre aux menus Dokploy)

| Option | Description | Intérêt | Points de vigilance |
|--------|-------------|---------|---------------------|
| **A — Postgres « à côté » de l’app sur Dokploy** | Base sur la même infra, réseau interne entre services (équivalent logique à Compose) | Latence faible, pas besoin d’ouvrir 5432 sur Internet | Persistance des données, sauvegardes, nom d’hôte / variables fournis par Dokploy (*à noter après test*) |
| **B — Deux Postgres (staging + prod)** | Une instance (ou un service) par environnement, aligné avec **deux apps** Dokploy | Isolation forte, limite les erreurs de mauvaise base | Consomme plus de ressources sur le serveur |
| **C — Un Postgres, deux bases** | Même serveur Postgres, `DATABASE_URL` différente par env (`…/db_staging` vs `…/db_prod`) | Moins de RAM qu’une instance par env | Risque opérationnel si la même URL est copiée par erreur ; droits utilisateurs à séparer proprement |
| **D — Postgres managé externe** | RDS, Neon, Supabase, autre | Sauvegardes / HA souvent prêts | Latence, coût, **RGPD** (localisation données), `sslmode` / certificats, pare-feu ou allowlist IP |

**Bonnes pratiques** (indépendantes de Dokploy, alignées avec le projet) :

1. **Staging et production** : au minimum **bases et utilisateurs distincts** ; de préférence **isolation** forte (option B ou D avec deux instances / deux URLs).
2. **Secrets** : URL complète ou mot de passe **uniquement** dans les secrets Dokploy — pas dans le dépôt ; voir [credentials.md](../../04-rails/setup/credentials.md).
3. **Ne pas exposer** PostgreSQL sur le réseau public si une alternative réseau interne existe.
4. **Version** : viser **PostgreSQL 16** comme dans les Compose pour limiter les écarts.
5. **Migrations** : une fois `DATABASE_URL` fixée, documenter **qui** exécute `rails db:migrate` et **quand** (lien avec §6 point 5 et ligne « Migrations » du tableau §5).
6. **Sauvegardes** : politique (fréquence, rétention, test de restauration) — croise la question RGPD / backups (checklist §7).

### Ce qu’il reste à écrire dans ce runbook (après exploration Dokploy)

- Hostname ou **nom de service** réel vu depuis le conteneur app.
- **`DATABASE_URL` exacte** (avec placeholders dans la doc, secrets dans Dokploy uniquement).
- Option retenue parmi A/B/C/D (ou hybride).

*Cette section remplace une simple question oui/non : la checklist Q5 ci-dessous sera cochée quand ces éléments seront renseignés.*

---

## 6. Décisions à prendre (arbitrage)

Pour chaque ligne, cocher une option quand elle est **validée en conditions réelles** et mettre à jour ce document.

**Build & images (Q3–Q4)** : **sur l’infra Dokploy** (build + déploiement selon les besoins) — pas de CI externe ni de registre d’images externe (Docker Hub, GHCR) dans le flux nominal.

1. **Un projet Dokploy par environnement** (staging + prod) **vs** un seul projet avec deux “environments” — **retenu** : **deux apps** (ou deux projets) avec **une branche chacune** (`staging` / `main`), confirmé Q2.
2. **Base de données** : Postgres version **16** (alignement [`docker-compose`](../../../ops/staging/docker-compose.yml)) ; **persistance** et **snapshots** à définir — arbitrage détaillé **§5.1** (options A–D, bonnes pratiques).
3. **Stockage fichiers (Active Storage)** : conserver une **API S3-compatible** ; choisir **MinIO** vs **cloud S3** vs autre.
4. **Variables d’environnement minimales** : tableau **§3.3** (et **`RAILS_MASTER_KEY`** **§3.4**) ; compléter après premier déploiement **sans commiter de secrets** (placeholders + [credentials.md](../../04-rails/setup/credentials.md)).
5. **Migrations** : **qui** les exécute et **quand** (avant trafic, avec verrou court, rollback si échec).
6. **Cron / Whenever** : soit **deux conteneurs** (web + scheduler), soit **entrypoint** qui lance Puma + Supercronic, soit tâches externes — impact sur le `Dockerfile` / `CMD` actuel.
7. **Rollback** : stratégie Dokploy (redéploiement image précédente) + **restauration DB** si migration appliquée (process à documenter, comme [rollback côté scripts](../../../ops/lib/deployment/rollback.sh)).
8. **Observabilité** : logs, alertes — au-delà des métriques optionnelles actuelles (`PROMETHEUS_PUSHGATEWAY` dans `*.env`).

---

## 7. Questions ouvertes (checklist)

Répondre par oui/non ou choix explicite ; les réponses validées sont recopiées ci-dessous (*Réponses enregistrées*) et reflétées dans la section 5 quand c’est pertinent.

### Reformulation : question 4 (« registry »)

**En clair :** après le `docker build`, l’**image** (la « photo » de ton app) doit être **stockée quelque part** pour que Docker puisse lancer le conteneur.

- Avec **build dans Dokploy**, dans beaucoup de cas **Dokploy / Docker sur le serveur garde l’image localement** : tu n’as **pas** besoin de Docker Hub, GHCR, etc. Tant que tu ne configures pas explicitement « push vers un registre externe », cette question peut être **« rien de spécial, tout reste sur le serveur »**.
- Elle ne devient importante si **l’interface Dokploy** te force à choisir un **registre distant** (compte Docker Hub, GitHub Container Registry, etc.) — dans ce cas, on note ici **lequel** et **à quoi sert le compte**.

**Ce qu’on te demande de décider (quand ce sera clair à l’écran) :**  
*Est-ce que les images sont uniquement sur le serveur Dokploy, ou est-ce qu’on utilise aussi un service externe (Docker Hub, GHCR, …) ?*

### Question 5 (Postgres) — où creuser

Ce n’est pas seulement « même machine ou pas » : voir **§5.1** (options A–D, bonnes pratiques, ce qu’il faut noter après test dans Dokploy).

### Réponses enregistrées

| # | Question | Réponse |
|---|----------|---------|
| 1 | URL / domaine staging et production | **Production** : `grenoble-roller.org`. **Staging** : soit l’URL **par défaut** fournie par Traefik/Dokploy, soit un sous-domaine dédié (ex. `staging.grenobleroller.org`) — choix **non figé**, simple à modifier dans Dokploy. *À trancher au moment du premier déploiement staging.* |
| 2 | Branche Git par environnement | **Oui** : **une app Dokploy par environnement**, chacune liée au dépôt sur **`staging`** (pré-prod) ou **`main`** (production). |
| 3 | Build sur serveur Dokploy vs CI externe + registry | **Build directement dans Dokploy** (sur l’hôte). Pas de flux « CI GitHub Actions → push image → pull » pour le déploiement nominal. |
| 4 | Stockage des images (« registry ») | **Uniquement en interne** : Dokploy fournit l’infra de **build** et de **déploiement** selon les besoins ; **pas** de registre externe (Docker Hub, GHCR, etc.) dans le flux prévu. |

*Note DNS* : le domaine prod utilise un tiret (`grenoble-roller.org`) ; le sous-domaine d’exemple cité pour le staging (`grenobleroller.org`) n’en a pas — vérifier en configuration DNS / certificat qu’on utilise bien le **bon nom de zone** (éventuellement `staging.grenoble-roller.org` pour rester aligné avec la prod).

- [x] URL / domaine **staging** et **production** sur Dokploy ?
- [x] Branche Git par environnement : `staging` / `main` confirmé ?
- [x] Build sur **le serveur Dokploy** ou **CI externe** + push image vers registry ?
- [x] **Où sont stockées les images Docker après le build ?** → **Interne Dokploy** uniquement (build + déploiement gérés par la plateforme, pas de registre externe — Q4).
- [ ] **Postgres** : option **§5.1** choisie ; **hostname** + **`DATABASE_URL`** (documentés ici en non-sensible) — réseau interne de préférence, pas d’exposition publique 5432 si évitable ?
- [ ] MinIO : besoin de la **console** exposée ou uniquement endpoint S3 pour Rails ?
- [ ] **CORS / host** Rails : `config.hosts`, `MAILER_HOST`, `RAILS_FORCE_SSL` selon le proxy Dokploy ?
- [ ] **Webhooks** Git (HelloAsso, etc.) : URLs à mettre à jour après bascule ?
- [ ] **Plan de bascule** depuis l’infra actuelle (DNS, coupure, double run) ?
- [ ] **RGPD / sauvegardes** : où sont stockées les backups et qui y accède ?

---

## 8. Prochaines étapes (à cocher)

- [ ] Créer l’application Dokploy **staging** (Dockerfile, env, secrets).
- [ ] Brancher **Postgres** + variables `DATABASE_URL`.
- [ ] Brancher **S3-compatible** (MinIO ou autre) + variables Rails Active Storage.
- [ ] Premier déploiement + **`db:migrate`** + smoke test (`/up`, parcours critique).
- [ ] Reproduire pour **production** avec secrets distincts.
- [ ] Documenter ici les **captures / valeurs non sensibles** (ports, labels, commandes exactes).
- [ ] Si le choix est structurant (abandon Compose sur VPS pour la prod), envisager un **ADR** dans `docs/10-decisions-and-changelog/` ou `docs/03-architecture/adr/`.

---

## 9. Références internes

- Runbooks : [local-setup](./local-setup.md), [staging-setup](./staging-setup.md), [production-setup](./production-setup.md), [rebuild-without-cache](./rebuild-without-cache.md), [staging-troubleshooting](./staging-troubleshooting.md)
- VPS classique : [deploy-vps.md](../deploy-vps.md)
- Watchdog / déploiement auto historique : [deployment.md](../deployment.md)

---

## 10. Historique des mises à jour

| Date | Changement |
|------|------------|
| 2026-03-26 | Création : contexte, liens, build types, décisions et questions initiales |
| 2026-03-27 | Q1 domaines : prod `grenoble-roller.org` ; staging = URL Traefik par défaut ou sous-domaine (modifiable dans Dokploy) |
| 2026-03-27 | Q2 Git : une app Dokploy par environnement, branche `staging` / `main` |
| 2026-03-27 | Q3 Build : directement dans Dokploy (pas de CI externe + push image pour le flux nominal) |
| 2026-03-27 | §7 : reformulation de l’ex-Q4 « registry » (stockage des images : local Dokploy vs registre externe) |
| 2026-03-27 | Q4 : images et déploiement **internes** à Dokploy (pas Docker Hub / GHCR) |
| 2026-03-27 | §5.1 : Postgres / réseau / `DATABASE_URL` — options A–D, bonnes pratiques, lien checklist Q5 |
| 2026-03-27 | §3.1–3.4 : environnements Dokploy, services hors `web`, `ENV` vs credentials, `RAILS_MASTER_KEY` |
