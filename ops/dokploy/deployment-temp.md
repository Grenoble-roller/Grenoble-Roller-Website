# Procédure de déploiement Dokploy — THÉORIQUE (à valider)

> Ce fichier est un brouillon de travail. Chaque étape est marquée **[ ] À valider**.
> Une fois validée, elle migre vers `README.md` avec les valeurs réelles.
> Ne pas supprimer ce fichier avant que toutes les étapes soient validées.

---

## Architecture cible

```
┌──────────────────────────────────────────────────────┐
│         Projet Dokploy : "infrastructure"            │
│                                                      │
│  ┌──────────────────────────────────────────────┐   │
│  │   s3 (SeaweedFS) — PARTAGÉ staging + prod   │   │
│  │   port 8333 S3 API (interne réseau Docker)  │   │
│  │   port 9333 console (optionnel public)       │   │
│  │   buckets : grenoble-roller-staging          │   │
│  │             grenoble-roller-production       │   │
│  └──────────────────────────────────────────────┘   │
└──────────────────────────────────────────────────────┘
         │ réseau Docker partagé (à valider)
         ▼
┌────────────────────────────────┐  ┌─────────────────────────────────┐
│   Projet "Site" — staging      │  │   Projet "Site" — production    │
│                                │  │                                 │
│  ┌──────┐  ┌────────┐          │  │  ┌──────┐  ┌────────┐          │
│  │ app  │  │ worker │          │  │  │ app  │  │ worker │          │
│  │+cron │  │SolidQ  │          │  │  │+cron │  │SolidQ  │          │
│  └──┬───┘  └───┬────┘          │  │  └──┬───┘  └───┬────┘          │
│     └─────┬────┘               │  │     └─────┬────┘               │
│  ┌────────▼────────┐           │  │  ┌────────▼────────┐           │
│  │ db (PostgreSQL) │           │  │  │ db (PostgreSQL) │           │
│  └─────────────────┘           │  │  └─────────────────┘           │
└────────────────────────────────┘  └─────────────────────────────────┘

Services externes (hors Dokploy) :
  - SMTP Ionos (email)
  - HelloAsso API (paiements)
  - Cloudflare Turnstile (CAPTCHA)
```

> **SeaweedFS est unique** : un seul service pour tous les environnements.
> L'isolation est assurée par le nom du bucket (`grenoble-roller-<RAILS_ENV>`),
> déjà géré automatiquement dans `config/storage.yml`.
>
> **Alternative si les réseaux Docker inter-projets ne sont pas supportés** :
> exposer SeaweedFS sur un port de l'hôte et utiliser `http://<IP_SERVEUR>:8333`
> comme `S3_ENDPOINT`. Moins élégant mais fonctionne sans configuration réseau avancée.

---

## Phase 0 — Prérequis

- [ ] Dokploy installé et accessible
- [ ] Accès au registre Docker (ou build direct sur le serveur Dokploy)
- [ ] Clé SSH ajoutée à Dokploy pour accès au dépôt Git
- [ ] DNS configuré : domaine pointant vers l'IP du serveur Dokploy
- [ ] `RAILS_MASTER_KEY` disponible (depuis `config/master.key` local)
- [ ] Credentials SMTP Ionos disponibles
- [ ] Credentials HelloAsso (prod) disponibles

---

## Phase 1 — Créer le projet Dokploy

- [ ] Dans Dokploy UI : **Projects → New Project**
- [ ] Nom suggéré : `grenoble-roller`
- [ ] Environnement : `production` (ou `staging` pour le premier test)

> **Note** : créer un projet séparé par environnement (staging / production), pas deux services dans le même projet.

---

## Phase 2 — Service `db` (PostgreSQL)

- [ ] **Service type** : Database → PostgreSQL
- [ ] **Nom** : `db` (ou `postgres`)
- [ ] **Version** : PostgreSQL 16 (ou 17)
- [ ] **Variables à définir** :
  ```
  POSTGRES_USER=app
  POSTGRES_PASSWORD=<mot de passe fort>
  POSTGRES_DB=app_production
  ```
- [ ] **Port** : interne uniquement (ne pas exposer publiquement)
- [ ] **Volume** : activer la persistence des données (ex: `/var/lib/postgresql/data`)

> **Point de validation** : se connecter depuis la console Dokploy et vérifier que la base répond.

> **Hostname interne** : dans Dokploy, le nom interne du service est utilisé comme hostname.
> À noter après création : `_______________` (ex: `db`, `postgres`, `grenoble-roller-db`)

---

## Phase 3 — Service `s3` (SeaweedFS — projet infrastructure, partagé)

> **SeaweedFS est créé une seule fois** dans un projet Dokploy dédié (`infrastructure`),
> partagé entre staging et production via réseau Docker ou port hôte.
> Choix : MinIO déprécié → **SeaweedFS** mature (10+ ans), S3-compatible, activement maintenu.

- [ ] Dans Dokploy : créer un projet **`infrastructure`** (si pas déjà fait)
- [ ] **Service type** : Docker image personnalisée
- [ ] **Image** : `chrislusf/seaweedfs:latest`
- [ ] **Nom** : `s3`
- [ ] **Command** : `server -s3 -dir=/data -s3.port=8333 -s3.config=/etc/seaweedfs/s3.json`
- [ ] **Variables à définir** : aucune (la config d'auth est dans le fichier `s3.json` monté en volume)
- [ ] **Ports** :
  - `8333` → interne réseau Docker (ou exposé sur l'hôte si inter-projet non supporté)
  - `9333` → optionnel, console SeaweedFS (management)
- [ ] **Volume data** : persistence sur `/data`
- [ ] **Volume config** : monter `s3.json` sur `/etc/seaweedfs/s3.json`
- [ ] **Valider** : comment Dokploy partage un réseau entre projets — sinon utiliser `http://<HOST_IP>:8333`

### Fichier de config SeaweedFS S3 (`s3.json`)

À créer sur le serveur et monter en volume dans Dokploy :

```json
{
  "identities": [
    {
      "name": "app",
      "credentials": [
        {
          "accessKey": "__S3_ACCESS_KEY__",
          "secretKey": "__S3_SECRET_KEY__"
        }
      ],
      "actions": [
        "Admin",
        "Read",
        "Write",
        "List",
        "Tagging"
      ]
    }
  ]
}
```

> **Bucket** : auto-créé au premier démarrage de l'app via `storage:ensure_bucket`
> (appelé automatiquement par `bin/docker-entrypoint`).
> Bucket attendu : `grenoble-roller-production` (ou `grenoble-roller-staging`)

> **Hostname interne** à noter après création : `_______________`

> **Point de blocage connu** : SeaweedFS nécessite le fichier `s3.json` monté avant démarrage.
> Sans ce fichier, la commande `-s3.config` échoue. À valider si Dokploy permet de monter
> des fichiers de config individuels ou s'il faut un volume dédié.

---

## Phase 4 — Service `app` (Rails + Supercronic)

- [ ] **Service type** : Application (Git)
- [ ] **Nom** : `app`
- [ ] **Repository** : URL du dépôt Git
- [ ] **Branch** : `main` (production) ou `Dev` (staging)
- [ ] **Dockerfile** : `Dockerfile` (à la racine)
- [ ] **Port** : `3000`
- [ ] **Domain** : configurer dans Dokploy → HTTPS via Traefik automatique

### Variables d'environnement (copier depuis `env/production.env.example`)

```env
RAILS_ENV=production
APP_ENV=production
DEPLOY_ENV=production
DB_BOOT_TASK=migrate
RAILS_LOG_LEVEL=info
TZ=Europe/Paris
PORT=3000
RAILS_FORCE_SSL=true

# Secrets (à mettre en "secret" dans Dokploy, pas en plain env)
RAILS_MASTER_KEY=<valeur de config/master.key>
DATABASE_URL=postgresql://app:<PASSWORD>@<DB_INTERNAL_HOST>:5432/app_production

# SeaweedFS S3
S3_ENDPOINT=http://<S3_INTERNAL_HOST>:8333
S3_ACCESS_KEY_ID=<access_key>
S3_SECRET_ACCESS_KEY=<secret_key>

# SolidQueue mode (option A : embarqué dans Puma, sans service worker séparé)
SOLID_QUEUE_IN_PUMA=true
```

> **Option A (simple)** : `SOLID_QUEUE_IN_PUMA=true` → jobs et cron tournent dans l'app.
> **Option B (scalable)** : `SOLID_QUEUE_IN_PUMA=false` + créer le service `worker` (Phase 5).
> Recommandation : commencer par l'option A, passer à B si la charge le justifie.

### Health check

- [ ] Configurer le health check Dokploy : `GET /up` (route Rails standard)
- [ ] Timeout : 30s, interval : 10s, retries : 3

### Comportement au démarrage

L'entrypoint `/rails/bin/docker-entrypoint` fait automatiquement :
1. `db:migrate` (car `DB_BOOT_TASK=migrate` en production)
2. Démarre Supercronic en arrière-plan (cron jobs)
3. Lance Puma (serveur web)

---

## Phase 5 — Service `worker` (SolidQueue) — optionnel

> Ne créer que si `SOLID_QUEUE_IN_PUMA=false` (Option B).

- [ ] **Service type** : Application (même source Git que `app`)
- [ ] **Nom** : `worker`
- [ ] **Même Dockerfile** que `app`
- [ ] **Override CMD** : `./bin/rails solid_queue:start`
- [ ] **Port** : aucun (service interne sans trafic HTTP)
- [ ] **Variables** : identiques à `app` SAUF :
  ```
  DB_BOOT_TASK=none
  SOLID_QUEUE_IN_PUMA=false
  ```

> **Note** : le worker a besoin d'accéder à la DB et MinIO avec les mêmes credentials.
> Ne pas démarrer l'entrypoint en mode `db:migrate` pour éviter la double migration.

---

## Phase 6 — Ordre de déploiement initial

- [ ] **1.** Déployer `db` → attendre que la base soit up
- [ ] **2.** Déployer `minio` → attendre que MinIO soit up
- [ ] **3.** Créer le bucket MinIO :
  ```bash
  # Via console MinIO (port 9001) : créer le bucket "grenoble-roller-production"
  # OU via exec dans le conteneur app après déploiement :
  bundle exec rake minio:ensure_bucket
  ```
- [ ] **4.** Déployer `app` → les migrations s'exécutent automatiquement
- [ ] **5.** (Option B) Déployer `worker`

---

## Phase 7 — Vérifications post-déploiement

### App

- [ ] `GET /up` répond 200
- [ ] Page d'accueil accessible en HTTPS
- [ ] Connexion admin fonctionnelle (`/admin`)
- [ ] Logs sans erreur : `dokploy logs app`

### Base de données

- [ ] Les 3 bases existent : `app_production`, `app_production_cache`, `app_production_cable`
- [ ] Migrations appliquées : `bundle exec rails db:version`

### Cron (Supercronic)

- [ ] Vérifier dans les logs app : `"Supercronic started in background"`
- [ ] Tâches actives :
  - Sync HelloAsso toutes les 5 min
  - Rappels événements à 19h
  - MAJ adhésions expirées à minuit
  - Rappels renouvellement à 9h
  - Remise rollers en stock à 2h

### Jobs (SolidQueue)

- [ ] Accès Mission Control : `/jobs` (admin uniquement)
- [ ] Aucun job en erreur au démarrage

### Email

- [ ] Envoyer un email de test :
  ```ruby
  # via rails console
  UserMailer.welcome(User.first).deliver_now
  ```
- [ ] Vérifier réception

### MinIO / Active Storage

- [ ] Uploader une image depuis l'admin
- [ ] Vérifier que le fichier apparaît dans le bucket MinIO

### HelloAsso

- [ ] Vérifier les credentials production dans les Rails credentials
- [ ] Tester un webhook ou une synchronisation manuelle

---

## Phase 8 — Backups

- [ ] Configurer backup PostgreSQL dans Dokploy → destination S3/MinIO externe
- [ ] Configurer backup volume MinIO (données) → destination S3 externe ou snapshot serveur
- [ ] Tester la restauration d'un backup DB

---

## Variables d'environnement complètes — récapitulatif

| Variable | Service | Source | Note |
|---|---|---|---|
| `RAILS_MASTER_KEY` | app, worker | Dokploy Secret | Jamais en clair |
| `DATABASE_URL` | app, worker | Dokploy Secret | URL complète |
| `S3_ENDPOINT` | app, worker | Env | `http://<host>:8333` |
| `S3_ACCESS_KEY_ID` | app, worker | Dokploy Secret | |
| `S3_SECRET_ACCESS_KEY` | app, worker | Dokploy Secret | |
| `POSTGRES_PASSWORD` | db | Dokploy Secret | |
| `RAILS_ENV` | app, worker | Env | `production` |
| `PORT` | app | Env | `3000` |
| `DB_BOOT_TASK` | app | Env | `migrate` |
| `DB_BOOT_TASK` | worker | Env | `none` |

---

## Points de blocage potentiels connus

1. **Hostname interne Dokploy** : le format exact des noms de services internes est à confirmer (ex: `db`, `grenoble-roller-db`, autre).
2. **Solid Cable / Action Cable** : nécessite la base `app_production_cable`. La base secondaire est créée par les migrations Rails mais il faut que le `DATABASE_URL` pointe vers le bon host.
3. **`db:migrate` vs bases multiples** : Rails gère les 3 bases via la config `database.yml` avec `connects_to`. La migration initiale doit inclure les 3 namespaces (`primary`, `cache`, `cable`).
4. **RAILS_MASTER_KEY** : si les credentials sont corrompus ou que la clé ne correspond pas, l'app crash au démarrage sans message clair.
5. **MinIO bucket** : l'app crash si le bucket n'existe pas au moment du premier upload. Créer le bucket AVANT de lancer l'app.

---

*Mis à jour le : 2026-05-04*
*Statut : théorique — aucune étape validée*
