# ⏰ Jobs Récurrents et Background Jobs

**Date** : 2025-01-13  
**Dernière mise à jour** : 2026-08-14  
**Statut** : ✅ **Solid Queue actif** | Migration terminée  
**Version** : 2.0

---

## 📋 Vue d'Ensemble

Ce répertoire contient la documentation complète du système de jobs récurrents et background jobs de l'application, maintenant basé sur **Solid Queue** (Rails 8).

---

## 📄 Fichiers

- **[CRON.md](./CRON.md)** : Documentation complète du système de jobs récurrents (Solid Queue actif, migration terminée)

---

## 🏗️ Architecture Actuelle

### Solid Queue (✅ ACTIF)

- **Configuration** : `config/recurring.yml` (chargé automatiquement)
- **Monitoring** : Mission Control Jobs (`/admin-panel/jobs`)
- **Base de données** : PostgreSQL (tables `solid_queue_*`)
- **Plugin Puma** : Intégré (`SOLID_QUEUE_IN_PUMA: true`)

### Jobs Configurés

| Job | Fréquence | Utilité |
|-----|-----------|---------|
| `EventReminderJob` | Quotidien 19h | Rappels événements |
| `SyncHelloAssoPaymentsJob` | Toutes les 5 min | Synchronisation paiements |
| `UpdateExpiredMembershipsJob` | Quotidien 00:00 | Adhésions expirées |
| `SendRenewalRemindersJob` | Quotidien 9h | Rappels renouvellement |
| `clear_solid_queue_finished_jobs` | Toutes les heures | Nettoyage DB |

---

## 🔗 Liens Utiles

- **Configuration** : [`config/recurring.yml`](../../../config/recurring.yml) - Configuration Solid Queue (✅ ACTIF)
- **Queue config** : [`config/queue.yml`](../../../config/queue.yml) - Configuration workers/dispatchers
- **Mailing** : [`docs/04-rails/mailing/README.md`](../mailing/README.md) - Emails automatiques
- **Admin Panel** : [`docs/04-rails/admin-panel/`](../admin-panel/) - Mission Control Jobs intégré

---

## 📚 Références

- [Solid Queue GitHub](https://github.com/rails/solid_queue)
- [Mission Control Jobs](https://github.com/rails/mission_control-jobs)

---

**Retour** : [README racine](../../../README.md)
