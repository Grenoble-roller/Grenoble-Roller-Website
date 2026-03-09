# Carrousel hero (HomepageCarousel)

**Dernière mise à jour** : 2026-03-09

Documentation dédiée au carrousel de la page d’accueil : spécifications, emplacement des textes, formulaire admin, liens vers le code.

---

## Taille affichée et ratio

- **Taille affichée finale** : **1600×550** px (largeur × hauteur).
- **Ratio** : 1600/550 (≈ 32/11).
- Les images sont redimensionnées via `resize_to_fill: [1600, 550]` pour garder ce ratio partout (bandeau public, aperçu formulaire, aperçu show admin).

---

## Où sont les textes

- **Sur le site (public)** : aucun titre ni sous-titre n’est affiché sur le slide. **Tout le texte doit être intégré dans l’image** (conception graphique 1600×550).
- **En administration** :
  - **Titre** : obligatoire, utilisé pour la liste des slides, le breadcrumb et l’accessibilité (aria-label des indicateurs). Usage interne uniquement.
  - **Description** (champ « Description », ex-sous-titre) : optionnel, notes pour les bénévoles, **non affichées sur le site**.

---

## Comportement du carrousel public

- Bootstrap 5 carousel (fade), avec auto-play et pause au survol (`carousel_controller.js`).
- Indicateurs (puces) : très petits (3×3 px) pour ne pas masquer l’image ; zone tactile 45×45 px conservée (padding).
- Pas de caption / overlay : pas de « En savoir plus » ni texte par-dessus l’image.
- Lien optionnel : clic sur toute l’image si `link_url` est renseigné (ouverture dans nouvel onglet si URL externe).

---

## Formulaire admin (nouveau / modifier)

- **Informations** : Titre *, Description (optionnel), Lien URL, Position, dates (published_at, expires_at), case à cocher Publié.
- **Image** :
  - Upload au format d’origine ; texte d’aide : « Bandeau hero 1600×550 (ratio 32/11) : intégrez tout le texte dans l’image ».
  - **Aperçu bandeau (1600×550)** : bloc avec `aspect-ratio: 1600/550` et image en `resize_to_fill: [1600, 550]` pour refléter le rendu réel.
- Aperçu en direct au choix du fichier (Stimulus `carousel_form_controller.js`).

Référence : `app/views/admin_panel/homepage_carousels/_form.html.erb`.

---

## Fichiers principaux

| Rôle | Fichier |
|------|--------|
| Partial carousel public | `app/views/pages/_carousel.html.erb` |
| Intégration homepage | `app/views/pages/index.html.erb` |
| Styles hero carousel (ratio, indicateurs, image) | `app/assets/stylesheets/_style.scss` — bloc `#homepageCarousel.hero-carousel` |
| Variant image public | `resize_to_fill: [1600, 550]` dans `_carousel.html.erb` |
| Formulaire admin | `app/views/admin_panel/homepage_carousels/_form.html.erb` |
| Show admin (aperçu) | `app/views/admin_panel/homepage_carousels/show.html.erb` |
| Contrôleur carousel (auto-play, pause) | `app/javascript/controllers/carousel_controller.js` |
| Aperçu image formulaire | `app/javascript/controllers/carousel_form_controller.js` |
| Contrôleur CRUD admin | `app/controllers/admin_panel/homepage_carousels_controller.rb` |
| Routes | `resources :homepage_carousels` (member: publish, unpublish, move_up, move_down ; collection: reorder) |

---

## Doc associée

- [homepage-implementation-plan.md](./homepage-implementation-plan.md) — Plan global homepage (état carousel, annonces, galerie, témoignages).
- [homepage-reflection.md](./homepage-reflection.md) — Réflexion initiale et checklist carousel.
