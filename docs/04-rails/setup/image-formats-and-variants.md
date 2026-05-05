# Formats images et variants (référence pivot)

Ce document est la source de vérité pour :

- Le vocabulaire canonique (`master`, `square`, `banner`, `story`).
- Les surfaces UI et leurs ratios.
- Les règles de preview admin.
- La stratégie de migration `image_url`.

> **Décision bénévoles — mai 2026 :** format unique **16:9 centré** sur toutes les surfaces du site. Le terme `square` est conservé dans le code comme alias de compatibilité ; il génère désormais du **16:9** (800×450) et non plus du 1:1.

---

## Vocabulaire canonique

| Nom | Ratio | Dimensions | Usage |
|------|-------|------------|-------|
| `master` | libre | fichier source | Seul upload bénévole ; conservé en storage sans transformation |
| `banner` | **16:9** | 1200×675 | Hero Event, carrousel homepage, surfaces larges |
| `square` | **16:9** | 800×450 | Cartes/listes events, boutique grille + détail *(nom legacy conservé pour compat)* |
| `thumb` | **16:9** | 400×225 | Miniatures tableaux admin |
| `story` | 9:16 | — | Canal social uniquement (doc/export V1 ; variant serveur si Phase B validée) |

Tous les variants servis au navigateur sont en **WebP**, centré (`resize_to_fill`).

---

## Matrice surfaces (format unique 16:9)

| Surface | Variant utilisé | Dimensions |
|---------|-----------------|------------|
| Event card / liste | `square` (alias `banner`) | 800×450 |
| Event hero / bandeau | `banner` | 1200×675 |
| Initiation card / liste | `square` | 800×450 |
| Initiation hero | `banner` | 1200×675 |
| Carousel homepage | `banner` | 1200×675 |
| Boutique grille (listing) | variant 16:9 via `ProductsHelper` | 800×450 |
| Boutique fiche produit | variant 16:9 via `ProductsHelper` | 800×450 |
| Miniature tableau passés | `banner` inline 71×40 | — |

---

## Règles de preview admin

Pattern appliqué dans tous les formulaires image :

1. **Preview master** (`object-fit: contain`) — montre le fichier source entier sans crop.
2. **Preview 16:9** (`object-fit: cover`, `aspect-ratio: 16/9`) — montre le rendu cible centré tel qu'affiché sur le site.
3. Si image déjà persistée → variant serveur identique à la prod ; sinon → blob local (approximation visuelle avant save).

---

## Livraison formats

- Upload accepté : JPG, PNG, WebP (permissif à l'entrée).
- Format de livraison site : **WebP** via `image_processing` / libvips.
- Blob `master` conservé en storage (jamais écrasé par le variant).
- Recadrage : **centré** (`resize_to_fill`) sur toutes les surfaces.

---

## Migration legacy `image_url`

Objectif de sortie : aucune branche d'affichage produit ne dépend de `image_url`.

1. **Phase 1 — UI** : champs `image_url` retirés des formulaires de création/édition. ✓ *Fait*
2. **Phase 2 — Data** : backfill des URLs historiques vers Active Storage (`rake images:backfill_legacy_urls`).
3. **Phase 3 — Code** : fallback `image_url` supprimé des vues/helpers ; drop colonne si applicable.

---

## Tutoriel bénévoles (résumé)

- Page publique : `/guide-images` (schéma + bonnes pratiques).
- Doc courte : [`docs/development/guide-images-benevoles.md`](../../development/guide-images-benevoles.md).
- Fiche SVG : `/guides/image-upload-reference.svg`.

---

## Références code

| Rôle | Fichier |
|------|---------|
| Variants Event / Initiation | `app/models/event.rb` |
| Variants Produit / Variante | `app/helpers/products_helper.rb` |
| Preview carousel admin | `app/views/admin_panel/homepage_carousels/_form.html.erb` |
| Preview events admin | `app/views/events/_form.html.erb` |
| Preview initiations admin | `app/views/initiations/_form.html.erb` |
| Preview produits admin | `app/views/admin_panel/products/_image_upload.html.erb` |
| CSS ratios | `app/assets/stylesheets/_style.scss` → `.card-event-image`, `.card-product-image-wrapper` |
| Carousel | `app/views/pages/_announcement_banner.html.erb` |
| Backfill legacy | `lib/tasks/images_legacy_backfill.rake` |
