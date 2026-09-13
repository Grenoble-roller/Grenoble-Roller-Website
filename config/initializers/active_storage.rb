# Configuration Active Storage
# Utilise libvips pour le traitement d'images (plus rapide que ImageMagick)

Rails.application.config.active_storage.variant_processor = :vips

# Configuration des variants par défaut
# Les variants sont générés à la demande et mis en cache
Rails.application.config.active_storage.track_variants = true

# Servir les fichiers via Rails au lieu de rediriger vers MinIO directement
# Cela permet d'éviter les problèmes de résolution DNS avec les noms Docker
Rails.application.config.active_storage.resolve_model_to_route = :rails_storage_proxy

# Load S3 service wrapper for idempotent deletes
require_relative "../../app/services/active_storage/s3_service_wrapper"
