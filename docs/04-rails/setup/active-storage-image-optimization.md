# Optimisation des images Active Storage

Ce document couvre les points techniques d'optimisation Active Storage.

La politique de formats (vocabulaire `master/square/banner/story`, matrice surfaces, migration `image_url`) est maintenue dans :
[`image-formats-and-variants.md`](./image-formats-and-variants.md).

## Pipeline actuel

- Traitement via `libvips` (`image_processing`).
- Variants générées à la demande (cache Active Storage).
- Livraison site orientée **WebP** quand possible.
- Blob source conservé (`master`) pour éviter toute perte.

## Variants Event / Initiation (implémentation)

Dans `app/models/event.rb` — **format unique 16:9** depuis mai 2026 :

- `cover_image_banner` : 1200×675, `resize_to_fill`, format WebP — hero, surfaces larges.
- `cover_image_square` : **800×450**, `resize_to_fill`, format WebP — cartes, listes *(nom legacy, génère du 16:9)*.
- `cover_image_thumb` : **400×225**, `resize_to_fill`, format WebP — miniatures.

Alias legacy conservés :

- `cover_image_hero` → `cover_image_banner`
- `cover_image_card` → `cover_image_square`
- `cover_image_card_featured` → `cover_image_banner`

## Variants Produit / Variante (implémentation)

Dans `app/helpers/products_helper.rb` — helper `square_image_variant` :

- Génère **800×450** (16:9) via `resize_to_fill: [size, (size * 9.0 / 16).round]`.
- Utilisé par `product_image_tag`, `variant_image_tag`, `product_image_url`, `variant_image_url`.

## Vérification rapide (console)

```bash
docker compose -f ops/dev/docker-compose.yml exec web bin/rails runner "
event = Event.where.not(id: nil).first
if event&.cover_image&.attached?
  puts 'Original: ' + event.cover_image.byte_size.to_s + ' bytes'
  puts 'Banner:   ' + event.cover_image_banner.processed.blob.byte_size.to_s + ' bytes'
  puts 'Square:   ' + event.cover_image_square.processed.blob.byte_size.to_s + ' bytes (16:9)'
end
"
```

## Références

- [Active Storage Variants](https://guides.rubyonrails.org/active_storage_overview.html#transforming-images)
- [Image Processing Gem](https://github.com/janko/image_processing)
- [libvips Documentation](https://www.libvips.org/)
