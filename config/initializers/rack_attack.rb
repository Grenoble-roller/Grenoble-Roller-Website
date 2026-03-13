# frozen_string_literal: true

# Rate limiting avec Rack::Attack
# Conformité sécurité 2025 - Protection contre brute force et spam

# Configuration du cache (utilise Rails.cache)
Rack::Attack.cache.store = ActiveSupport::Cache::MemoryStore.new

# === PROTECTION CONNEXION (Brute force) ===
# 5 tentatives de connexion par IP toutes les 15 minutes
Rack::Attack.throttle("logins/ip", limit: 5, period: 15.minutes) do |req|
  if req.path == "/users/sign_in" && req.post?
    req.ip
  end
end

# === PROTECTION INSCRIPTION (Spam) ===
# 3 inscriptions par IP par heure
Rack::Attack.throttle("registrations/ip", limit: 3, period: 1.hour) do |req|
  if req.path == "/users" && req.post?
    req.ip
  end
end

# === PROTECTION RESET PASSWORD ===
# 3 demandes de reset par IP par heure
Rack::Attack.throttle("password_resets/ip", limit: 3, period: 1.hour) do |req|
  if req.path == "/users/password" && req.post?
    req.ip
  end
end

# === PROTECTION CONFIRMATION RESEND ===
# Limiter renvois confirmation par IP (10 par heure)
Rack::Attack.throttle("confirmations/ip", limit: 10, period: 3600.seconds) do |req|
  if req.path == "/users/confirmation" && req.post?
    req.ip
  end
end

# Limiter renvois confirmation par email (5 par heure)
Rack::Attack.throttle("confirmations/email", limit: 5, period: 3600.seconds) do |req|
  if req.path == "/users/confirmation" && req.post?
    email = req.params.dig("user", "email")&.downcase
    "confirmation:#{email}" if email
  end
end

# === PROTECTION GLOBALE ===
# 300 requêtes par IP par minute (protection DDoS basique)
# Rate limiting pour les inscriptions aux initiations/événements
Rack::Attack.throttle("initiations/attend/ip", limit: 10, period: 1.minute) do |req|
  if req.path.match?(%r{/initiations/\d+/attend}) && req.post?
    req.ip
  end
end

Rack::Attack.throttle("events/attend/ip", limit: 10, period: 1.minute) do |req|
  if req.path.match?(%r{/events/\d+/attend}) && req.post?
    req.ip
  end
end

# Rate limiting général par IP
Rack::Attack.throttle("req/ip", limit: 300, period: 1.minute) do |req|
  req.ip
end

# === WHITELIST (Développement) ===
# En développement, pas de rate limiting pour localhost
if Rails.env.development?
  Rack::Attack.safelist("allow-localhost") do |req|
    req.ip == "127.0.0.1" || req.ip == "::1"
  end
end

# === CUSTOM RESPONSE ===
Rack::Attack.throttled_responder = lambda do |request|
  # Accéder à match_data depuis l'environnement Rack
  match_data = request.env["rack.attack.match_data"]

  # Extraire la période (retry_after) - valeur par défaut 60 secondes
  throttle_name = request.env["rack.attack.matched"]

  retry_after = 60
  if match_data
    # Essayer différentes méthodes d'accès selon le type d'objet
    if match_data.is_a?(Hash)
      retry_after = match_data[:period] || match_data["period"] || 60
    elsif match_data.respond_to?(:period)
      retry_after = match_data.period
    elsif match_data.respond_to?(:[])
      retry_after = match_data[:period] || 60
    end
  end

  # Messages spécifiques selon le throttle
  message = case throttle_name
  when "confirmations/ip", "confirmations/email"
    "Trop de demandes de renvoi d'email. Réessayez dans 1 heure."
  when "logins/ip", "sessions/ip"
    "Trop de tentatives de connexion. Réessayez dans 15 minutes."
  when "password_resets/ip"
    "Trop de demandes de réinitialisation. Réessayez dans 1 heure."
  else
    "Trop de tentatives. Réessayez plus tard."
  end

  [
    429,
    {
      "Content-Type" => "text/html; charset=utf-8",
      "Retry-After" => retry_after.to_s
    },
    [ "<html><body><h1>Trop de tentatives</h1><p>#{message}</p></body></html>" ]
  ]
end
