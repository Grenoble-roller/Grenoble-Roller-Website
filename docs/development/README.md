# 📚 Documentation - Développement

**Section** : Documentation des fonctionnalités en développement

---

## 📋 Vue d'Ensemble

Cette section est réservée pour la documentation des **fonctionnalités en cours de développement** (WIP), des **plans d'implémentation non terminés**, et des **audits nécessitant des actions**.

**Statut actuel** : ⚠️ **Éléments identifiés à implémenter** (voir ci-dessous)

---

## 🔄 Cycle de Vie des Documents

### Quand un document entre dans `development/` ?
- ✅ Fonctionnalité **en cours de développement** (WIP, EN COURS)
- ✅ Plan d'implémentation **non terminé**
- ✅ Audit avec **actions à réaliser**
- ✅ Backlog d'améliorations **non implémentées**
- ✅ Spécifications **non finalisées**

### Quand un document sort de `development/` ?
- ✅ Fonctionnalité **terminée et validée** → Déplacer vers section appropriée
- ✅ Plan **complètement implémenté** → Archiver ou déplacer vers section complétée
- ✅ Audit **toutes actions réalisées** → Déplacer vers section appropriée

**Exemples de déplacements récents** :
- ✅ `admin-panel/` → `04-rails/admin-panel/` (100% complété)
- ✅ `cron/` → `04-rails/background-jobs/` (Solid Queue actif, migration terminée)
- ✅ `phase2/` → `02-shape-up/building/` (Phase 2 terminée)
- ✅ `ux-improvements/` → `09-product/` (Améliorations UX terminées)

---

## 📋 Éléments à Implémenter

**Dernière mise à jour** : 2025-01-30

### 🔴 Priorité Haute

#### Pagination (Partielle)
- ✅ Pagination "Mes sorties" (événements à venir/passés) - **IMPLÉMENTÉ**
- ✅ Pagination événements passés (tableau) - **IMPLÉMENTÉ**
- ⚠️ Pagination événements à venir (liste publique) - **DÉLIBÉRÉMENT LIMITÉE À 6** (minicards pour mise en avant)
- ✅ Pagination initiations (liste publique) - **IMPLÉMENTÉ** (6 minicards à venir + tableau paginé pour passées)
- ❌ Pagination commandes (liste utilisateur) - **À évaluer selon volume**
- ❌ Pagination attendances (admin) - **À évaluer selon volume**

**Note** : Pagy 43 est installé et fonctionnel. La pagination événements/initiations à venir est volontairement limitée à 6 pour mise en avant visuelle.

**Référence** : [`../00-overview/features-status.md`](../00-overview/features-status.md)

---

### 🟡 Priorité Moyenne

#### Page d'Accueil - Amélioration & Autonomie Bénévoles
- ❌ Système de communication bénévoles (carrousel images, annonces, etc.)
- ❌ Interface d'administration autonome pour bénévoles (gestion contenu homepage)

**Impact** : Haut (autonomie bénévoles)  
**Effort** : Moyen  
**Références** :
- [`homepage-quick-wins.md`](./homepage-quick-wins.md) - **NOUVEAU** - Quick wins (difficulté faible + impact élevé)
- [`homepage-implementation-plan.md`](./homepage-implementation-plan.md) - Plan complet avec gestion admin détaillée
- [`homepage-reflection.md`](./homepage-reflection.md) - Réflexion initiale + prompt Perplexity

#### Calendrier Interactif
- ❌ Vue calendrier (FullCalendar) pour événements
- ❌ Vue calendrier pour "Mes sorties"

**Impact** : Moyen  
**Effort** : Moyen  
**Référence** : [`../02-shape-up/building/cycle-01-building-log.md`](../02-shape-up/building/cycle-01-building-log.md)

---

## 📚 Documentation Terminée (Déplacée)

### Phase 2 - Événements & Admin
**Emplacement** : [`../02-shape-up/building/`](../02-shape-up/building/)
- `cycle-01-phase-2-plan.md` - Plan Phase 2 (Events & Admin) ✅ **COMPLETED**
- `phase2-migrations-models.md` - Migrations et modèles Phase 2 ✅ **TERMINÉ**

### Améliorations UX
**Emplacement** : [`../09-product/`](../09-product/)
- `quick-wins-helloasso.md` - Intégration HelloAsso ✅ **100% INTÉGRÉ**
- `ux-improvements-backlog.md` - Référence historique des améliorations UX ✅
- `todo-restant.md` - Récapitulatif des fonctionnalités essentielles terminées ✅

---

## 🔗 Liens Utiles

- **Documentation principale** : [`../README.md`](../README.md)
- **État des fonctionnalités** : [`../00-overview/features-status.md`](../00-overview/features-status.md)
- **Shape Up** : [`../02-shape-up/`](../02-shape-up/)
- **Architecture** : [`../03-architecture/`](../03-architecture/)
- **Product** : [`../09-product/`](../09-product/)

---

**Dernière mise à jour** : 2025-01-30 (Nettoyage complet + réflexion page d'accueil avec autonomie bénévoles)
