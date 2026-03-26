# Configuration pour hashid-rails
# Obfusque les IDs numériques dans les URLs pour améliorer la sécurité
Hashid::Rails.configure do |config|
  # Secret salt from Rails credentials or a default derived from secret_key_base
  config.salt = Rails.application.credentials.dig(:hashid, :salt) || Rails.application.secret_key_base[0..31]

  # Longueur minimale du hash (6 caractères par défaut)
  config.min_hash_length = 8

  # Alphabet utilisé pour générer les hashids (éviter les caractères ambigus)
  config.alphabet = "abcdefghjkmnpqrstuvwxyzABCDEFGHJKMNPQRSTUVWXYZ23456789"
end
