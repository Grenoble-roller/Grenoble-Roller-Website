# Carousel bannière annonces (HomepageCarousel)

**Dernière mise à jour** : 2026-03-09

Référence unique pour le **carousel de la page d’accueil** : bannière annonces sous le hero, 16:9, modèle `HomepageCarousel`, admin dédié.

---

## Contexte

- **Emplacement** : sous le hero (pitch + CTA), avant « Prochains rendez-vous ».
- **Rôle** : afficher des slides d’annonces (affiches, événements à thème). Pas de titre/sous-titre HTML sur le slide — tout le texte est **dans l’image**.
- **Modèle** : `HomepageCarousel` (titre, description optionnelle, image, `link_url`, position, published_at, expires_at). Scope public : `HomepageCarousel.active.ordered`.

---

## Spécifications

| Élément | Valeur |
|--------|--------|
| Ratio | **16:9** (fixe) |
| Image affichée | `resize_to_fill: [1200, 675]` |
| Format conseillé bénévoles | 1920×1080 ou 1920×1005 |
| Hauteur max visuelle | Largeur limitée à `min(100%, calc(55vh * 16/9))` → marges latérales sur grands écrans, ratio toujours 16:9 |
| Autoplay | 6 s (`data-bs-interval="6000"`), pause au survol/focus |
| Accessibilité | `aria-label="Annonces importantes"` ; flèches + indicateurs ; pas de caption overlay |

---

## Fichiers (carousel uniquement)

| Rôle | Fichier |
|------|--------|
| Partial bannière | `app/views/pages/_announcement_banner.html.erb` |
| Styles 16:9 (racine + cover) | `app/assets/stylesheets/_style.scss` → `#announcementCarousel.announcement-banner-carousel` |
| JS carousel (Bootstrap + autoplay) | `app/javascript/controllers/carousel_controller.js` |
| Admin CRUD | `app/controllers/admin_panel/homepage_carousels_controller.rb` |
| Formulaire admin | `app/views/admin_panel/homepage_carousels/_form.html.erb` |
| Aperçu formulaire (16:9) | `app/javascript/controllers/carousel_form_controller.js` |
| Modèle | `app/models/homepage_carousel.rb` |
| Routes | `resources :homepage_carousels` (member: publish, unpublish, move_up, move_down ; collection: reorder) |

---

## Intégration homepage

Dans `app/views/pages/index.html.erb` :

1. Hero : `<%= render 'pages/hero' %>`
2. Ligne de séparation
3. Bannière : `<%= render 'pages/announcement_banner' %>`
4. Ligne de séparation
5. Section « Prochains rendez-vous », etc.

---

## Admin

- **Titre** : obligatoire (liste, breadcrumb, aria-label des indicateurs).
- **Description** : optionnel, non affiché sur le site.
- **Lien URL** : optionnel ; si présent, clic sur toute la slide ouvre le lien (nouvel onglet si URL externe).
- **Image** : 16:9, aperçu en 1200×675 dans le formulaire.
- **Publication** : published_at, expires_at, case Publié ; publish/unpublish manuel possible.

---

## Doc connexe (contexte plus large)

- [homepage-implementation-plan.md](./homepage-implementation-plan.md) — Plan global homepage (hero, bannière, ordre des sections, options abandonnées).
- [homepage-reflection.md](./homepage-reflection.md) — Réflexion initiale et contexte bénévoles.
