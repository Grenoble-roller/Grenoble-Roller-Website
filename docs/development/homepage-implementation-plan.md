---
title: "Plan d'Implémentation Page d'Accueil - Grenoble Roller"
status: "draft"
version: "2.0"
created: "2025-01-30"
updated: "2025-01-30"
tags: ["homepage", "implementation", "benevoles", "autonomie", "admin"]
---

# Plan d'Implémentation Page d'Accueil - Grenoble Roller

**Dernière mise à jour** : 2026-03-09 (État carousel aligné avec l’app : implémenté ; annonces/galerie/témoignages non faits)

Ce document classe les éléments de la réponse Perplexity par **pertinence** et **faisabilité**, en tenant compte de ce qui existe déjà dans l'application. **TOUTE** la gestion admin est détaillée pour chaque élément.

---

## 🔍 État des Lieux - Ce qui Existe Déjà

### ✅ Infrastructure Disponible
- **Active Storage** : Gestion images (Event.cover_image avec variants)
- **AdminPanel** : Namespace `/admin-panel` avec contrôleurs dédiés
- **Système de rôles** : ORGANIZER (level 40+) peut créer événements/initiations
- **Bootstrap 5** : Carrousel natif disponible
- **Stimulus + Turbo** : Interactivité moderne
- **Design System** : "Liquid" (couleurs, cartes arrondies)
- **Event Model** : `cover_image` avec variants (hero, card, featured, thumb)
- **PagesController** : `@highlighted_event` déjà chargé

### ❌ Ce qui N'Existe Pas Encore
- Galerie photos événements passés
- Système d'annonces/actualités (HomepageAnnouncement)
- Témoignages membres

### ✅ Carrousel Page d'Accueil (HomepageCarousel) — IMPLÉMENTÉ
- Modèle `HomepageCarousel`, migrations (table + position unique), Active Storage `image`
- AdminPanel complet : CRUD, publish/unpublish, move_up/move_down, reorder (endpoint)
- Policy ORGANIZER+ (level ≥ 40) ; accès BaseController level ≥ 30
- Partial `pages/_carousel.html.erb` (Bootstrap 5, actif si slides actifs), fallback hero si vide
- Menu admin « Page d'Accueil » > « Carrousel ». Pas de drag & drop batch dans l’UI (boutons monter/descendre uniquement).

---

## 📊 Éléments Réalisables - Classement par Pertinence & Faisabilité

### 🟢 PRIORITÉ 1 : Impact Haut + Faisabilité Élevée (Sprint 1)

#### 1.1 Système d'Annonces (Announcement)
**Pertinence** : ⭐⭐⭐⭐⭐ (Autonomie bénévoles maximale)  
**Faisabilité** : ⭐⭐⭐⭐⭐ (Simple CRUD Rails)

**Pourquoi prioritaire** :
- Permet aux bénévoles de communiquer rapidement (événements spéciaux, infos importantes)
- Impact immédiat sur l'autonomie
- Implémentation simple (modèle + CRUD + affichage)

**Ce qui existe déjà** :
- ✅ AdminPanel namespace
- ✅ Active Storage pour images
- ✅ Système de rôles (ORGANIZER+)
- ✅ Bootstrap cards pour affichage

**À créer** :
- Modèle `HomepageAnnouncement`
- Migration (title, content, image, pinned, published_at, expires_at, author_id)
- Contrôleur `AdminPanel::HomepageAnnouncementsController`
- Vue `admin_panel/homepage_announcements/`
- Partial `pages/_announcements.html.erb`
- Intégration dans `pages/index.html.erb`

**Estimation** : 4-6h

---

#### 1.2 Carrousel Hero (HomepageCarousel) — ✅ IMPLÉMENTÉ
**Pertinence** : ⭐⭐⭐⭐ (Visibilité immédiate)  
**Faisabilité** : ⭐⭐⭐⭐⭐ (Bootstrap carousel natif)

**État actuel (vérifié)** :
- ✅ Modèle `HomepageCarousel` (title, subtitle, link_url, position, published, published_at, expires_at, image via Active Storage)
- ✅ Migrations : `create_homepage_carousels`, `add_unique_position_to_homepage_carousels`
- ✅ Contrôleur `AdminPanel::HomepageCarouselsController` : index (Ransack, Pagy), show, new, create, edit, update, destroy, publish, unpublish, move_up, move_down, reorder
- ✅ Policy `AdminPanel::HomepageCarouselPolicy` (level ≥ 40) ; accès admin level ≥ 30 dans BaseController
- ✅ Routes `resources :homepage_carousels` avec member (publish, unpublish, move_up, move_down) et collection (reorder)
- ✅ Vues admin : index (filtres, grille, boutons monter/descendre), show, new, edit, _form
- ✅ Partial `pages/_carousel.html.erb` (Bootstrap 5, `HomepageCarousel.active.ordered`), intégré dans `pages/index` ; fallback hero si aucun slide actif
- ⚠️ Réordonnancement : move_up/move_down en place ; pas d’UI drag & drop batch (endpoint `reorder` présent, SortableJS non intégré)

---

### 🟡 PRIORITÉ 2 : Impact Moyen-Haut + Faisabilité Moyenne (Sprint 2)

#### 2.1 Galerie Photos Événements Passés
**Pertinence** : ⭐⭐⭐⭐ (Preuve sociale, engagement)  
**Faisabilité** : ⭐⭐⭐⭐ (Réutilise Event.cover_image existant)

**Pourquoi secondaire** :
- Utilise les images d'événements déjà existantes
- Pas besoin de nouveau modèle (peut utiliser Event directement)
- Impact visuel fort mais moins critique que annonces

**Ce qui existe déjà** :
- ✅ Event.cover_image avec variants
- ✅ Event.past scope
- ✅ Event.visible scope
- ✅ Bootstrap grid pour layout

**À créer** :
- Modèle optionnel `EventGallery` (si besoin métadonnées supplémentaires)
- OU utiliser directement `Event.past.where.not(cover_image: nil)`
- Partial `pages/_gallery.html.erb` (masonry grid ou Bootstrap grid)
- Lightbox (gem `lightbox2` ou Stimulus)
- Filtres optionnels (type événement, mois)

**Estimation** : 4-6h (sans modèle dédié) ou 6-8h (avec modèle)

---

#### 2.2 Section "Activités Principales" (3 Cartes)
**Pertinence** : ⭐⭐⭐ (Navigation claire)  
**Faisabilité** : ⭐⭐⭐⭐⭐ (Statique ou modèle simple)

**Pourquoi secondaire** :
- Peut être statique (pas besoin de CMS)
- OU modèle simple `ActivitySpotlight` pour éditer descriptions
- Navigation déjà présente (liens vers events/initiations)

**Ce qui existe déjà** :
- ✅ Routes `/events` et `/initiations`
- ✅ Bootstrap cards
- ✅ Design system

**À créer** :
- Modèle optionnel `ActivitySpotlight` (si besoin édition)
- OU section statique dans `pages/index.html.erb`
- 3 cartes avec icônes, descriptions, CTA

**Estimation** : 2-3h (statique) ou 4-5h (avec modèle)

---

### 🔵 PRIORITÉ 3 : Impact Moyen + Faisabilité Variable (Sprint 3+)

#### 3.1 Témoignages Membres
**Pertinence** : ⭐⭐⭐ (Authenticité, confiance)  
**Faisabilité** : ⭐⭐⭐ (Modération nécessaire)

**Pourquoi tertiaire** :
- Nécessite collecte de témoignages (processus manuel)
- Modération avant publication
- Impact moyen mais authentique

**Ce qui existe déjà** :
- ✅ User model (pour auteur)
- ✅ Active Storage (avatar optionnel)
- ✅ Système de rôles (modération)

**À créer** :
- Modèle `Testimonial`
- Migration (content, author_name, author_role, author_image, featured, moderated, user_id)
- Formulaire public `/testimonials/new` (optionnel)
- Interface modération AdminPanel
- Partial `pages/_testimonials.html.erb`
- Rotation aléatoire (scope `.random`)

**Estimation** : 6-8h (avec formulaire public + modération)

---

#### 3.2 Hero Section Dynamique (Amélioration)
**Pertinence** : ⭐⭐⭐ (UX améliorée)  
**Faisabilité** : ⭐⭐⭐⭐ (Amélioration existant)

**Pourquoi tertiaire** :
- Hero section existe déjà
- Amélioration plutôt que nouvelle fonctionnalité
- Sous-titre contextuel (prochain événement)

**Ce qui existe déjà** :
- ✅ Hero banner dans `pages/index.html.erb`
- ✅ `@highlighted_event` chargé
- ✅ Design system

**À créer** :
- Améliorer hero avec sous-titre dynamique
- Tagline émotionnel éditable (modèle `HomepageSetting` ou config)
- Carrousel auto-play (si plusieurs images)

**Estimation** : 2-3h

---

## 🎯 Plan d'Implémentation Recommandé

### Sprint 1 (Semaine 1-2) : Autonomie Bénévoles
**Objectif** : Permettre aux bénévoles de communiquer rapidement

1. ✅ **Système d'Annonces** (4-6h)
   - Modèle + CRUD AdminPanel
   - Affichage homepage
   - Publication immédiate (modération = phase 2)

2. ✅ **Carrousel Hero** (6-8h)
   - Modèle + CRUD AdminPanel
   - Drag & drop réordonnement
   - Intégration hero section

**Livrable** : Bénévoles peuvent créer annonces et gérer carrousel

---

### Sprint 2 (Semaine 3-4) : Contenu Visuel
**Objectif** : Enrichir homepage avec contenu visuel

3. ✅ **Galerie Photos** (4-6h)
   - Utiliser Event.cover_image existant
   - Grid responsive + lightbox
   - Filtres optionnels

4. ✅ **Section Activités** (2-3h)
   - 3 cartes statiques ou modèle simple
   - Navigation claire

**Livrable** : Homepage visuellement riche

---

### Sprint 3 (Semaine 5-6) : Engagement Communautaire
**Objectif** : Ajouter authenticité et confiance

5. ✅ **Témoignages** (6-8h)
   - Modèle + collecte + modération
   - Affichage rotation aléatoire

6. ✅ **Améliorations Hero** (2-3h)
   - Sous-titre dynamique
   - Tagline éditable

**Livrable** : Homepage complète et engageante

---

## 🎛️ Gestion Admin Complète - Détails Techniques

Cette section détaille **TOUTE** la gestion admin nécessaire pour chaque élément, en s'inspirant de la structure existante (`AdminPanel::ProductsController`).

---

## 📋 Checklist Détaillée par Élément

### ✅ 1. Système d'Annonces (Announcement)

#### Modèle & Migration
- [ ] Migration `create_homepage_announcements`
  - `title` (string, required)
  - `content` (text, required)
  - `image` (Active Storage, optional)
  - `pinned` (boolean, default: false)
  - `published` (boolean, default: false)
  - `published_at` (datetime)
  - `expires_at` (datetime, optional)
  - `author_id` (references User)
  - `created_at`, `updated_at`

- [ ] Modèle `HomepageAnnouncement`
  - `belongs_to :author, class_name: 'User'`
  - `has_one_attached :image`
  - Scopes : `.published`, `.pinned`, `.not_expired`, `.ordered`
  - Validations : title, content présents

#### AdminPanel - Gestion Complète

**Routes** (`config/routes.rb`) :
```ruby
namespace :admin_panel do
  resources :homepage_announcements, path: "homepage-announcements" do
    member do
      post :publish
      post :unpublish
      post :toggle_pinned
    end
    collection do
      get :export
    end
  end
end
```

**Contrôleur** (`app/controllers/admin_panel/homepage_announcements_controller.rb`) :
- [ ] `index` : Liste avec recherche/filtres (Ransack)
  - Filtres : published, pinned, expired
  - Recherche : titre, contenu
  - Pagination (Pagy, 25 par page)
  - Export CSV optionnel
- [ ] `show` : Détail avec aperçu visuel
- [ ] `new` : Formulaire création
- [ ] `create` : Création avec attribution `author_id = current_user.id`
- [ ] `edit` : Formulaire édition
- [ ] `update` : Mise à jour
- [ ] `destroy` : Suppression avec confirmation
- [ ] `publish` : Action rapide (toggle published = true)
- [ ] `unpublish` : Action rapide (toggle published = false)
- [ ] `toggle_pinned` : Action rapide (toggle pinned)
- [ ] `export` : Export CSV (titre, contenu, dates, statut)

**Policy Pundit** (`app/policies/admin_panel/homepage_announcement_policy.rb`) :
- [ ] Hérite de `AdminPanel::BasePolicy`
- [ ] Permissions : level >= 40 (ORGANIZER+)
- [ ] Méthodes : `index?`, `show?`, `create?`, `update?`, `destroy?`
- [ ] Scope : Tous les annonces (pas de restriction par auteur)

**Vues AdminPanel** :
- [ ] `index.html.erb` :
  - Breadcrumb (`admin_panel/shared/_breadcrumb`)
  - Header avec titre + bouton "Nouvelle annonce"
  - Card filtres/recherche (Ransack form)
  - Tableau responsive avec colonnes :
    - Image (thumbnail 80x80)
    - Titre (lien vers show)
    - Statut badges (publié/brouillon, épinglé)
    - Dates (publié le, expire le)
    - Auteur
    - Actions (voir, éditer, publier/dépublier, épingler, supprimer)
  - Pagination (`admin_panel/shared/_pagination`)
  - Message vide si aucune annonce
- [ ] `show.html.erb` :
  - Breadcrumb
  - Card avec aperçu complet
  - Image (si présente)
  - Métadonnées (dates, auteur, statuts)
  - Actions rapides (publier/dépublier, épingler, supprimer)
- [ ] `new.html.erb` + `edit.html.erb` :
  - Breadcrumb
  - Formulaire (`_form.html.erb`)
- [ ] `_form.html.erb` :
  - Champs : titre, contenu (textarea), image (file_field), dates (datetime_local), épinglé (checkbox)
  - Validation côté client (Stimulus)
  - Preview image si uploadée
  - Boutons : Enregistrer, Enregistrer et publier, Annuler

**Sidebar Navigation** (`app/views/admin/shared/_menu_items.html.erb`) :
- [ ] Ajouter section "Page d'Accueil" (level >= 40)
  - Sous-menu : Annonces, Carrousel, Galerie, Témoignages
  - Icône : `bi-house-door` ou `bi-newspaper`

**Tests** :
- [ ] `spec/policies/admin_panel/homepage_announcement_policy_spec.rb`
  - Tests permissions (ORGANIZER+, ADMIN)
  - Tests scope
- [ ] `spec/requests/admin_panel/homepage_announcements_spec.rb`
  - Tests CRUD complet
  - Tests actions rapides (publish/unpublish/toggle_pinned)
  - Tests permissions (redirections si level < 40)
  - Tests export CSV

#### Affichage Public
- [ ] Partial `app/views/pages/_announcements.html.erb`
  - Section "À la Une" (pinned)
  - Liste chronologique (5-6 dernières)
  - CTA "Voir toutes les actualités" (si > 6)

- [ ] Intégration `pages/index.html.erb`
  - Ajouter section après hero ou avant événements

#### Tests
- [ ] Tests modèle (validations, scopes)
- [ ] Tests contrôleur (CRUD, permissions)
- [ ] Tests vues (affichage)

---

### ✅ 2. Carrousel Hero (HomepageCarousel) — IMPLÉMENTÉ

**Doc dédiée (liens code, routes, vues)** : [homepage-carousel.md](./homepage-carousel.md).

#### Modèle & Migration
- [x] Migration `create_homepage_carousels` (title, subtitle, link_url, position, published, published_at, expires_at)
- [x] Migration `add_unique_position_to_homepage_carousels` (index unique sur position)
- [x] Modèle `HomepageCarousel` : `has_one_attached :image`, scopes `published`, `active`, `ordered`, validations (title, position unique, image si published), Ransack, callbacks (set_published_at, set_default_position)

#### AdminPanel - Gestion Complète
- [x] **Routes** : `resources :homepage_carousels` avec member (publish, unpublish, move_up, move_down) et collection (reorder)
- [x] **Contrôleur** : index (Ransack, filtre published, Pagy), show, new, create, edit, update, destroy, publish, unpublish, move_up, move_down, reorder
- [x] **Policy** : `AdminPanel::HomepageCarouselPolicy` (level ≥ 40), Scope pour organizer_user
- [x] **Vues** : index (breadcrumb, filtre, grille cards avec thumbnail, position, statut, actions éditer / publier-dépublier / monter-descendre / supprimer), show, new, edit, _form (titre, sous-titre, image, link_url, position, published, published_at, expires_at)
- [ ] **Drag & drop batch** : endpoint `reorder` présent ; UI SortableJS non intégrée (réordonnancement par move_up/move_down uniquement)

#### Affichage Public
- [x] Partial `app/views/pages/_carousel.html.erb` : Bootstrap 5 carousel, `HomepageCarousel.active.ordered`, variant image 1600×550, pas de caption (texte dans l’image), indicateurs et contrôles si > 1 slide
- [x] Intégration dans `pages/index.html.erb` ; fallback hero banner si aucun slide actif

#### Tests
- [x] Request spec : GET index (admin, organizer, non connecté), GET new
- [x] Policy spec : `AdminPanel::HomepageCarouselPolicy`
- [ ] Request spec : CRUD complet, publish/unpublish, move_up/move_down, reorder (lacune couverture, voir `docs/05-testing/rspec/coverage-gaps.md`)
- [ ] Model spec : optionnel (validations, scopes)

---

### ✅ 3. Galerie Photos Événements Passés

#### Option A : Sans Modèle Dédié (Recommandé)
- [ ] Utiliser `Event.past.where.not(cover_image: nil)`
- [ ] Partial `app/views/pages/_gallery.html.erb`
  - Bootstrap grid responsive (2-3 colonnes desktop)
  - Images avec `cover_image_card` variant
  - Lightbox (gem `lightbox2` ou Stimulus)

- [ ] Intégration `pages/index.html.erb`
  - Section après événements passés

#### Option B : Avec Modèle Dédié (Si besoin métadonnées)
- [ ] Migration `create_event_galleries`
  - `image` (Active Storage)
  - `caption` (text, optional)
  - `event_id` (references Event, optional)
  - `event_type` (enum: randonnée/cours/communauté)
  - `event_date` (date)
  - `photographer_credit` (string, optional)
  - `uploaded_by_id` (references User)

- [ ] Modèle `EventGallery`
  - `belongs_to :event, optional: true`
  - `belongs_to :uploaded_by, class_name: 'User'`
  - `has_one_attached :image`
  - Scopes : `.by_type`, `.by_month`, `.ordered`

#### AdminPanel (Si Option B) - Gestion Complète

**Routes** (`config/routes.rb`) :
```ruby
namespace :admin_panel do
  resources :event_galleries, path: "event-galleries" do
    collection do
      post :bulk_upload  # Upload multiple
      get :export
    end
  end
end
```

**Contrôleur** (`app/controllers/admin_panel/event_galleries_controller.rb`) :
- [ ] `index` : Grid de thumbnails avec filtres
  - Filtres : type événement, mois, année
  - Recherche : légende, nom événement
  - Pagination (20 par page)
- [ ] `show` : Image complète + métadonnées
- [ ] `new` : Formulaire création
- [ ] `create` : Création avec upload image
- [ ] `edit` : Formulaire édition métadonnées
- [ ] `update` : Mise à jour métadonnées
- [ ] `destroy` : Suppression
- [ ] `bulk_upload` : Upload multiple (5-10 images max)
  - Formulaire avec file_field multiple
  - Traitement en background (job) si > 5 images
- [ ] `export` : Export CSV (métadonnées)

**Policy Pundit** (`app/policies/admin_panel/event_gallery_policy.rb`) :
- [ ] Permissions : level >= 40 (ORGANIZER+)

**Vues AdminPanel** :
- [ ] `index.html.erb` : Grid masonry ou Bootstrap grid
- [ ] `bulk_upload.html.erb` : Formulaire upload multiple
- [ ] `_form.html.erb` : Métadonnées (date, type, légende, crédit photo)

#### Tests
- [ ] Tests affichage galerie
- [ ] Tests lightbox
- [ ] Tests filtres (si implémentés)

---

### ✅ 4. Section "Activités Principales"

#### Option A : Statique (Recommandé pour MVP)
- [ ] Section dans `pages/index.html.erb`
  - 3 cartes Bootstrap
  - Icônes (Bootstrap Icons)
  - Descriptions courtes
  - CTA vers `/events`, `/initiations`, `/about`

#### Option B : Modèle Éditable
- [ ] Migration `create_activity_spotlights`
  - `title` (string)
  - `description` (text)
  - `icon` (string, nom icône Bootstrap)
  - `link_path` (string)
  - `position` (integer)
  - `active` (boolean)

- [ ] Modèle `ActivitySpotlight`
  - Scope `.active`, `.ordered`

**AdminPanel** (Si Option B) :
- [ ] Contrôleur `AdminPanel::ActivitySpotlightsController`
  - CRUD simple
  - Réordonnement (position)
- [ ] Vues AdminPanel (index, show, new, edit)
- [ ] Policy Pundit (level >= 40)

---

### ✅ 5. Témoignages Membres

#### Modèle & Migration
- [ ] Migration `create_testimonials`
  - `content` (text, required, max 300 chars)
  - `author_name` (string, required)
  - `author_role` (string, optional : "Membre depuis 3 ans")
  - `author_image` (Active Storage, optional)
  - `featured` (boolean, default: false)
  - `moderated` (boolean, default: false)
  - `user_id` (references User, optional)
  - `created_at`, `updated_at`

- [ ] Modèle `Testimonial`
  - `belongs_to :user, optional: true`
  - `has_one_attached :author_image`
  - Scopes : `.moderated`, `.featured`, `.random`
  - Validations : content, author_name présents

#### Collecte
- [ ] Option A : Formulaire public `/testimonials/new`
  - Champs : Quote, Nom, Rôle, Email (validation)
  - Envoi → modération

- [ ] Option B : Collecte par bénévoles
  - Formulaire AdminPanel uniquement

#### AdminPanel - Gestion Complète

**Routes** (`config/routes.rb`) :
```ruby
namespace :admin_panel do
  resources :testimonials do
    member do
      post :moderate
      post :toggle_featured
    end
    collection do
      get :pending  # Témoignages en attente modération
      get :export
    end
  end
end
```

**Contrôleur** (`app/controllers/admin_panel/testimonials_controller.rb`) :
- [ ] `index` : Liste avec filtres
  - Filtres : modéré/non modéré, featured, auteur
  - Recherche : contenu, nom auteur
  - Pagination (20 par page)
  - Badge "En attente" pour non modérés
- [ ] `show` : Aperçu complet
- [ ] `new` : Formulaire création (pour bénévoles)
- [ ] `create` : Création avec `moderated = false` par défaut
- [ ] `edit` : Formulaire édition
- [ ] `update` : Mise à jour
- [ ] `destroy` : Suppression
- [ ] `moderate` : Toggle `moderated` (true/false)
- [ ] `toggle_featured` : Toggle `featured`
- [ ] `pending` : Vue spéciale témoignages non modérés
  - Liste avec actions rapides (modérer, supprimer)
- [ ] `export` : Export CSV

**Policy Pundit** (`app/policies/admin_panel/testimonial_policy.rb`) :
- [ ] Permissions : level >= 40 (ORGANIZER+)
- [ ] Scope : Tous les témoignages

**Vues AdminPanel** :
- [ ] `index.html.erb` :
  - Filtres (modéré, featured)
  - Tableau avec colonnes : contenu (tronqué), auteur, rôle, statut, actions
  - Badge "En attente modération" (rouge) si non modéré
- [ ] `pending.html.erb` : Vue dédiée modération
  - Liste témoignages non modérés
  - Actions rapides : Modérer, Supprimer
- [ ] `show.html.erb` : Aperçu avec image auteur si présente
- [ ] `new.html.erb` + `edit.html.erb` : Formulaire
- [ ] `_form.html.erb` :
  - Champs : contenu (textarea, max 300), nom auteur, rôle, image (optionnel)
  - Checkbox "Modéré" (si level >= 60)
  - Checkbox "Featured"

**Formulaire Public** (`app/controllers/testimonials_controller.rb`) :
- [ ] `new` : Formulaire public `/testimonials/new`
- [ ] `create` : Création avec `moderated = false`
  - Message : "Merci ! Votre témoignage sera publié après modération."
  - Email notification aux bénévoles (si configuré)

**Tests** :
- [ ] Tests modèle (validations, scopes, random)
- [ ] Tests contrôleur (CRUD, modération, featured)
- [ ] Tests formulaire public
- [ ] Tests permissions

#### Affichage Public
- [ ] Partial `app/views/pages/_testimonials.html.erb`
  - 3-4 témoignages aléatoires
  - Format citation (italique)
  - Auteur + rôle (gris clair)
  - Avatar optionnel

- [ ] Intégration `pages/index.html.erb`
  - Section avant footer

#### Tests
- [ ] Tests modèle (validations, scopes, random)
- [ ] Tests contrôleur (CRUD, modération)
- [ ] Tests formulaire public (si Option A)

---

## 🎛️ Détails Gestion Admin - Points Communs

### Structure Contrôleur Standard
Tous les contrôleurs AdminPanel suivent le même pattern :
```ruby
module AdminPanel
  class HomepageAnnouncementsController < BaseController
    before_action :set_announcement, only: %i[show edit update destroy publish unpublish]
    before_action :authorize_announcement, only: %i[show edit update destroy publish unpublish]
    
    def index
      authorize [ :admin_panel, HomepageAnnouncement ]
      @q = HomepageAnnouncement.ransack(params[:q])
      @announcements = @q.result.includes(:author)
      @pagy, @announcements = pagy(@announcements.order(created_at: :desc))
    end
    
    # ... autres actions
  end
end
```

### Permissions & BaseController
- **BaseController** : Vérifie `authenticate_admin_user!`
- **Exception initiations** : Level >= 40 (ORGANIZER+)
- **Autres ressources** : Level >= 60 (ADMIN+)
- **Pour homepage content** : Level >= 40 (ORGANIZER+) pour autonomie bénévoles

### Sidebar Navigation
Ajouter dans `app/views/admin/shared/_menu_items.html.erb` :
```erb
<!-- PAGE D'ACCUEIL (level >= 40 : ORGANIZER+) -->
<% if can_access_admin_panel?(40) %>
  <li class="admin-menu-item">
    <a href="#homepage-submenu" 
       class="admin-menu-link <%= 'active' if admin_panel_active?('homepage_announcements') || admin_panel_active?('homepage_carousels') || admin_panel_active?('testimonials') %>"
       data-bs-toggle="collapse"
       aria-expanded="..."
       title="Page d'Accueil">
      <i class="bi bi-house-door admin-menu-icon"></i>
      <span class="admin-menu-label">Page d'Accueil</span>
      <i class="bi bi-chevron-down admin-menu-chevron ms-auto"></i>
    </a>
    <ul class="collapse ..." id="homepage-submenu">
      <li><%= link_to "Annonces", admin_panel_homepage_announcements_path %></li>
      <li><%= link_to "Carrousel", admin_panel_homepage_carousels_path %></li>
      <li><%= link_to "Témoignages", admin_panel_testimonials_path %></li>
    </ul>
  </li>
<% end %>
```

### Partials Partagés AdminPanel
- `admin_panel/shared/_breadcrumb.html.erb` : Breadcrumb navigation
- `admin_panel/shared/_pagination.html.erb` : Pagination Pagy
- `admin_panel/shared/_status_badge.html.erb` : Badges statut

### Recherche & Filtres (Ransack)
Tous les index utilisent Ransack pour recherche/filtres :
```ruby
@q = Model.ransack(params[:q])
@items = @q.result
```

### Exports CSV
Pattern standard pour exports :
```ruby
def export
  authorize [ :admin_panel, Model ]
  @items = Model.all
  respond_to do |format|
    format.csv { send_data ModelExporter.to_csv(@items), filename: "export_#{Time.current.strftime('%Y%m%d')}.csv" }
  end
end
```

### Actions Rapides
Pattern pour actions rapides (publish/unpublish/toggle) :
```ruby
def publish
  if @item.update(published: true, published_at: Time.current)
    flash[:notice] = "Publié avec succès"
  else
    flash[:alert] = "Erreur : #{@item.errors.full_messages.join(', ')}"
  end
  redirect_to admin_panel_item_path(@item)
end
```

### Tests Standards
Chaque ressource nécessite :
- `spec/policies/admin_panel/*_policy_spec.rb` : Tests permissions
- `spec/requests/admin_panel/*_spec.rb` : Tests contrôleur complet
- Tests vues optionnels (si logique complexe)

---

## 🔧 Détails Techniques

### Gems Potentielles
- `ranked-model` : Réordonnement carrousel (drag & drop)
- `lightbox2` : Lightbox galerie (ou Stimulus custom)
- `friendly_id` : Slugs pour annonces (optionnel)

### Stimulus Controllers à Créer
- `carousel_controller.js` : Gestion carrousel (auto-play, pause)
- `gallery_controller.js` : Lightbox galerie
- `sortable_controller.js` : Drag & drop réordonnement (si pas gem)

### Active Storage Variants
- Carrousel hero : `resize_to_fill: [1600, 550]` (ratio 32/11, taille affichée finale 1600×550)
- Annonces : `resize_to_limit: [800, 400]` (ratio 2:1)
- Galerie thumbnails : `resize_to_limit: [400, 300]` (ratio 4:3)
- Témoignages avatar : `resize_to_limit: [100, 100]` (carré)

---

## 📊 Estimation Totale

| Élément | Temps Estimé | Priorité |
|---------|--------------|----------|
| Annonces | 4-6h | 🟢 P1 |
| Carrousel | 6-8h | 🟢 P1 |
| Galerie | 4-6h | 🟡 P2 |
| Activités | 2-3h | 🟡 P2 |
| Témoignages | 6-8h | 🔵 P3 |
| Hero amélioré | 2-3h | 🔵 P3 |
| **TOTAL Sprint 1** | **10-14h** | |
| **TOTAL Sprint 2** | **6-9h** | |
| **TOTAL Sprint 3** | **8-11h** | |
| **TOTAL GLOBAL** | **24-34h** | |

---

## 🎯 Critères de Succès

### Sprint 1
- ✅ Bénévoles peuvent créer/modifier annonces sans développeur
- ✅ Bénévoles peuvent gérer carrousel hero (ajout/suppression/réordonnement)
- ✅ Contenu apparaît sur homepage immédiatement après publication

### Sprint 2
- ✅ Galerie photos événements passés visible
- ✅ Section activités claire et navigable

### Sprint 3
- ✅ Témoignages collectés et affichés
- ✅ Hero section améliorée avec contenu dynamique

---

## 🔗 Références

- **Réflexion initiale** : [`homepage-reflection.md`](./homepage-reflection.md)
- **Documentation principale** : [`../README.md`](../README.md)
- **Architecture** : [`../03-architecture/`](../03-architecture/)
- **AdminPanel** : [`../04-rails/admin-panel/`](../04-rails/admin-panel/)

---

**Dernière mise à jour** : 2026-03-09 (État carousel aligné avec l’app : implémenté ; annonces/galerie/témoignages non faits)
