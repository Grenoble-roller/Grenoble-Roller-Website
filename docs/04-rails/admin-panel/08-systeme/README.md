# ⚙️ SYSTÈME - Plan d'Implémentation

**Priorité** : 🟡 MOYENNE | **Phase** : 8 | **Semaine** : 8+

---

## 📋 Vue d'ensemble

Gestion système : paiements, **notifications Discord (webhooks admin)** — voir [DR-002](../../../10-decisions-and-changelog/DR-002-discord-webhook-notifications.md).

**Status actuel** : ✅ Payments dans AdminPanel · ✅ Notification channels **implémenté** (DR-002, 2026-06-09)

**Note** : 
- **Maintenance** → Géré dans le dashboard (toggle level ≥ 60)
- **AuditLogs** → Non prioritaire (peu utilisé)

---

## 📄 Documentation

### **📁 Fichiers détaillés par type (CODE EXACT)**
Les fichiers de construction détaillés (migrations, modèles, services, controllers, routes, policies, vues, JavaScript) ont été **archivés** — le code source (`app/controllers/admin_panel/`, `app/policies/`) est la référence vivante.

### **📁 Fichiers par fonctionnalité**

> Les fichiers de construction détaillés (migrations, modèles, services, controllers, policies, vues, JavaScript) ont été **archivés** — le code source (`app/controllers/admin_panel/`, `app/policies/`) est la référence vivante.

---

## 🎯 Fonctionnalités Incluses

### ✅ Payments (Paiements)
- Liste avec filtres (provider, status, date)
- Détails avec panels (Orders, Memberships, Attendances associés)
- CRUD complet

### ✅ Notification channels (Discord webhooks) — DR-002

- CRUD webhooks Discord (SUPERADMIN ≥ 70) — `/admin-panel/notification-channels`
- Toggles par type d'événement (~65 clés), bouton test, échantillons QA, multi-canaux
- Dispatch après confirmation paiement HelloAsso (pas callbacks modèle)
- Gate staging : `ALLOW_DISCORD_NOTIFICATIONS=true`
- Spec : [DR-002-discord-webhook-notifications.md](../../../10-decisions-and-changelog/DR-002-discord-webhook-notifications.md)

---

## ✅ Checklist Globale

### **Phase 8 (Semaine 8+)**
- [x] Controller Payments ✅ **IMPLÉMENTÉ** (index, show, destroy)
- [x] Policy Payments ✅ **IMPLÉMENTÉE** (index/show: level >= 60, destroy: level >= 70 ⚠️)
- [x] Routes Payments ✅ **IMPLÉMENTÉES** (RESTful)
- [x] Vues Payments ✅ **IMPLÉMENTÉES** (index avec filtres Ransack, show avec panels, boutons groupés)
- [x] Menu sidebar ✅ **AJOUTÉ** (sous-menu Commandes)
- [x] Tests RSpec ✅ **22 exemples, 0 échecs**
- [x] Factory Payment ✅ **CRÉÉE**
- [x] Sécurité ✅ **RENFORCÉE** (suppression SUPERADMIN uniquement + disclaimer explicite)

### **Notification channels (DR-002 — 2026-06-09)**
- [x] Migration `notification_channels`, `notification_subscriptions`, `notification_deliveries`
- [x] Models + `NotificationDispatchService`, `DiscordWebhookClient`, delivery job
- [x] Admin CRUD + test + sample events (`NotificationChannelsController`)
- [x] Hooks HelloAsso, contact public, registrations, ~18 admin controllers (`AdminPanel::NotifiesDiscord`)
- [x] Menu sidebar **Notifications**
- [x] Tests RSpec (~65+ examples for registry, dispatch, job, admin requests)

---

## 🔗 Dépendances

- **Orders** : Pour afficher commandes liées aux paiements
- **Memberships** : Pour afficher adhésions liées aux paiements
- **Attendances** : Pour afficher participations liées aux paiements

---

## 📊 Estimation

- **Temps** : 1 semaine
- **Complexité** : ⭐⭐⭐
- **Dépendances** : Commandes, Utilisateurs, Événements

---

**Retour** : [INDEX principal](../INDEX.md)
