# Optimisation des images Active Storage

Ce document couvre les points techniques d’optimisation Active Storage.

La politique de formats (vocabulaire `master/square/banner/story`, matrice surfaces, migration `image_url`) est maintenue dans :
[`image-formats-and-variants.md`](./image-formats-and-variants.md).

## Pipeline actuel

- Traitement via `libvips` (`image_processing`).
- Variants générées à la demande (cache Active Storage).
- Livraison site orientée **WebP** quand possible.
- Blob source conservé (`master`) pour éviter toute perte.

## Variants Event (implémentation)

Dans `app/models/event.rb` :

- `cover_image_banner` : 1200×675, `resize_to_fill`, format WebP.
- `cover_image_square` : 800×800, `resize_to_fill`, format WebP.
- `cover_image_thumb` : 400×400, `resize_to_fill`, format WebP.

Alias legacy conservés temporairement :

- `cover_image_hero` → `cover_image_banner`
- `cover_image_card` → `cover_image_square`
- `cover_image_card_featured` → `cover_image_banner`

## Vérification rapide (console)

```bash
docker compose -f ops/dev/docker-compose.yml exec web bin/rails runner "
event = Event.where.not(id: nil).first
if event&.cover_image&.attached?
  puts 'Original: ' + event.cover_image.byte_size.to_s + ' bytes'
  puts 'Banner:   ' + event.cover_image_banner.processed.blob.byte_size.to_s + ' bytes'
  puts 'Square:   ' + event.cover_image_square.processed.blob.byte_size.to_s + ' bytes'
end
"
```

## Références

- [Active Storage Variants](https://guides.rubyonrails.org/active_storage_overview.html#transforming-images)
- [Image Processing Gem](https://github.com/janko/image_processing)
- [libvips Documentation](https://www.libvips.org/)

