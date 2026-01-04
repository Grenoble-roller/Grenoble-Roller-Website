---
title: "Réflexion Page d'Accueil - Grenoble Roller"
status: "draft"
version: "1.0"
created: "2025-01-30"
updated: "2025-01-30"
tags: ["homepage", "ux", "benevoles", "autonomie", "communication"]
---

# Réflexion Page d'Accueil - Grenoble Roller

**Dernière mise à jour** : 2025-01-30

---

## 📋 Contexte

Ce document présente une réflexion sur l'amélioration de la page d'accueil de Grenoble Roller, avec un focus particulier sur l'autonomie des bénévoles pour communiquer et gérer le contenu.

---

## 🎯 Esprit de l'Application

### Vision
**Grenoble Roller** est une plateforme communautaire qui rassemble la communauté roller grenobloise autour de :
- **Événements** : Organisation et participation aux randonnées hebdomadaires
- **Initiations** : Gestion des sessions d'initiation au roller (samedis matin)
- **Boutique** : Vente de goodies aux couleurs de l'association
- **Adhésions** : Gestion des adhésions membres (FFRS + Association)
- **Communauté** : Créer du lien social dans un esprit convivial et sportif

### Valeurs
- **Convivialité** : Esprit communautaire, partage, bienveillance
- **Accessibilité** : Ouvert à tous niveaux (débutants à confirmés)
- **Autonomie** : Les bénévoles doivent pouvoir gérer le contenu sans dépendre des développeurs
- **Simplicité** : Interface claire, intuitive, pas de surcharge cognitive

### Public Cible
- **Membres actifs** : Adhérents participant régulièrement aux événements
- **Nouveaux membres** : Personnes découvrant l'association
- **Visiteurs** : Curieux cherchant des informations
- **Bénévoles** : Organisateurs d'événements, instructeurs d'initiations

---

## 📱 État Actuel de la Page d'Accueil

### Structure Actuelle
1. **Hero Banner** : Titre, description, CTA (événements, connexion, adhésion)
2. **Section "À propos"** : Présentation courte de l'association
3. **Prochain événement mis en avant** : Carte événement featured
4. **Événements à venir** : 6 minicards maximum
5. **Événements passés** : Tableau paginé

### Points Forts
- ✅ Design moderne et attractif
- ✅ Mise en avant du prochain événement
- ✅ Appels à l'action clairs
- ✅ Responsive et accessible

### Points à Améliorer
- ⚠️ Pas de système de communication pour les bénévoles
- ⚠️ Contenu statique (nécessite intervention développeur pour modifications)
- ⚠️ Pas de galerie photos des événements passés
- ⚠️ Pas de témoignages ou retours membres
- ⚠️ Pas de section "actualités" ou "annonces"

---

## 🎨 Prompt pour Perplexity

### Prompt Principal

```
Je développe une plateforme communautaire pour une association de rollerblading à Grenoble (Grenoble Roller). 

CONTEXTE :
- Association à but non lucratif, communauté de 20+ ans
- Organise des randonnées urbaines encadrées et cours d'initiation au roller
- Valeurs : convivialité, accessibilité, autonomie, simplicité
- Public : membres actifs, nouveaux membres, visiteurs, bénévoles organisateurs

PROBLÉMATIQUE PAGE D'ACCUEIL :
Je souhaite améliorer la page d'accueil pour :
1. Permettre aux bénévoles d'être autonomes dans la communication (sans dépendre des développeurs)
2. Créer un espace de communication dynamique (carrousel d'images, annonces, actualités)
3. Mettre en avant l'esprit communautaire et les activités de l'association
4. Faciliter la découverte pour les nouveaux visiteurs

CONTRAINTES TECHNIQUES :
- Stack : Ruby on Rails 8, Bootstrap 5, Stimulus, Turbo
- Design : Système de design "liquid" (couleurs primaires, cartes arrondies)
- Rôles : 7 niveaux (USER → SUPERADMIN), bénévoles = niveau ORGANIZER (40) et plus
- Stockage : Active Storage (images), PostgreSQL

QUESTIONS :
1. Quels éléments de contenu devraient figurer sur une page d'accueil d'association sportive communautaire ?
2. Quelles solutions techniques pour permettre aux bénévoles de gérer du contenu dynamique (carrousel images, annonces) de manière autonome ?
3. Quels patterns UX/UI pour une page d'accueil communautaire conviviale et engageante ?
4. Comment structurer un système de gestion de contenu simple pour bénévoles non-techniques ?
5. Quelles bonnes pratiques pour une galerie photos d'événements passés ?
6. Comment intégrer des témoignages ou retours membres de manière authentique ?

Merci de proposer des solutions concrètes, des exemples d'implémentation Rails, et des recommandations UX/UI adaptées à une association sportive communautaire.
```

---

## 💡 Suggestions d'Implémentation

### 1. Système de Communication Bénévoles

#### Option A : Carrousel d'Images avec Admin Panel
**Description** : Carrousel d'images en haut de page, géré via ActiveAdmin

**Avantages** :
- ✅ Intégration native avec ActiveAdmin existant
- ✅ Upload images via Active Storage
- ✅ Ordre personnalisable (drag & drop)
- ✅ Dates de publication (début/fin)
- ✅ Visibilité par rôle (public, membres, etc.)

**Implémentation** :
```ruby
# Modèle
class HomepageCarousel < ApplicationRecord
  has_one_attached :image
  validates :title, :image, presence: true
  scope :active, -> { where('start_at <= ? AND (end_at IS NULL OR end_at >= ?)', Time.current, Time.current) }
  scope :ordered, -> { order(:position, :created_at) }
end

# ActiveAdmin
ActiveAdmin.register HomepageCarousel do
  permit_params :title, :description, :link_url, :image, :position, :start_at, :end_at, :visible_to
  
  # Interface drag & drop pour réordonner
end
```

**Vue** :
```erb
<!-- Carrousel Bootstrap 5 -->
<div id="homepageCarousel" class="carousel slide" data-bs-ride="carousel">
  <% @carousel_items.each_with_index do |item, index| %>
    <div class="carousel-item <%= 'active' if index == 0 %>">
      <%= image_tag item.image, class: "d-block w-100", alt: item.title %>
      <div class="carousel-caption">
        <h3><%= item.title %></h3>
        <% if item.link_url.present? %>
          <%= link_to "En savoir plus", item.link_url, class: "btn btn-light" %>
        <% end %>
      </div>
    </div>
  <% end %>
</div>
```

#### Option B : Section "Annonces" avec Cards
**Description** : Section d'annonces/actualités avec cards cliquables

**Avantages** :
- ✅ Plus flexible (texte + image)
- ✅ Possibilité de catégoriser (événement, info, partenariat)
- ✅ Format blog-like simple

**Implémentation** :
```ruby
class HomepageAnnouncement < ApplicationRecord
  has_one_attached :image
  enum category: { event: 0, info: 1, partnership: 2, community: 3 }
  scope :published, -> { where(published: true).where('published_at <= ?', Time.current) }
  scope :ordered, -> { order(published_at: :desc) }
end
```

### 2. Galerie Photos Événements Passés

**Description** : Section galerie avec photos des événements récents

**Implémentation** :
- Utiliser les `cover_image` des événements passés
- Grid responsive (Bootstrap grid)
- Lightbox pour agrandir les images
- Filtre par type (événements, initiations)

**Modèle** :
```ruby
# Utiliser Event.cover_image existant
# Scope dans EventsController
@recent_events_with_images = Event.visible.past
  .where.not(cover_image: nil)
  .order(start_at: :desc)
  .limit(12)
```

### 3. Témoignages Membres

**Description** : Section témoignages avec avatars et citations

**Implémentation** :
```ruby
class Testimonial < ApplicationRecord
  belongs_to :user, optional: true
  validates :content, :author_name, presence: true
  scope :published, -> { where(published: true).order(:position, :created_at) }
end
```

**Interface Admin** :
- Formulaire simple (nom, contenu, photo optionnelle)
- Position pour ordre d'affichage
- Publication/dépublier

### 4. Section "Actualités" ou "Dernières Nouvelles"

**Description** : Blog-like simple pour annonces importantes

**Implémentation** :
```ruby
class NewsItem < ApplicationRecord
  has_one_attached :image
  belongs_to :author, class_name: 'User'
  scope :published, -> { where(published: true).where('published_at <= ?', Time.current) }
end
```

**Fonctionnalités** :
- Éditeur de texte simple (pas de WYSIWYG complexe)
- Upload image
- Date de publication
- Auteur (bénévole)

---

## 🏗️ Architecture Proposée

### Modèles à Créer

1. **HomepageCarousel** (ou **HomepageSlide**)
   - `title` (string)
   - `description` (text, optionnel)
   - `image` (Active Storage)
   - `link_url` (string, optionnel)
   - `position` (integer, pour ordre)
   - `start_at` (datetime)
   - `end_at` (datetime, optionnel)
   - `visible_to` (enum: public, members_only)

2. **HomepageAnnouncement** (ou **NewsItem**)
   - `title` (string)
   - `content` (text)
   - `image` (Active Storage, optionnel)
   - `category` (enum: event, info, partnership, community)
   - `link_url` (string, optionnel)
   - `author_id` (references User)
   - `published` (boolean)
   - `published_at` (datetime)
   - `position` (integer)

3. **Testimonial**
   - `content` (text)
   - `author_name` (string)
   - `author_role` (string, optionnel : "Membre depuis 5 ans", etc.)
   - `author_image` (Active Storage, optionnel)
   - `published` (boolean)
   - `position` (integer)

### Contrôleurs

- `HomepageController` ou extension de `PagesController`
  - `index` : Affiche tous les éléments dynamiques
  - Logique de récupération des différents contenus

### Vues

- `pages/index.html.erb` : Structure principale
- Partials :
  - `_carousel.html.erb` : Carrousel d'images
  - `_announcements.html.erb` : Section annonces
  - `_gallery.html.erb` : Galerie photos
  - `_testimonials.html.erb` : Témoignages

### ActiveAdmin

- Interfaces d'administration pour chaque modèle
- Permissions : ORGANIZER (level 40) et plus peuvent créer/modifier
- Interface drag & drop pour réordonner (gem `ranked-model`)

---

## 🎯 Priorités d'Implémentation

### Phase 1 : Communication Bénévoles (Priorité Haute)
1. ✅ Créer modèle `HomepageCarousel`
2. ✅ Interface ActiveAdmin pour gestion carrousel
3. ✅ Intégrer carrousel dans homepage
4. ✅ Permissions (ORGANIZER+ peuvent gérer)

### Phase 2 : Contenu Dynamique (Priorité Moyenne)
1. ✅ Créer modèle `HomepageAnnouncement`
2. ✅ Section annonces sur homepage
3. ✅ Interface admin simple

### Phase 3 : Engagement Communautaire (Priorité Basse)
1. ✅ Galerie photos événements passés
2. ✅ Témoignages membres
3. ✅ Section actualités

---

## 📝 Checklist Implémentation

### Modèles & Migrations
- [ ] Migration `create_homepage_carousels`
- [ ] Migration `create_homepage_announcements`
- [ ] Migration `create_testimonials`
- [ ] Modèles avec validations
- [ ] Scopes (published, active, ordered)

### ActiveAdmin
- [ ] Interface `HomepageCarousel`
- [ ] Interface `HomepageAnnouncement`
- [ ] Interface `Testimonial`
- [ ] Permissions Pundit (ORGANIZER+)

### Vues & Partials
- [ ] Partial `_carousel.html.erb`
- [ ] Partial `_announcements.html.erb`
- [ ] Partial `_gallery.html.erb`
- [ ] Partial `_testimonials.html.erb`
- [ ] Intégration dans `pages/index.html.erb`

### Contrôleur
- [ ] `PagesController#index` : Charger tous les contenus dynamiques
- [ ] Optimisation requêtes (includes, eager loading)

### Tests
- [ ] Tests modèles
- [ ] Tests contrôleur
- [ ] Tests permissions
- [ ] Tests vues (si nécessaire)

---

## 🔗 Références

- **Plan d'implémentation détaillé** : [`homepage-implementation-plan.md`](./homepage-implementation-plan.md) - **NOUVEAU** - Éléments réalisables classés par pertinence et faisabilité
- **Documentation principale** : [`../README.md`](../README.md)
- **État des fonctionnalités** : [`../00-overview/features-status.md`](../00-overview/features-status.md)
- **Architecture** : [`../03-architecture/`](../03-architecture/)
- **Design System** : Bootstrap 5 + Liquid Design

---

**Dernière mise à jour** : 2025-01-30
