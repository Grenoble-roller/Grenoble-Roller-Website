# db/seeds_staging.rb
# Seed pour STAGING - SANS destroy_all (ne supprime pas les données existantes)
# Contient uniquement les données essentielles : rôles + compte superadmin
# ⚠️ IMPORTANT : Ce seed utilise find_or_create_by! pour ne pas écraser les données existantes

# Désactiver l'envoi d'emails pendant le seed (évite erreurs SMTP)
ActionMailer::Base.perform_deliveries = false
ActionMailer::Base.delivery_method = :test

# Désactiver temporairement le callback d'envoi d'email
User.skip_callback(:create, :after, :send_welcome_email_and_confirmation)

puts "🌱 Seed staging - Données minimales essentielles (SANS suppression)"
puts ""

# 🎭 Création des rôles (OBLIGATOIRE - User.belongs_to :role)
# Utilise find_or_create_by! pour ne pas écraser les rôles existants
puts "📋 Création/vérification des rôles..."
roles_seed = [
  { code: "USER",        name: "Utilisateur", level: 10 },
  { code: "REGISTERED",  name: "Inscrit",     level: 20 },
  { code: "INITIATION",  name: "Initiation",  level: 30 },
  { code: "ORGANIZER",   name: "Organisateur", level: 40 },
  { code: "MODERATOR",   name: "Modérateur",  level: 50 },
  { code: "ADMIN",       name: "Admin",       level: 60 },
  { code: "SUPERADMIN",  name: "Super Admin", level: 70 }
]

roles_seed.each do |attrs|
  Role.find_or_create_by!(code: attrs[:code]) do |role|
    role.assign_attributes(attrs)
  end
end

puts "✅ #{Role.count} rôles créés/vérifiés"

# 👨‍💻 Compte SuperAdmin (OBLIGATOIRE - pour administrer le site)
puts ""
puts "👤 Création/vérification du compte SuperAdmin..."

superadmin_role = Role.find_by!(code: "SUPERADMIN")

# Utiliser un email de staging spécifique ou celui de production selon besoin
superadmin_email = ENV.fetch("STAGING_SUPERADMIN_EMAIL", "admin@staging.grenoble-roller.org")
superadmin_password = ENV.fetch("STAGING_SUPERADMIN_PASSWORD", "Staging12345678")

superadmin = User.find_or_create_by!(email: superadmin_email) do |user|
  user.password = superadmin_password  # Minimum 12 caractères requis
  user.password_confirmation = superadmin_password
  user.first_name = "Admin"
  user.last_name = "Staging"
  user.phone = "0612345678"
  user.role = superadmin_role
  user.skill_level = "advanced"
  user.confirmed_at = Time.now
end

# Si l'utilisateur existe déjà, s'assurer qu'il a le bon rôle
unless superadmin.role.code == "SUPERADMIN"
  superadmin.update!(role: superadmin_role)
  puts "  ⚠️  Rôle mis à jour vers SUPERADMIN"
end

superadmin.skip_confirmation_notification!
superadmin.save!

puts "✅ Compte SuperAdmin créé/vérifié"
puts "   📧 Email: #{superadmin.email}"
puts "   🆔 ID: #{superadmin.id}"
puts "   🔑 Rôle: #{superadmin.role.code}"

# Réactiver le callback d'envoi d'email
User.set_callback(:create, :after, :send_welcome_email_and_confirmation)

# Réactiver l'envoi d'emails
ActionMailer::Base.perform_deliveries = true

puts ""
puts "✅ Seed staging terminé avec succès !"
puts "   - Rôles : #{Role.count}"
puts "   - Utilisateurs : #{User.count}"
puts ""
puts "⚠️  NOTE : Ce seed ne supprime AUCUNE donnée existante"
puts "   Utilisez find_or_create_by! pour éviter les doublons"
