---
title: "Quick Wins Homepage - Difficulté Faible + Impact Élevé"
status: "draft"
version: "1.0"
created: "2025-01-30"
updated: "2025-01-30"
tags: ["homepage", "quick-wins", "low-effort", "high-impact"]
---

# Quick Wins Homepage - Difficulté Faible + Impact Élevé

**Dernière mise à jour** : 2025-01-30

Ce document liste les éléments à mettre en place avec **difficulté faible** et **impact élevé** pour améliorer la page d'accueil.

---

## 🎯 Critères de Sélection

- **Difficulté** : ⭐⭐⭐⭐⭐ (Très facile) ou ⭐⭐⭐⭐ (Facile)
- **Impact** : ⭐⭐⭐⭐⭐ (Très élevé) ou ⭐⭐⭐⭐ (Élevé)
- **Temps estimé** : 1-6h maximum
- **Dépendances** : Minimales (utilise infrastructure existante)

---

## 🟢 TOP 3 - Impact Maximum + Difficulté Minimale

### 1. Section "Activités Principales" (Statique)
**Impact** : ⭐⭐⭐⭐ (Navigation claire, orientation utilisateur)  
**Difficulté** : ⭐⭐⭐⭐⭐ (Très facile - HTML/CSS pur)  
**Temps** : 2-3h

**Pourquoi prioritaire** :
- ✅ Navigation claire vers les 3 activités principales
- ✅ Aucun modèle/contrôleur nécessaire (statique)
- ✅ Impact immédiat sur l'UX
- ✅ Utilise Bootstrap cards existantes

**Ce qui existe déjà** :
- ✅ Routes `/events` et `/initiations`
- ✅ Bootstrap cards et design system
- ✅ Icônes Bootstrap Icons

**À créer** :
- Section HTML dans `pages/index.html.erb`
- 3 cartes avec icônes, descriptions courtes, CTA
- Styles CSS (déjà dans design system)

**Implémentation** :
```erb
<!-- Section Activités -->
<section class="container py-5">
  <h2 class="h3 fw-bold mb-4 text-center">Nos Activités</h2>
  <div class="row g-4">
    <div class="col-md-4">
      <div class="card card-liquid h-100">
        <div class="card-body text-center">
          <i class="bi bi-calendar-event fs-1 text-liquid-primary mb-3"></i>
          <h3 class="h5">Randonnées</h3>
          <p>Sorties urbaines encadrées pour tous niveaux</p>
          <%= link_to "Voir le planning", events_path, class: "btn btn-liquid-primary" %>
        </div>
      </div>
    </div>
    <!-- ... 2 autres cartes -->
  </div>
</section>
```

**Emplacement** : Après section "À propos", avant événements

---

### 2. Système d'Annonces (Version Simplifiée)
**Impact** : ⭐⭐⭐⭐⭐ (Autonomie bénévoles maximale)  
**Difficulté** : ⭐⭐⭐⭐ (Facile - CRUD Rails standard)  
**Temps** : 4-6h

**Pourquoi prioritaire** :
- ✅ Permet aux bénévoles de communiquer rapidement
- ✅ Impact immédiat sur l'autonomie
- ✅ CRUD Rails standard (pas de complexité)

**Version simplifiée** (sans modération initiale) :
- Modèle simple (title, content, image optionnel, published, published_at)
- CRUD AdminPanel basique
- Affichage homepage (section "À la Une")

**Ce qui existe déjà** :
- ✅ AdminPanel namespace
- ✅ Active Storage
- ✅ Système de rôles (ORGANIZER+)
- ✅ Bootstrap cards

**À créer** :
- Modèle `HomepageAnnouncement` (5 champs)
- Contrôleur AdminPanel (CRUD standard)
- Vues AdminPanel (index, new, edit, show)
- Partial `pages/_announcements.html.erb`
- Intégration homepage

**Simplifications** :
- Pas de modération (publication directe)
- Pas d'expiration automatique (optionnel)
- Pas d'épinglage (ajoutable plus tard)

---

### 3. Galerie Photos Événements Passés (Sans Modèle)
**Impact** : ⭐⭐⭐⭐ (Preuve sociale, engagement)  
**Difficulté** : ⭐⭐⭐⭐ (Facile - Réutilise Event existant)  
**Temps** : 3-4h

**Pourquoi prioritaire** :
- ✅ Utilise les images d'événements déjà existantes
- ✅ Aucun modèle à créer
- ✅ Impact visuel fort
- ✅ Preuve sociale pour nouveaux visiteurs

**Ce qui existe déjà** :
- ✅ `Event.cover_image` avec variants
- ✅ `Event.past` scope
- ✅ `Event.visible` scope
- ✅ Bootstrap grid

**À créer** :
- Partial `pages/_gallery.html.erb`
- Grid responsive (Bootstrap)
- Lightbox simple (gem `lightbox2` ou Stimulus basique)
- Intégration homepage

**Implémentation** :
```ruby
# Dans PagesController#index
@recent_events_with_images = Event.visible.past
  .where.not(cover_image: nil)
  .order(start_at: :desc)
  .limit(8)
```

```erb
<!-- Galerie -->
<section class="container py-5">
  <h2 class="h3 fw-bold mb-4">Nos Derniers Événements</h2>
  <div class="row g-3">
    <% @recent_events_with_images.each do |event| %>
      <div class="col-6 col-md-4 col-lg-3">
        <%= link_to event_path(event), data: { lightbox: "gallery" } do %>
          <%= image_tag event.cover_image_card, class: "img-fluid rounded", alt: event.title %>
        <% end %>
      </div>
    <% end %>
  </div>
</section>
```

---

## 🟡 BONUS - Améliorations Rapides (< 2h chacune)

### 4. Compteurs Social Proof
**Impact** : ⭐⭐⭐ (Confiance, preuve sociale)  
**Difficulté** : ⭐⭐⭐⭐⭐ (Très facile - Utilise données existantes)  
**Temps** : 1h

**Implémentation** :
- Utiliser `@users_count`, `@events_count`, `@attendances_count` déjà chargés dans `PagesController`
- Section avec 3 compteurs (Membres, Événements, Participations)
- Design simple avec icônes

**Emplacement** : Après hero, avant "À propos"

---

### 5. Hero Section Améliorée (Sous-titre Dynamique)
**Impact** : ⭐⭐⭐ (UX améliorée)  
**Difficulté** : ⭐⭐⭐⭐ (Facile - Amélioration existant)  
**Temps** : 1-2h

**Améliorations** :
- Sous-titre dynamique avec prochain événement (si `@highlighted_event` présent)
- Format : "Prochaine sortie : [Titre] le [Date]"
- Sinon, sous-titre générique

**Ce qui existe déjà** :
- ✅ `@highlighted_event` chargé dans `PagesController`
- ✅ Hero banner existant

**À modifier** :
- `pages/index.html.erb` : Améliorer sous-titre hero

---

### 6. Section "Pourquoi Nous Rejoindre ?" (Statique)
**Impact** : ⭐⭐⭐ (Valeurs, conversion)  
**Difficulté** : ⭐⭐⭐⭐⭐ (Très facile - HTML/CSS)  
**Temps** : 1-2h

**Contenu** :
- 4 cartes avec valeurs : Convivialité, Sécurité, Dynamisme, Respect
- Icônes Bootstrap
- Descriptions courtes

**Emplacement** : Après "À propos", avant activités

---

## 📊 Tableau Comparatif

| Élément | Impact | Difficulté | Temps | Priorité |
|---------|--------|------------|-------|----------|
| **1. Activités (statique)** | ⭐⭐⭐⭐ | ⭐⭐⭐⭐⭐ | 2-3h | 🟢 P1 |
| **2. Annonces (simplifié)** | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐ | 4-6h | 🟢 P1 |
| **3. Galerie (sans modèle)** | ⭐⭐⭐⭐ | ⭐⭐⭐⭐ | 3-4h | 🟢 P1 |
| **4. Compteurs** | ⭐⭐⭐ | ⭐⭐⭐⭐⭐ | 1h | 🟡 P2 |
| **5. Hero amélioré** | ⭐⭐⭐ | ⭐⭐⭐⭐ | 1-2h | 🟡 P2 |
| **6. Pourquoi rejoindre** | ⭐⭐⭐ | ⭐⭐⭐⭐⭐ | 1-2h | 🟡 P2 |

**TOTAL Sprint Quick Wins** : **12-18h** (2-3 jours de travail)

---

## 🎯 Plan d'Action Recommandé

### Jour 1 (6-8h) : Impact Maximum
1. ✅ **Section Activités** (2-3h) - Navigation claire
2. ✅ **Galerie Photos** (3-4h) - Preuve sociale
3. ✅ **Compteurs Social Proof** (1h) - Confiance

**Livrable** : Homepage visuellement enrichie

---

### Jour 2 (4-6h) : Autonomie Bénévoles
4. ✅ **Système d'Annonces** (4-6h) - Communication autonome

**Livrable** : Bénévoles peuvent créer annonces

---

### Jour 3 (2-4h) : Améliorations UX
5. ✅ **Hero amélioré** (1-2h) - Sous-titre dynamique
6. ✅ **Section "Pourquoi"** (1-2h) - Valeurs

**Livrable** : Homepage complète et engageante

---

## ✅ Checklist Implémentation

### Section Activités (Statique)
- [ ] Créer section HTML dans `pages/index.html.erb`
- [ ] 3 cartes : Randonnées, Initiations, Boutique
- [ ] Icônes Bootstrap appropriées
- [ ] Descriptions courtes et claires
- [ ] CTA vers routes existantes
- [ ] Styles responsive (mobile-first)
- [ ] Test affichage mobile/desktop

### Système d'Annonces (Simplifié)
- [ ] Migration `create_homepage_announcements`
  - `title` (string)
  - `content` (text)
  - `image` (Active Storage, optional)
  - `published` (boolean, default: false)
  - `published_at` (datetime)
  - `author_id` (references User)
- [ ] Modèle `HomepageAnnouncement`
- [ ] Contrôleur `AdminPanel::HomepageAnnouncementsController` (CRUD)
- [ ] Policy Pundit (level >= 40)
- [ ] Vues AdminPanel (index, new, edit, show, _form)
- [ ] Partial `pages/_announcements.html.erb`
- [ ] Intégration homepage
- [ ] Tests basiques (CRUD, permissions)

### Galerie Photos (Sans Modèle)
- [ ] Charger `@recent_events_with_images` dans `PagesController#index`
- [ ] Partial `pages/_gallery.html.erb`
- [ ] Grid Bootstrap responsive
- [ ] Lightbox (gem `lightbox2` ou Stimulus)
- [ ] Intégration homepage
- [ ] Test affichage (si événements avec images)

### Compteurs Social Proof
- [ ] Section avec 3 compteurs (utilise variables existantes)
- [ ] Icônes Bootstrap
- [ ] Design cohérent avec design system
- [ ] Intégration homepage

### Hero Amélioré
- [ ] Modifier sous-titre hero dans `pages/index.html.erb`
- [ ] Logique conditionnelle (si `@highlighted_event` présent)
- [ ] Format dynamique avec date événement
- [ ] Fallback sous-titre générique

### Section "Pourquoi Rejoindre"
- [ ] Section HTML avec 4 cartes valeurs
- [ ] Icônes Bootstrap
- [ ] Descriptions courtes
- [ ] Styles cohérents

---

## 🔗 Références

- **Plan complet** : [`homepage-implementation-plan.md`](./homepage-implementation-plan.md)
- **Réflexion initiale** : [`homepage-reflection.md`](./homepage-reflection.md)
- **Documentation principale** : [`../README.md`](../README.md)

---

**Dernière mise à jour** : 2025-01-30
