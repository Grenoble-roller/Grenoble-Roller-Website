# Déploiement Dokploy — Grenoble Roller

Procédure de déploiement de l'application sur [Dokploy](https://dokploy.com).

> **En cours de validation** : la procédure théorique complète est dans [`deployment-temp.md`](./deployment-temp.md).
> Ce README ne documente que les étapes **réellement validées** en production/staging.

---

## Architecture des services

### Projet `infrastructure` — services partagés staging + production

| Service | Type | Image | Port |
|---|---|---|---|
| `s3` | Stockage S3 (SeaweedFS) | `chrislusf/seaweedfs` | 8333 S3 API, 9333 console |

> Un seul SeaweedFS pour tous les environnements. L'isolation est par bucket :
> `grenoble-roller-staging` et `grenoble-roller-production` (auto via `RAILS_ENV`).

### Projet `Site` — par environnement (staging / production)

| Service | Type | Image | Port exposé |
|---|---|---|---|
| `db` | PostgreSQL | `postgres:16` | interne uniquement |
| `app` | Rails + Supercronic | build depuis `Dockerfile` | 3000 → Traefik HTTPS |
| `worker` | SolidQueue | même image que `app` | aucun |

> `worker` est optionnel si `SOLID_QUEUE_IN_PUMA=true` (jobs embarqués dans Puma).
> Supercronic (cron) démarre automatiquement **dans le conteneur `app`** via l'entrypoint.
> Pas de Redis — tout est DB-backed (SolidQueue, SolidCache, SolidCable).
> Le bucket S3 est **auto-créé au premier boot** de l'app (`storage:ensure_bucket`).

---

## Fichiers de référence

| Fichier | Usage |
|---|---|
| [`env/production.env.example`](./env/production.env.example) | Template variables d'environnement production |
| [`env/staging.env.example`](./env/staging.env.example) | Template variables d'environnement staging |
| [`deployment-temp.md`](./deployment-temp.md) | Procédure théorique complète (work in progress) |

---

## Étapes validées

> Les étapes ci-dessous ont été testées et confirmées en conditions réelles.
> Chaque étape sera ajoutée ici après validation.

### ✅ Aucune étape validée pour l'instant

*La procédure est en cours de test. Voir [`deployment-temp.md`](./deployment-temp.md) pour le détail de chaque étape.*

---

<!-- VALIDATED STEPS — ajout progressif ci-dessous -->

<!--
### Étape X — [Nom de l'étape]

**Validé le** : YYYY-MM-DD  
**Environnement** : staging | production

[Description de ce qui a été fait et ce qui a fonctionné]

```bash
# commandes exactes utilisées
```

> **Gotcha** : [piège éventuel rencontré]
-->

---

## Notes de sécurité

- Ne jamais commiter de vraies valeurs dans les fichiers `.env.example`.
- `RAILS_MASTER_KEY` → uniquement dans les **Secrets** Dokploy (jamais en variable plain text).
- `DATABASE_URL`, `MINIO_SECRET_ACCESS_KEY` → idem, Secrets Dokploy.
- DB et MinIO : **pas de port public** sauf la console MinIO (9001) si nécessaire.
- L'app tourne en utilisateur non-root (uid 1000) — ne pas modifier sans tester l'entrypoint.

---

## Comportement au premier démarrage (`app`)

L'entrypoint `bin/docker-entrypoint` fait automatiquement :
1. Détecte `DB_BOOT_TASK=migrate` → exécute `rails db:migrate`
2. Démarre Supercronic en arrière-plan (cron jobs production)
3. Lance Puma sur `0.0.0.0:$PORT`

Pour `worker` : toujours mettre `DB_BOOT_TASK=none` pour éviter la double migration.

---

## Cron jobs embarqués (Supercronic)

Actifs dès que `RAILS_ENV=production` ou `DEPLOY_ENV=production` :

| Fréquence | Tâche |
|---|---|
| Toutes les 5 min | Sync paiements HelloAsso |
| Tous les jours 19h | Rappels événements du lendemain |
| Tous les jours minuit | MAJ adhésions expirées |
| Tous les jours 9h | Rappels renouvellement adhésions |
| Tous les jours 2h | Remise rollers en stock (après initiations) |
| Lundis 10h | Vérification autorisations mineurs |
| Lundis 10h30 | Vérification certificats médicaux |

---

## Ressources

- [Dokploy documentation](https://docs.dokploy.com)
- [Runbook complet (VPS → Dokploy)](../../docs/07-ops/runbooks/dokploy-setup.md)
- [Background jobs & cron](../../docs/04-rails/background-jobs/README.md)
- [Active Storage MinIO](../../docs/04-rails/setup/active-storage-minio-setup.md)
