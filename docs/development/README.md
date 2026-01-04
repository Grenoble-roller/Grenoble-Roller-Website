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
- ❌ Pagination produits (liste boutique)
- ❌ Pagination commandes (liste utilisateur)
- ❌ Pagination attendances (admin)

**Note** : Pagy 43 est installé et fonctionnel. La pagination événements/initiations à venir est volontairement limitée à 6 pour mise en avant visuelle.

**Référence** : [`../00-overview/features-status.md`](../00-overview/features-status.md)

#### Recherche & Filtres Événements (Partielle)
- ✅ Filtres basiques (route, niveau) - **IMPLÉMENTÉ**
- ❌ Barre de recherche AJAX (titre, description, lieu)
- ❌ Tri personnalisé (Date, Popularité, Distance, Nouveautés)
- ❌ Filtres avancés combinés avec tags actifs

**Référence** : [`../00-overview/features-status.md`](../00-overview/features-status.md)

---

### 🟡 Priorité Moyenne

#### Newsletter
- ✅ Formulaire footer présent
- ❌ Backend avec service email
- ❌ Gestion abonnés
- ❌ Templates newsletter

**Impact** : Haut  
**Effort** : Moyen  
**Référence** : [`../00-overview/features-status.md`](../00-overview/features-status.md)

#### Pages Statiques Manquantes
- ❌ Page "Équipe" (lien masqué actuellement)
- ❌ Page "Carrières" (si recrutement prévu)
- ❌ Page "Blog" (si blog prévu)

**Impact** : Faible  
**Effort** : Faible (pages statiques)  
**Référence** : [`../00-overview/features-status.md`](../00-overview/features-status.md)

#### Validation Email & Page Bienvenue
- ✅ Validation email en temps réel (AJAX) - **IMPLÉMENTÉ** (`/users/check_email`)
- ✅ Page de bienvenue après inscription (`/welcome`) - **IMPLÉMENTÉ**

**Note** : Ces fonctionnalités sont implémentées mais listées comme non implémentées dans `features-status.md` (document à mettre à jour).

#### Export iCal Global
- ✅ Export iCal par événement - **IMPLÉMENTÉ**
- ❌ Export global (toutes inscriptions en une fois)

**Impact** : Moyen  
**Effort** : Faible  
**Référence** : [`../00-overview/features-status.md`](../00-overview/features-status.md)

#### Génération Attestation Auto FFRS
- ✅ Structure prête
- ⚠️ Logique conditionnelle (si toutes réponses NON → génération auto)

**Impact** : Moyen  
**Effort** : Moyen (4h estimées)  
**Référence** : [`../09-product/adhesions-implementation-status.md`](../09-product/adhesions-implementation-status.md)

#### Tests Capybara
- ✅ Tests créés (57 tests passent)
- ✅ ChromeDriver configuré en Docker (pour tests JavaScript) - **IMPLÉMENTÉ**

**Note** : Chrome installé dans `Dockerfile.dev`, configuration `selenium_chrome_headless` active, 4 tests JS fonctionnels.

**Référence** : [`../00-overview/features-status.md`](../00-overview/features-status.md)

#### Calendrier Interactif
- ❌ Vue calendrier (FullCalendar) pour événements
- ❌ Vue calendrier pour "Mes sorties"

**Impact** : Moyen  
**Effort** : Moyen  
**Référence** : [`../02-shape-up/building/cycle-01-building-log.md`](../02-shape-up/building/cycle-01-building-log.md)

---

### 🟢 Priorité Basse (Améliorations Futures)

#### Admin Panel (Améliorations)
- ❌ Bulk actions (sélection multiple, actions en masse)
- ❌ Recherche globale (Events, Users, Orders)
- ❌ Menu groupé ("Événements" → Events, Routes, Attendances)
- ❌ Exports avancés (CSV personnalisé, PDF)
- ❌ Dashboard avec graphiques (événements/mois, inscriptions, revenus)
- ❌ Notifications admin (alertes)
- ❌ Workflow modération avec commentaires
- ❌ Rapports automatiques (email)
- ❌ Audit trail visuel

**Impact** : Moyen  
**Effort** : Élevé  
**Référence** : [`../00-overview/features-status.md`](../00-overview/features-status.md)

#### Performance & Optimisation
- ❌ Tests de charge (JMeter/k6)
- ❌ Optimisation requêtes (audit N+1 complet)
- ❌ CDN et compression

**Note** : Cache natif Rails disponible et suffisant pour les besoins actuels.

**Impact** : Moyen  
**Effort** : Élevé  
**Référence** : [`../02-shape-up/building/cycle-01-building-log.md`](../02-shape-up/building/cycle-01-building-log.md)

#### Boutique (Améliorations)
- ❌ Galerie d'images (carrousel plusieurs images)
- ❌ Suggestions produits ("Produits similaires")
- ❌ Comparaison produits
- ❌ Liste de souhaits (wishlist)
- ❌ Avis clients (notes et commentaires)
- ❌ Codes promo

**Impact** : Moyen  
**Effort** : Élevé  
**Note** : Dépriorisé (peu de produits ~6-7)  
**Référence** : [`../00-overview/features-status.md`](../00-overview/features-status.md)

#### Événements (Améliorations Avancées)
- ❌ Carte interactive (points événements, filtrage géographique)
- ❌ Suggestions personnalisées (basé sur historique)
- ❌ Filtres sauvegardés (favoris)
- ❌ Inscription avec paiement intégré
- ❌ Inscription groupée (plusieurs personnes)
- ❌ QR code confirmation
- ❌ Éditeur WYSIWYG description (Trix, TinyMCE)
- ❌ Planification récurrente (tous les vendredis du mois)
- ❌ Historique modifications événement

**Impact** : Moyen  
**Effort** : Élevé  
**Référence** : [`../00-overview/features-status.md`](../00-overview/features-status.md)

#### Utilisateur (Améliorations)
- ❌ Statistiques personnelles (graphiques)
- ❌ Historique complet (sorties annulées incluses)
- ❌ Rappels personnalisés (paramètres globaux)
- ❌ Partage de ses sorties (lien public)
- ❌ Onboarding interactif (tour guidé)

**Impact** : Faible  
**Effort** : Élevé  
**Référence** : [`../00-overview/features-status.md`](../00-overview/features-status.md)

#### Homepage (Améliorations)
- ❌ Section "Derniers événements" (carrousel)
- ❌ Section "Tarifs d'adhésion" (tableau)
- ❌ Témoignages membres
- ❌ Galerie photos événements passés
- ❌ Carte interactive (points départ récurrents)

**Impact** : Faible  
**Effort** : Moyen  
**Référence** : [`../00-overview/features-status.md`](../00-overview/features-status.md)

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

**Dernière mise à jour** : 2025-01-30 (Audit complet documentation)
