# Bannière annonces (HomepageCarousel)

**Dernière mise à jour** : 2026-03-09

Documentation dédiée à la **bannière annonces** de la page d’accueil : le carousel est affiché **sous le hero** (hero fixe pitch + CTA toujours affiché en tête). Spécifications, emplacement des textes, formulaire admin, liens vers le code.

---

## Taille affichée et ratio

- **Hero** : bloc statique (pitch + CTA), pas d’image carousel. Partial `_hero.html.erb`.
- **Bannière annonces** : ratio **16:9**. Taille affichée côté site : **1200×675** (variant `resize_to_fill: [1200, 675]`). Les bénévoles peuvent fournir en 1920×1080 ou 1920×1005 ; le site redimensionne.

---

## Où sont les textes

- **Sur le site (public)** : aucun titre ni sous-titre n’est affiché sur le slide. **Tout le texte doit être intégré dans l’image** (conception graphique 16:9).
- **En administration** :
  - **Titre** : obligatoire, utilisé pour la liste des slides, le breadcrumb et l’accessibilité (aria-label des indicateurs). Usage interne uniquement.
  - **Description** (champ « Description », ex-sous-titre) : optionnel, notes pour les bénévoles, **non affichées sur le site**.

---

## Comportement du carousel public (bannière)

- Bootstrap 5 carousel (fade), avec **autoplay 5–7 s** (configurable) et pause au survol / focus (`carousel_controller.js`).
- **Accessibilité** : `aria-label="Annonces importantes"` sur le conteneur ; contrôles visibles (flèches + indicateurs).
- Indicateurs (puces) : petits (3×3 px), zone tactile conservée.
- Pas de caption / overlay : pas de « En savoir plus » ni texte par-dessus l’image.
- Lien optionnel : clic sur toute la slide si `link_url` est renseigné (ouverture dans nouvel onglet si URL externe).

---

## Formulaire admin (nouveau / modifier)

- **Informations** : Titre *, Description (optionnel), Lien URL, Position, dates (published_at, expires_at), case à cocher Publié.
- **Image** :
  - Bannière annonces **16:9** (recommandé 1920×1080 ou 1920×1005 ; le site affiche en 1200×675). Contenu centré, idéalement < 20 % de texte dans l’image.
  - **Aperçu bannière (16:9)** : bloc avec `aspect-ratio: 16/9` et image en `resize_to_fill: [1200, 675]` pour refléter le rendu réel.
- Aperçu en direct au choix du fichier (Stimulus `carousel_form_controller.js`).

Référence : `app/views/admin_panel/homepage_carousels/_form.html.erb`.

---

## Fichiers principaux

| Rôle | Fichier |
|------|--------|
| Partial hero (pitch + CTA) | `app/views/pages/_hero.html.erb` |
| Partial bannière annonces | `app/views/pages/_announcement_banner.html.erb` |
| Intégration homepage | `app/views/pages/index.html.erb` |
| Styles bannière (16:9 fixe, aspect-ratio racine, image cover centrée) | `app/assets/stylesheets/_style.scss` — bloc `#announcementCarousel.announcement-banner-carousel` |
| Variant image public (bannière) | `resize_to_fill: [1200, 675]` dans `_announcement_banner.html.erb` |
| Formulaire admin | `app/views/admin_panel/homepage_carousels/_form.html.erb` |
| Show admin (aperçu) | `app/views/admin_panel/homepage_carousels/show.html.erb` |
| Contrôleur carousel (auto-play, pause) | `app/javascript/controllers/carousel_controller.js` |
| Aperçu image formulaire | `app/javascript/controllers/carousel_form_controller.js` |
| Contrôleur CRUD admin | `app/controllers/admin_panel/homepage_carousels_controller.rb` |
| Routes | `resources :homepage_carousels` (member: publish, unpublish, move_up, move_down ; collection: reorder) |

---

## Doc associée

- [homepage-implementation-plan.md](./homepage-implementation-plan.md) — Plan global homepage (état bannière, hero fixe, hiérarchie de page).
- [homepage-reflection.md](./homepage-reflection.md) — Réflexion initiale et checklist carousel.
