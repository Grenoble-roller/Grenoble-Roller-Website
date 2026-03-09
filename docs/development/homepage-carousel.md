# Carrousel de la page d'accueil (HomepageCarousel)

**Statut** : ✅ Implémenté  
**Dernière mise à jour** : 2026-03-09

Documentation dédiée au carrousel hero de la page d'accueil : modèle, admin (AdminPanel), affichage public et liens vers le code.

---

## Vue d'ensemble

Le carrousel affiche des slides (titre, sous-titre, image, lien optionnel) en haut de la page d'accueil. Les slides sont gérés dans l'AdminPanel par les utilisateurs avec le rôle ORGANIZER+ (level ≥ 40). Si aucun slide actif n'existe, un hero banner par défaut s'affiche.

---

## Liens vers le code

### Modèle & base de données
| Élément | Fichier |
|--------|--------|
| Modèle | [`app/models/homepage_carousel.rb`](../../app/models/homepage_carousel.rb) |
| Migration création | [`db/migrate/20260105000001_create_homepage_carousels.rb`](../../db/migrate/20260105000001_create_homepage_carousels.rb) |
| Migration position unique | [`db/migrate/20260131000001_add_unique_position_to_homepage_carousels.rb`](../../db/migrate/20260131000001_add_unique_position_to_homepage_carousels.rb) |
| Schéma | `db/schema.rb` → table `homepage_carousels` |

### Admin (AdminPanel)
| Élément | Fichier |
|--------|--------|
| Contrôleur | [`app/controllers/admin_panel/homepage_carousels_controller.rb`](../../app/controllers/admin_panel/homepage_carousels_controller.rb) |
| Policy | [`app/policies/admin_panel/homepage_carousel_policy.rb`](../../app/policies/admin_panel/homepage_carousel_policy.rb) |
| Routes | [`config/routes.rb`](../../config/routes.rb) — namespace `admin_panel`, `resources :homepage_carousels` |
| BaseController (accès level) | [`app/controllers/admin_panel/base_controller.rb`](../../app/controllers/admin_panel/base_controller.rb) |

### Vues admin
| Vue | Fichier |
|-----|--------|
| Index | [`app/views/admin_panel/homepage_carousels/index.html.erb`](../../app/views/admin_panel/homepage_carousels/index.html.erb) |
| Show | [`app/views/admin_panel/homepage_carousels/show.html.erb`](../../app/views/admin_panel/homepage_carousels/show.html.erb) |
| New / Edit | [`app/views/admin_panel/homepage_carousels/new.html.erb`](../../app/views/admin_panel/homepage_carousels/new.html.erb), [`edit.html.erb`](../../app/views/admin_panel/homepage_carousels/edit.html.erb) |
| Formulaire | [`app/views/admin_panel/homepage_carousels/_form.html.erb`](../../app/views/admin_panel/homepage_carousels/_form.html.erb) |
| Menu sidebar | [`app/views/admin/shared/_menu_items.html.erb`](../../app/views/admin/shared/_menu_items.html.erb) — entrée « Page d'Accueil » > « Carrousel » |

### Affichage public
| Élément | Fichier |
|--------|--------|
| Partial carousel | [`app/views/pages/_carousel.html.erb`](../../app/views/pages/_carousel.html.erb) |
| Page d'accueil | [`app/views/pages/index.html.erb`](../../app/views/pages/index.html.erb) — inclut `render 'pages/carousel'` |

### Tests & locales
| Élément | Fichier |
|--------|--------|
| Request spec | [`spec/requests/admin_panel/homepage_carousels_spec.rb`](../../spec/requests/admin_panel/homepage_carousels_spec.rb) |
| Policy spec | [`spec/policies/admin_panel/homepage_carousel_policy_spec.rb`](../../spec/policies/admin_panel/homepage_carousel_policy_spec.rb) |
| Locales FR | [`config/locales/fr.yml`](../../config/locales/fr.yml) — clés `activerecord.models.homepage_carousel` |

---

## Documentation associée

| Document | Description |
|----------|-------------|
| [Plan d'implémentation page d'accueil](./homepage-implementation-plan.md) | Plan global ; section « Carrousel Hero » avec état détaillé |
| [Réflexion page d'accueil](./homepage-reflection.md) | Contexte, priorités, checklist (carousel coché) |
| [Lacunes de couverture tests](../05-testing/rspec/coverage-gaps.md) | Request spec partiel ; CRUD + actions custom non couverts |
| [Sidebar Admin Panel](../04-rails/admin-panel/00-dashboard/sidebar.md) | Structure du menu admin |

---

## Référence technique rapide

### Modèle `HomepageCarousel`
- **Attributs** : `title` (requis), `subtitle`, `link_url`, `position` (entier, unique), `published` (défaut false), `published_at`, `expires_at`, `image` (Active Storage).
- **Scopes** : `published`, `active` (visible selon published + dates), `ordered` (position asc, created_at desc).
- **Validations** : titre présent ; position présente, unique, entier ≥ 0 ; image requise si `published?`.

### Routes admin (préfixe `/admin-panel`)
- Index : `GET /admin-panel/homepage-carousels`
- Show : `GET /admin-panel/homepage-carousels/:id`
- New / Create : `GET|POST /admin-panel/homepage-carousels/new`, `POST /admin-panel/homepage-carousels`
- Edit / Update : `GET|PATCH /admin-panel/homepage-carousels/:id/edit`, `PATCH /admin-panel/homepage-carousels/:id`
- Destroy : `DELETE /admin-panel/homepage-carousels/:id`
- Actions member : `POST publish`, `POST unpublish`, `PATCH move_up`, `PATCH move_down`
- Collection : `PATCH /admin-panel/homepage-carousels/reorder` (paramètre `positions`)

### Permissions
- Accès admin (BaseController) : level ≥ 30 pour `homepage_carousels`.
- Policy : level ≥ 40 (ORGANIZER+) pour toutes les actions.

### Affichage public
- Données : `HomepageCarousel.active.ordered`.
- Image : variant `resize_to_limit: [1920, 600]`.
- Si aucun slide actif : hero banner par défaut (titre « La communauté Roller Grenobloise ! », CTA événements / connexion).

### Non implémenté
- UI drag & drop batch (SortableJS) : l’endpoint `reorder` existe, l’interface utilise uniquement les boutons « Monter » / « Descendre ».
