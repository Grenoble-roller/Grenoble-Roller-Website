# Plan de Migration — Grenoble Roller vers Dokploy

> **Fichier :** `/home/flowtech/grenoble-roller-migration-dokploy.md`  
> **Date :** 2026-05-02  
> **Statut :** ✅ PHASE 1 TERMINÉE — site en ligne via Traefik Dokploy — Phase 2 à planifier

---

## 0. Sauvegarde réalisée le 2026-05-02 à 23h54

> Dossier : `/home/flowtech/save/2026-05-02_23-54/`  
> Taille totale : **49 Mo**

| Fichier | Contenu | Taille |
|---|---|---|
| `grenoble_roller_production.dump` | Dump PostgreSQL (format custom — restaurable avec `pg_restore`) | 316 Ko |
| `volume-db-data.tar.gz` | Volume Docker PostgreSQL complet | 14 Mo |
| `volume-minio-data.tar.gz` | Volume Docker MinIO complet (fichiers uploadés) | 35 Mo |
| `volume-caddy-data.tar.gz` | Certificats Let's Encrypt Caddy | 8 Ko |
| `docker-compose.yml` | Stack Docker Compose production | 4.4 Ko |
| `Caddyfile` | Configuration reverse proxy + sécurité | 5.1 Ko |
| `production.env` | Variables de déploiement (non-sensibles) | 1.2 Ko |
| `master.key` | Clé Rails chiffrée (chmod 600) | 32 octets |

**Restaurer la base de données depuis le dump :**
```bash
sudo docker exec -i grenoble-roller-db-production pg_restore \
  -U postgres -d grenoble_roller_production --clean \
  < /home/flowtech/save/2026-05-02_23-54/grenoble_roller_production.dump
```

**Restaurer un volume depuis le tar.gz :**
```bash
sudo docker run --rm \
  -v production_grenoble-roller-prod-db-data:/target \
  -v /home/flowtech/save/2026-05-02_23-54:/backup \
  alpine sh -c "cd /target && tar xzf /backup/volume-db-data.tar.gz"
```

---

## 1. État des lieux actuel (vérifié)

### 1.1 Serveur

| Élément | Valeur |
|---|---|
| Chemin réel du projet | `/opt/Grenoble-Roller-Project/` |
| Compose production | `/opt/Grenoble-Roller-Project/ops/production/docker-compose.yml` |
| RAM totale / utilisée / disponible | 7.7 Go / 3.0 Go / 4.8 Go |
| CPU | 4 vCPU |
| Disque `/` | 232 Go total — 16 Go utilisés — **216 Go libres** |
| Docker | 29.3.0 |
| Docker Compose | v5.1.0 |
| Swap | Aucun |

### 1.2 Services Docker actifs

| Conteneur | Image | Ports exposés | Uptime | Santé |
|---|---|---|---|---|
| `grenoble-roller-caddy-production` | `caddy:2-alpine` | **80, 443, 443/udp, 2019** | 7 semaines | — |
| `grenoble-roller-production` | `production-web` (Rails) | **3000** | 7 semaines | healthy |
| `grenoble-roller-db-production` | `postgres:16-alpine` | aucun (interne) | 7 semaines | healthy |
| `grenoble-roller-minio-production` | `minio/minio:latest` | aucun (interne) | 7 semaines | healthy |

### 1.3 Reverse proxy actuel — **Caddy 2**

> **Point clé :** le reverse proxy n'est PAS Traefik ni Nginx — c'est **Caddy 2**.

| Élément | Valeur |
|---|---|
| Reverse proxy | **Caddy 2-alpine** |
| Configuration | `/opt/Grenoble-Roller-Project/ops/production/Caddyfile` |
| Domaines gérés | `grenoble-roller.org` et `www.grenoble-roller.org` |
| TLS/HTTPS | **Let's Encrypt automatique via Caddy** |
| HTTP/3 (QUIC) | Activé (port 443/udp) |
| Port admin Caddy | 2019 (exposé — à fermer ou supprimer) |
| Upstream cible | `web:3000` (nom de service Docker interne) |

**Ce que fait le Caddyfile (à reproduire côté Traefik ou Rails) :**
- Compression gzip/zstd
- Headers de sécurité : HSTS, X-Content-Type-Options, X-XSS-Protection, Referrer-Policy
- **CSP spécifique Cloudflare Turnstile** (anti-bot — critique à ne pas perdre)
- Cache assets `/assets/*` → `max-age=31536000, immutable`
- Cache images `/images/*` → `max-age=86400`
- Timeouts augmentés pour Active Storage (`/rails/direct_uploads/*`, `/rails/active_storage/*`)
- Health check `/up` répondu directement par Caddy

### 1.4 Application Rails

| Élément | Valeur |
|---|---|
| Framework | Ruby on Rails (production) |
| Port interne | 3000 |
| Background jobs | **Solid Queue intégré dans Puma** (pas de conteneur séparé) |
| Stockage fichiers | **MinIO** via Active Storage |
| Variables d'env critiques | `RAILS_MASTER_KEY` (monté depuis `config/master.key`) |
| Timezone | Europe/Paris |
| SSL forcé | `RAILS_FORCE_SSL=true` |

### 1.5 Réseau Docker

| Réseau | Driver | Subnet | Conteneurs |
|---|---|---|---|
| `production_app-network` | bridge | `172.19.0.0/16` | Tous les 4 conteneurs |
| `production_default` | bridge | — | (inutilisé) |

### 1.6 Volumes persistants

| Volume Docker | Contenu | Criticité |
|---|---|---|
| `production_grenoble-roller-prod-db-data` | Données PostgreSQL | **CRITIQUE** |
| `production_grenoble-roller-prod-minio-data` | Fichiers uploadés (Active Storage) | **CRITIQUE** |
| `production_caddy-data` | Certificats Let's Encrypt | Remplacé par Traefik |
| `production_caddy-config` | Config runtime Caddy | Non réutilisé |
| `production_nginx-certbot-*` | Anciens volumes nginx (orphelins) | À nettoyer |

### 1.7 Tâches planifiées (cron)

- Gérées via la gem Ruby **Whenever** (`bundle exec whenever`)
- Script d'installation : `ops/scripts/update-crontab.sh [production]`
- Backups chiffrés activés (`BACKUP_ENCRYPTION_ENABLED=true`)
- Blue/green deployment disponible mais désactivé (`BLUE_GREEN_ENABLED=false`)

### 1.8 Fichiers de configuration critiques

| Fichier | Rôle |
|---|---|
| `ops/production/docker-compose.yml` | Stack complète |
| `ops/production/Caddyfile` | Reverse proxy + sécurité |
| `ops/config/production.env` | Variables de déploiement (non-sensibles) |
| `config/master.key` | Clé Rails chiffrée, montée en volume — **NE PAS PERDRE** |

---

## 2. Cible — Architecture après migration Dokploy

### 2.1 Vue d'ensemble Phase 1 (transition sans risque)

```
Internet (80/443)
      │
      ▼
┌──────────────────────────────┐
│   Traefik (Dokploy)          │  ◄── Remplace Caddy
│   Port 80 + 443              │       Gère Let's Encrypt
│   UI Dokploy sur port 3001   │  ◄── Port changé (conflit avec Rails :3000)
└──────────────┬───────────────┘
               │  réseau dokploy-network connecté à production_app-network
               ▼
┌──────────────────────────────┐
│  grenoble-roller-production  │  ◄── Conteneur Rails INCHANGÉ
│  (port 3000 — interne)       │       Port 3000 dé-exposé du host
│  grenoble-roller-db          │
│  grenoble-roller-minio       │
└──────────────────────────────┘
```

### 2.2 Phases de migration

| Phase | Action | Durée coupure | Risque |
|---|---|---|---|
| **Phase 0** | Backup + préparation | 0 | Nul |
| **Phase 1** | Stop Caddy → Install Dokploy → Traefik pointe vers le Compose existant | ~5 min | Faible |
| **Phase 2** | Migration des services dans Dokploy (planifier séparément) | à définir | Moyen |

---

## 3. Points de blocage critiques identifiés

### ✅ DOKPLOY INSTALLÉ — état au 2026-05-04

| Élément | Valeur |
|---|---|
| Version Dokploy | v0.29.2 |
| Version Traefik | v3.6.7 |
| UI Dokploy | `dokploy.grenoble-roller.org` ✅ |
| Mode Docker | **Swarm** (réseau overlay) |
| Réseau Traefik | `dokploy-network` (overlay swarm) |
| Ports 80/443 | tenus par `dokploy-traefik` ✅ |

> ⚠️ Dokploy tourne en **Docker Swarm** — le réseau `dokploy-network` est un overlay.
> Les conteneurs standalone (grenoble-roller) ne peuvent pas le rejoindre directement avec `docker network connect`.
> Solution : utiliser le **file provider Traefik** pour router vers l'IP interne du conteneur Rails.

### ℹ️ DOKPLOY UTILISE TRAEFIK — PAS CADDY

Dokploy embarque **Traefik** comme reverse proxy natif. Caddy n'est pas supporté nativement.  
La migration consiste donc à **remplacer Caddy par le Traefik de Dokploy**, et à reconfigurer les règles de routing et les headers de sécurité sous forme de middlewares Traefik.

### ⚠️ CONFLIT PORT 3000 — PRIORITÉ ABSOLUE

Dokploy démarre son interface web sur le **port 3000** par défaut.  
Or `grenoble-roller-production` expose aussi le **port 3000** sur l'hôte.

**Solution :** avant d'installer Dokploy, modifier le docker-compose.yml pour **retirer l'exposition du port 3000** vers l'hôte (inutile une fois que Traefik proxifie directement via le réseau Docker interne) :

```yaml
# Supprimer ou commenter cette ligne dans docker-compose.yml :
# ports:
#   - "3000:3000"
```

Et configurer Dokploy UI sur un autre port (ex: 3001) via son `.env`.

### ⚠️ REMPLACEMENT CADDY → TRAEFIK : les headers sécurité

Le Caddyfile contient des **headers de sécurité critiques** (CSP pour Cloudflare Turnstile, HSTS, etc.) actuellement gérés par Caddy. Une fois Caddy retiré, ces headers doivent être repris :

- **Option A (recommandée Phase 1)** : middleware Traefik (labels sur le conteneur)
- **Option B** : les intégrer dans Rails (rack-middleware)

### ⚠️ CERTIFICAT TLS — renouvellement Let's Encrypt

Caddy a ses propres certificats dans `production_caddy-data`. Traefik va en générer de nouveaux. Le renouvellement prend quelques secondes si le DNS pointe déjà correctement.

### ⚠️ VOLUMES ORPHELINS

Des volumes `production_nginx-certbot-*` et `production_nginx-proxy-*` traînent — vestige d'une ancienne config Nginx. Ils ne sont plus utilisés, à nettoyer après la migration.

---

## 4. Runbook de migration

> **Légende :**
> - 🤖 **CLAUDE** — je l'exécute directement dans cette session
> - 👤 **TOI** — action manuelle requise (UI, décision, copie hors serveur)
> - ⏱️ durée estimée indiquée pour chaque étape

---

### Phase 0 — Préparation (SANS coupure de service)

#### 0.1 🤖 Modifier le docker-compose.yml — retirer le port 3000 host

> Je retire les lignes `ports: - "3000:3000"` du service `web`.  
> Traefik joindra le conteneur via le réseau interne — le port host n'est plus nécessaire.

```bash
# Exécuté par Claude dans la session
sudo python3 << 'EOF'
path = '/opt/Grenoble-Roller-Project/ops/production/docker-compose.yml'
content = open(path).read()
old = '    # Port 3000 exposé pour accès direct (en plus de Caddy)\n    ports:\n      - "3000:3000"\n    # Monter le fichier master.key'
new = '    # Monter le fichier master.key'
result = content.replace(old, new)
open(path, 'w').write(result)
print('OK' if old not in result else 'ECHEC')
EOF
```

#### 0.2 🤖 Recréer le conteneur web sans le port 3000 (Caddy reste actif)

> ⏱️ ~45 sec — Caddy continue de servir le trafic, pas de coupure.

```bash
cd /opt/Grenoble-Roller-Project
sudo docker compose -f ops/production/docker-compose.yml up -d --force-recreate web
# Attendre healthy
sudo docker ps | grep grenoble-roller-production
ss -tlnp | grep 3000   # doit retourner VIDE
```

#### 0.3 🤖 Vérifier DNS et firewall

```bash
dig grenoble-roller.org +short
dig www.grenoble-roller.org +short
sudo ufw status
```

#### 0.4 👤 Copier le master.key hors du serveur

> ⏱️ 1 min — **action manuelle obligatoire**, ne peut pas être automatisée.

```bash
sudo cat /opt/Grenoble-Roller-Project/config/master.key
```

→ Copier la valeur dans ton gestionnaire de mots de passe (Bitwarden, 1Password, etc.)

---

### Phase 1 — Installation Dokploy + routage Traefik ⚠️ DOWNTIME

> **Durée totale estimée : 8–12 min de coupure**  
> Maintenance mode déjà activé sur le site ✅

#### 1.1 🤖 Stopper Caddy — début du downtime

```bash
sudo docker stop grenoble-roller-caddy-production
# Vérifier que les ports 80/443 sont libres
ss -tlnp | grep -E ':80|:443'   # doit retourner VIDE
```

#### 1.2 👤 Lancer l'installation de Dokploy

> ⏱️ 2–4 min — nécessite de lire la sortie interactive et confirmer si demandé.

```bash
SERVER_PORT=3001 curl -sSL https://dokploy.com/install.sh | sh
```

> Si l'installer ignore `SERVER_PORT`, le modifier après dans `/etc/dokploy/.env` puis `docker compose restart`.

#### 1.3 🤖 Vérifier que Dokploy et Traefik sont bien démarrés

```bash
sudo docker ps | grep -E 'dokploy|traefik'
sudo docker logs dokploy-traefik --tail 20
```

#### 1.4 🤖 Connecter le réseau Compose au réseau Traefik Dokploy

```bash
sudo docker network connect dokploy-network grenoble-roller-production
# Vérifier la connexion
sudo docker inspect grenoble-roller-production --format '{{range $k,$v := .NetworkSettings.Networks}}{{$k}} {{end}}'
```

#### 1.5 👤 Configurer le domaine dans l'UI Dokploy

> ⏱️ 2–3 min — interface web, ne peut pas être automatisé.

1. Ouvrir `http://<IP>:3001` dans le navigateur
2. Créer le compte admin
3. Aller dans **Settings → Domains** (ou **Proxy**)
4. Ajouter :
   - Domaine : `grenoble-roller.org`
   - Domaine : `www.grenoble-roller.org`
   - Target : `grenoble-roller-production:3000`
   - TLS : **Let's Encrypt activé**

#### 1.4b 🤖 Connexion Traefik → réseau app (ajustement Swarm)

> Dokploy tourne en Swarm — `dokploy-network` est un overlay non attachable.
> Solution appliquée : connexion de `dokploy-traefik` à `production_app-network`.

```bash
sudo docker network connect production_app-network dokploy-traefik
# Résultat : Traefik accessible sur 172.19.0.2 dans le réseau Rails
```

#### 1.5b 🤖 Création du fichier de route Traefik

> Fichier créé : `/etc/dokploy/traefik/dynamic/grenoble-roller.yml`
> Traefik watche ce dossier — prise en compte immédiate, sans redémarrage.

- Router HTTP → redirect 308 vers HTTPS ✅
- Router HTTPS → `grenoble-roller-production:3000` ✅
- TLS Let's Encrypt automatique ✅
- Headers de sécurité (HSTS, CSP Turnstile, X-XSS, Referrer) ✅

#### 1.6 🤖 Validation — résultats au 2026-05-04

```
https://grenoble-roller.org      → HTTP/2 200 ✅
https://www.grenoble-roller.org  → HTTP/2 200 ✅
http://grenoble-roller.org       → 308 redirect HTTPS ✅
Headers de sécurité              → tous présents ✅
```

#### 1.7 🤖 Plan de rollback si échec

> Si quelque chose ne va pas, remettre Caddy en route immédiatement :

```bash
sudo docker start grenoble-roller-caddy-production
# Vérifier que Caddy reprend bien
curl -I https://grenoble-roller.org
```

---

### Phase 1.8 👤 Créer la clé API Dokploy + connecter Claude via MCP

> ⏱️ 2 min — à faire juste après que le site répond correctement en 1.6.  
> Une fois la clé donnée à Claude, toute la Phase 2 devient 🤖 automatisée.

**Dans l'UI Dokploy (`http://<IP>:3001`) :**

1. Aller dans **Settings → API**
2. Cliquer **Generate API Key**
3. Copier la clé générée
4. La donner à Claude dans la session : `Voici ma clé Dokploy : <clé>`

**Claude configure ensuite le MCP Dokploy dans Claude Code :**

```bash
# Claude l'exécute automatiquement après réception de la clé
claude mcp add dokploy \
  --transport http \
  --url http://<IP>:3001/api \
  --header "Authorization: Bearer <clé>"
```

> Cela permet à Claude d'interagir directement avec Dokploy via son API REST :
> créer des projets, configurer des domaines, gérer les variables d'env,
> déployer des services — sans passer par l'UI.

---

### Phase 2 — Migration des services dans Dokploy (session suivante, via MCP)

> Ces étapes ne font pas partie du downtime initial.  
> Grâce au MCP Dokploy, elles sont quasi-entièrement automatisées par Claude.

#### 2.1 🤖 Créer le projet Dokploy et importer le Compose

```
Via MCP → POST /api/compose/create
         → body : contenu du docker-compose.yml actuel
```

#### 2.2 🤖 Injecter les variables d'environnement

```
Via MCP → POST /api/project/{id}/env
         → variables issues de ops/config/production.env + secrets
```

> ⚠️ `RAILS_MASTER_KEY` et les secrets MinIO sont à fournir manuellement
> (jamais stockés en clair dans un fichier)

#### 2.3 🤖 Configurer les domaines dans Dokploy

```
Via MCP → POST /api/domain/create
         → grenoble-roller.org + www.grenoble-roller.org
         → Let's Encrypt activé
```

#### 2.4 🤖 Transférer les volumes (DB et MinIO)

```bash
# Copie des volumes vers les nouveaux volumes Dokploy
sudo docker run --rm \
  -v production_grenoble-roller-prod-db-data:/src \
  -v <nouveau-volume-dokploy>:/dst \
  alpine sh -c "cp -a /src/. /dst/"
```

#### 2.5 👤 Valider le déploiement Dokploy natif

> Tester manuellement le site une fois le projet Dokploy déployé.

#### 2.6 🤖 Supprimer l'ancienne stack Compose et nettoyer

```bash
cd /opt/Grenoble-Roller-Project
sudo docker compose -f ops/production/docker-compose.yml down
sudo docker volume rm production_caddy-data production_caddy-config
sudo docker volume rm production_nginx-certbot-conf production_nginx-certbot-www \
  production_nginx-proxy-acme production_nginx-proxy-certs \
  production_nginx-proxy-dhparam production_nginx-proxy-html production_nginx-proxy-vhost
```

---

## 5. Headers de sécurité — migration Caddy → Traefik

À configurer comme **middleware Traefik** dans Dokploy (labels ou fichier de config) :

```yaml
traefik.http.middlewares.grenoble-security.headers.stsSeconds: "31536000"
traefik.http.middlewares.grenoble-security.headers.stsIncludeSubdomains: "true"
traefik.http.middlewares.grenoble-security.headers.stsPreload: "true"
traefik.http.middlewares.grenoble-security.headers.contentTypeNosniff: "true"
traefik.http.middlewares.grenoble-security.headers.browserXssFilter: "true"
traefik.http.middlewares.grenoble-security.headers.referrerPolicy: "strict-origin-when-cross-origin"
traefik.http.middlewares.grenoble-security.headers.customResponseHeaders.server: ""
# CSP Cloudflare Turnstile (critique pour le formulaire anti-bot)
traefik.http.middlewares.grenoble-security.headers.contentSecurityPolicy: "default-src 'self' https://challenges.cloudflare.com; script-src 'self' 'unsafe-inline' 'unsafe-eval' https://challenges.cloudflare.com; style-src 'self' 'unsafe-inline' https://challenges.cloudflare.com; img-src 'self' data: https:; font-src 'self' data:; connect-src 'self' https://challenges.cloudflare.com; frame-src 'self' https://challenges.cloudflare.com; frame-ancestors 'self'; worker-src 'self' https://challenges.cloudflare.com blob:;"
```

---

## 6. Résumé des risques

| Risque | Probabilité | Impact | Mitigation |
|---|---|---|---|
| Conflit port 3000 (Rails vs Dokploy UI) | **Certaine** | Bloquant | Retirer exposition 3000 du compose + changer port Dokploy |
| Perte des headers sécurité (CSP Turnstile) | Haute | Fort | Middleware Traefik à configurer avant de couper Caddy |
| Échec Let's Encrypt (DNS mal configuré) | Faible | Moyen | Vérifier DNS avant la migration |
| Perte de données PostgreSQL ou MinIO | Faible | Fatal | Backup obligatoire avant toute action |
| Volumes orphelins nginx (déjà présents) | Certaine | Nul | À nettoyer après migration, pas bloquant |

---

## 7. Fenêtre de maintenance estimée

| Opération | Durée | Service coupé |
|---|---|---|
| Stop Caddy | 5 sec | **Oui — début de la fenêtre** |
| Installation Dokploy | 3–5 min | Oui |
| Configuration domaine + TLS | 2–3 min | Oui |
| Vérification et validation | 5–10 min | Non (si TLS OK) |
| **Total** | **~15 min** | dont ~10 min max |

> Recommandation : planifier un **dimanche matin entre 6h et 8h**.

---

## 8. Informations à conserver précieusement

```
Domaines      : grenoble-roller.org, www.grenoble-roller.org
Email LE      : contact@grenoble-roller.org
Réseau Docker : production_app-network (172.19.0.0/16)
Volumes DB    : production_grenoble-roller-prod-db-data
Volumes MinIO : production_grenoble-roller-prod-minio-data
Master key    : /opt/Grenoble-Roller-Project/config/master.key  ← BACKUP IMPÉRATIF
Compose actuel: /opt/Grenoble-Roller-Project/ops/production/docker-compose.yml
Caddyfile     : /opt/Grenoble-Roller-Project/ops/production/Caddyfile
```

---

*Document complété avec les données réelles du serveur — prêt à valider avant action.*
