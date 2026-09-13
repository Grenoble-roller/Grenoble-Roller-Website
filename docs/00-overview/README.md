---
title: "Grenoble Roller - Overview Complet"
status: "active"
version: "2.1"
created: "2025-01-30"
updated: "2026-08-14"
tags: ["overview", "project", "vision", "architecture", "status"]
---

# Grenoble Roller – Overview Complet du Projet

**Dernière mise à jour** : 2026-08-14

---

## 📋 Vue d'Ensemble

**Grenoble Roller** est une plateforme communautaire Ruby on Rails 8 pour l'association de rollerblading de Grenoble. L'application combine une boutique e-commerce de goodies, un système de gestion d'événements et d'initiations, ainsi qu'un système d'adhésions.

**Repository** : [https://github.com/Grenoble-roller/Grenoble-Roller-Website](https://github.com/Grenoble-roller/Grenoble-Roller-Website)

---

## 🎯 Vision & Objectifs

### Vision
Créer une plateforme complète qui rassemble la communauté roller grenobloise autour de :
- **Achats de goodies** : Boutique avec produits floqués aux couleurs de l'association
- **Événements** : Organisation et participation aux randonnées hebdomadaires
- **Initiations** : Gestion des sessions d'initiation au roller
- **Adhésions** : Gestion des adhésions membres (FFRS + Association)

### Objectifs Métier
- Rassembler la communauté roller grenobloise
- Vendre des produits aux couleurs de l'association (activité accessoire non lucrative)
- Organiser et gérer les événements de randonnée
- Faciliter les initiations au roller
- Gérer les adhésions et membres

---

## 🏗️ Architecture Technique

### Stack Principal
- **Framework** : Ruby on Rails 8.1.1
- **Langage** : Ruby 3.4.2
- **Base de données** : PostgreSQL 16
- **Authentification** : Devise
- **Frontend** : Bootstrap 5.3.2, Stimulus, Turbo
- **Containerisation** : Docker & Docker Compose
- **Déploiement** : Kamal-ready (Dockerfile inclus)

### Architecture Application
```
[Rails Monolithe]
├── Authentification (Devise)
├── E-commerce (Products, Orders, Payments)
├── Événements (Events, Routes, Attendances)
├── Initiations (Event::Initiation, spécifique)
├── Adhésions (Memberships, adulte/enfant)
├── Admin Panel (custom `/admin-panel`, ActiveAdmin legacy)
└── Pages Légales & Conformité (RGPD, Cookies, Umami analytics)
```

### Environnements
- **Développement** : Docker Compose (`ops/dev/`), port `3000` (DB `5434`)
- **Staging** : Docker Compose (`ops/staging/`), port `3001`
- **Production** : Docker Compose (`ops/production/`), port `3002` / `80`

---

## ✅ État d'Implémentation

### Phase 1 : E-commerce (✅ 100% TERMINÉ)

#### Authentification & Autorisation
- ✅ Devise (inscription, connexion, confirmation email)
- ✅ 7 niveaux de rôles (USER → SUPERADMIN)
- ✅ Profils utilisateurs complets
- ✅ Reset de mot de passe
- ✅ Confirmation email avec QR code mobile
- ✅ Rate limiting (rack-attack)
- ✅ Protection Turnstile (Cloudflare) — login, inscription, **formulaire contact**
- ✅ Analytics Umami (consentement cookies analytics requis)

#### E-commerce
- ✅ Catalogue produits (3 catégories : Rollers, Protections, Accessoires)
- ✅ Variantes produits (taille, couleur)
- ✅ Panier d'achat (session + DB pour utilisateurs connectés)
- ✅ Gestion des commandes (CRUD complet)
- ✅ Système de paiement multi-providers (structure prête)
- ✅ Intégration HelloAsso (checkout + polling automatique) ✅ 100%
- ✅ Gestion des stocks
- ✅ Emails de commande (7 templates : confirmation, payé, annulé, préparation, expédié, remboursement demandé, remboursement confirmé)

#### Pages Publiques
- ✅ Homepage complète
- ✅ Pages produits (liste + détail)
- ✅ Pages légales (Mentions légales, RGPD, CGV, CGU, Contact)
- ✅ Gestion des cookies (conforme RGPD 2025)

---

### Phase 2 : Événements & Admin (✅ 95% TERMINÉ)

#### Modèles & Migrations
- ✅ Routes (parcours prédéfinis avec GPX)
- ✅ Events (événements généraux)
- ✅ Event::Initiation (sessions d'initiation spécialisées)
- ✅ Attendances (inscriptions aux événements)
- ✅ OrganizerApplications (demandes d'organisateurs)
- ✅ Partners (partenaires)
- ✅ ContactMessages (messages contact)
- ✅ AuditLogs (traçabilité admin)

#### Controllers & Vues
- ✅ EventsController (CRUD public complet)
- ✅ InitiationsController (CRUD public complet)
- ✅ RoutesController (CRUD public complet)
- ✅ AttendancesController (inscriptions/désinscriptions)
- ✅ Pages événements (liste, détail, création)
- ✅ Pages initiations (liste, détail, inscription)
- ✅ Séparation événements à venir/passés
- ✅ Compteurs d'inscriptions
- ✅ Export iCal par événement
- ✅ Modal d'inscription avec résumé

#### Admin Panel
- ✅ Admin Panel custom (`/admin-panel`) — modules initiations, événements, boutique, adhésions
- ✅ ActiveAdmin legacy (référence / certains exports)
- ✅ Dashboard admin
- ✅ CRUD complet modèles principaux
- ✅ Exports CSV natifs
- ✅ Actions rapides (publier, annuler, etc.)
- ✅ Vue "À valider" pour événements
- ✅ Suivi goodies adhésions (`goodies_distributed`)
- ✅ Logs emails sortants (`outbound_email_logs`)

#### Fonctionnalités Avancées
- ✅ Inscriptions bénévoles
- ✅ Inscriptions enfants (via ChildMembership)
- ✅ Essai gratuit (1 par utilisateur)
- ✅ Gestion équipement (roller_size, réservations par initiation — voir `docs/06-events/roller-stock.md`)
- ✅ Emails automatiques (inscription/désinscription)
- ✅ Rappels événements (optionnels)

---

### Phase 3 : Adhésions (✅ 90% TERMINÉ)

#### Modèles
- ✅ Membership (adhésions adultes)
- ✅ ChildMembership (adhésions enfants)
- ✅ Types : FFRS + Association

#### Fonctionnalités
- ✅ Formulaire d'adhésion adulte
- ✅ Formulaire d'adhésion enfant
- ✅ Intégration HelloAsso (checkout)
- ✅ Polling automatique HelloAsso
- ✅ Gestion statuts (pending, active, expired, cancelled)
- ✅ Calcul dates (1 an à partir de l'adhésion)
- ⚠️ Génération attestation auto (partiellement implémenté)

---

### Tests & Qualité

#### Tests RSpec
- ✅ **166 tests, 0 échec** (dernier run)
  - 135 tests models
  - 12 tests policies
  - 19 tests requests
- ✅ FactoryBot factories pour tous modèles
- ✅ Tests complets counter cache
- ✅ Tests max_participants
- ✅ Tests OrderMailer (7 méthodes)
- ✅ Tests intégration emails événements

#### Qualité Code
- ✅ RuboCop Rails Omakase
- ✅ Brakeman (sécurité)
- ⚠️ Tests Capybara (10 tests system/feature, ChromeDriver non configuré en Docker)

---

### Conformité & Accessibilité

#### Accessibilité (WCAG 2.1 AA)
- ✅ Audit complet réalisé
- ✅ Corrections appliquées
- ✅ Tests Pa11y (6/6 pages conformes)
- ✅ Navigation clavier complète
- ✅ Contraste couleurs conforme
- ✅ Labels ARIA corrects

#### Performance
- ✅ Lighthouse optimisé (meta descriptions, headings)
- ✅ Quick wins appliqués
- ⚠️ Optimisations futures planifiées

#### Conformité Légale
- ✅ Pages légales complètes (5 pages)
- ✅ Gestion cookies RGPD 2025
- ✅ Directive ePrivacy respectée
- ✅ Conformité Code de la consommation (CGV)

---

## 📊 Statistiques du Projet

### Code
- **Controllers** : 19 contrôleurs
- **Models** : ~25 modèles
- **Views** : Templates ERB complets
- **Tests** : 166 tests RSpec (0 échec)

### Documentation
- **Fichiers docs/** : ~100 fichiers markdown
- **Structure** : 13 sections organisées (00-overview → 12-development)
- **ADRs** : À créer (structure prête)

### Features
- **Quick Wins UX** : 33/41 terminés (80%)
- **Améliorations importantes** : ~30 prioritaires identifiées
- **Améliorations futures** : ~33 planifiées

---

## 🚧 Éléments Non Implémentés ou Partiels

### Priorité Haute

1. **Pagination** (Événements, Produits)
   - Non implémentée actuellement
   - Planifiée avec Kaminari/Pagy

2. **Recherche & Filtres** (Événements)
   - Barre de recherche AJAX
   - Filtres (date, route, niveau)
   - Tri personnalisé

3. **Export iCal global**
   - Export par événement ✅
   - Export global de toutes les inscriptions ⚠️

4. **Génération attestation auto**
   - Structure prête
   - Logique conditionnelle à finaliser

### Priorité Moyenne

5. **Newsletter fonctionnelle**
   - Formulaire footer présent
   - Backend + service email à créer

6. **Validation email temps réel**
   - Vérification AJAX si email existe

7. **Panier persistant**
   - Sauvegarde DB pour utilisateurs connectés (partiel)
   - Fusion session/DB à améliorer

8. **Page "Équipe"**
   - Page statique manquante (lien masqué)

### Priorité Basse (Futures)

- Vue calendrier (FullCalendar)
- Duplication événements
- Templates événements
- Liste de souhaits (wishlist)
- Avis clients
- Codes promo
- Statistiques personnelles utilisateur

**Voir détails complets** : [`docs/09-product/todo-restant.md`](../09-product/todo-restant.md)

---

## 📁 Structure de Documentation

```
docs/
├── 00-overview/           # Vue d'ensemble (ce document)
├── 01-ways-of-working/    # Workflow équipe (à compléter)
├── 02-shape-up/           # Méthodologie Shape Up
├── 03-architecture/       # Architecture, ADRs, modèles domaine
├── 04-rails/             # Conventions Rails, setup, sécurité
├── 05-testing/           # Stratégie tests (RSpec)
├── 06-events/            # Documentation événements
├── 07-ops/               # Runbooks (setup, backup, incidents)
├── 08-security-privacy/   # Accessibilité, RGPD, conformité
├── 09-product/           # Product, UX, parcours utilisateur
├── 10-decisions-and-changelog/  # ADRs, DRs, changelog
├── 11-templates/         # Gabarits (ADR, PR, issues)
└── 12-development/       # WIP — fonctionnalités en cours
```

**Index complet** : [`00-overview/README.md`](README.md) (il n'y a pas de `docs/README.md` — voir AGENTS.md)

---

## 📋 Documentation de Référence

### Overview & Audit
- **Vue d'ensemble** : Ce document (`README.md`)
- **État des fonctionnalités** : [`features-status.md`](features-status.md)

### Documentation Clé
- **Setup local** : [`docs/04-rails/setup/local-development.md`](../04-rails/setup/local-development.md)
- **Architecture** : [`docs/03-architecture/system-overview.md`](../03-architecture/system-overview.md)
- **Modèles domaine** : [`docs/03-architecture/domain/models.md`](../03-architecture/domain/models.md)
- **Changelog** : [`docs/10-decisions-and-changelog/CHANGELOG.md`](../10-decisions-and-changelog/CHANGELOG.md)

### Product & UX
- **Backlog UX** : [`docs/09-product/ux-improvements-backlog.md`](../09-product/ux-improvements-backlog.md)
- **Todo restant** : [`docs/09-product/todo-restant.md`](../09-product/todo-restant.md)

### Ops & Deploy
- **Runbooks** : [`docs/07-ops/runbooks/`](../07-ops/runbooks/)
- **Déploiement** : [`docs/07-ops/deployment.md`](../07-ops/deployment.md)
- **Déploiement VPS** : [`docs/07-ops/deploy-vps.md`](../07-ops/deploy-vps.md)

---

## 🎯 Prochaines Étapes Recommandées

### Court Terme (1-2 semaines)
1. ✅ Finaliser pagination événements/produits
2. ✅ Implémenter recherche & filtres événements
3. ✅ Créer page "Équipe"
4. ✅ Newsletter fonctionnelle

### Moyen Terme (1 mois)
5. ⚠️ Finaliser génération attestation auto
6. ⚠️ Améliorer panier persistant
7. ⚠️ Validation email temps réel
8. ⚠️ Export iCal global

### Long Terme (Selon besoins)
- Vue calendrier FullCalendar
- Statistiques personnelles
- Templates événements
- Avis clients

---

## 📝 Notes Importantes

### Méthodologie
- **Shape Up** : Appetite fixe (3 semaines Building + 1 semaine Cooldown), scope flexible
- **YAGNI** : Pas de sur-ingénierie
- **KISS** : Simplicité avant tout

### Déploiement
- **Watchdog** : Déploiement automatique toutes les 5-10 min (cron)
- **Backups** : Automatiques avant chaque déploiement
- **Health checks** : Vérification automatique après déploiement

### Conformité
- **RGPD 2025** : Conforme (pages légales, cookies)
- **Accessibilité** : WCAG 2.1 AA conforme
- **Légal** : Mentions légales, CGV, CGU complètes

---

**Version** : 2.0  
**Dernière mise à jour** : 2026-06-07  
**Maintenu par** : Équipe FlowTech-Lab

