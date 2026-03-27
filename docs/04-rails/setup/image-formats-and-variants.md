# Formats images et variants (référence pivot)

Ce document est la source de vérité pour :

- Le vocabulaire canonique (`master`, `square`, `banner`, `story`).
- Les surfaces UI et leurs ratios.
- Les règles de preview admin.
- La stratégie de migration `image_url`.

## Vocabulaire canonique

| Nom | Ratio | Usage |
|------|-------|-------|
| `master` | — | Fichier source uploadé (ex. **16:9** ou **4:5**), conservé en storage ; d’autres ratios sont acceptés |
| `square` | 1:1 | Cartes/listes et boutique (grille + détail par défaut) |
| `banner` | 16:9 | Hero Event + carrousel homepage |
| `story` | 9:16 | Canal social (doc/export V1, variant serveur uniquement si Phase B validée) |

## Matrice surfaces

| Surface | Variant |
|---------|---------|
| Event card / liste | `square` |
| Event hero | `banner` |
| Carousel homepage | `banner` |
| Boutique grille | `square` |
| Boutique détail | `square` (par défaut) |

## Règles de preview admin

Pattern à appliquer dans les formulaires image :

1. **Preview master** (`contain`) : montre le fichier source sans crop.
2. **Preview surface** (`cover`) : montre le rendu cible par ratio (`square` et/ou `banner`).
3. Quand un fichier est déjà enregistré, la preview surface doit utiliser la **variant serveur** ; quand l’upload est local avant save, la preview JS est une approximation visuelle.

## Livraison formats

- Upload accepté : JPG, PNG, WebP.
- Ratios sources côté bénévolat : **16:9** et **4:5** sont compatibles ; d’autres ratios passent aussi (recadrage centré pour les variants `square` / `banner`).
- Livraison côté site : variants en **WebP** quand possible.
- Le blob `master` original reste conservé.

## Migration legacy `image_url`

Objectif de sortie : aucune branche d’affichage produit ne dépend de `image_url`.

1. **UI** : champs `image_url` retirés des formulaires de création/édition.
2. **Data** : backfill des URLs historiques vers Active Storage (`rake images:backfill_legacy_urls`).
3. **Code** : fallback `image_url` supprimé des vues/helpers.

## Tutoriel bénévoles (résumé)

- Page publique : `/guide-images` (schéma + bonnes pratiques).
- Doc courte : [`docs/development/guide-images-benevoles.md`](../../development/guide-images-benevoles.md).
- Fiche SVG : `/guides/image-upload-reference.svg`.

## Références code

- Event variants : `app/models/event.rb`
- Carousel : `app/views/pages/_announcement_banner.html.erb`
- Preview carousel admin : `app/views/admin_panel/homepage_carousels/_form.html.erb`
- Boutique helpers : `app/helpers/products_helper.rb`
- Backfill legacy : `lib/tasks/images_legacy_backfill.rake`
