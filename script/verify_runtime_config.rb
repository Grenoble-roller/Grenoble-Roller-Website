# frozen_string_literal: true

# Loaded via: bin/rails runner script/verify_runtime_config.rb
# Does not print secret values. Exit 0 = all checks passed.

puts "=== Runtime config verification (no secrets printed) ==="
puts "Rails.env: #{Rails.env}"

errors = []

# Credentials decrypt
begin
  _cfg = Rails.application.credentials.config
  puts "[OK] credentials: encrypted file decrypts (RAILS_MASTER_KEY / config/master.key)"
rescue StandardError => e
  errors << "credentials"
  puts "[FAIL] credentials: #{e.class} — #{e.message}"
end

credentials_ok = !errors.include?("credentials")

# HelloAsso (sandbox vs prod resolved by HelloassoService)
if credentials_ok && defined?(HelloassoService)
  if HelloassoService.client_id.to_s.strip.empty?
    errors << "helloasso_client_id"
    puts "[FAIL] helloasso: client_id missing for #{HelloassoService.environment} API"
  else
    puts "[OK] helloasso: client_id present (API mode: #{HelloassoService.environment})"
  end

  if HelloassoService.client_secret.to_s.strip.empty?
    errors << "helloasso_client_secret"
    puts "[FAIL] helloasso: client_secret missing"
  else
    puts "[OK] helloasso: client_secret present"
  end

  if HelloassoService.organization_slug.to_s.strip.empty?
    errors << "helloasso_org_slug"
    puts "[FAIL] helloasso: organization_slug missing"
  else
    puts "[OK] helloasso: organization_slug present"
  end

  puts "--- HelloAsso diagnostic (no secrets) ---"
  HelloassoService.diagnostic_summary.each do |key, value|
    puts "  #{key}: #{value}"
  end
  puts "  (Sandbox checkout pages use api.helloasso-sandbox.com; live uses api.helloasso.com / www.helloasso.com.)"
  puts "---"
elsif !credentials_ok
  puts "[SKIP] helloasso: credentials decrypt failed"
else
  puts "[SKIP] HelloassoService not loaded"
end

# MinIO / Active Storage (ENV overrides credentials per storage.yml)
if credentials_ok
  minio_access = ENV["MINIO_ACCESS_KEY_ID"].presence ||
                   Rails.application.credentials.dig(:minio, :access_key_id)
  minio_secret = ENV["MINIO_SECRET_ACCESS_KEY"].presence ||
                   Rails.application.credentials.dig(:minio, :secret_access_key)
  minio_endpoint = ENV["MINIO_ENDPOINT"].presence ||
                     Rails.application.credentials.dig(:minio, :endpoint)
  if minio_access.to_s.strip.empty? || minio_secret.to_s.strip.empty? || minio_endpoint.to_s.strip.empty?
    errors << "minio"
    puts "[FAIL] minio: missing access_key_id, secret_access_key, or endpoint (ENV or credentials)"
  else
    puts "[OK] minio: MINIO_* or credentials present (endpoint configured)"
  end

  # Cloudflare Turnstile
  turn_site = Rails.application.credentials.dig(:turnstile, :site_key).presence || ENV["TURNSTILE_SITE_KEY"].to_s
  turn_secret = Rails.application.credentials.dig(:turnstile, :secret_key).presence || ENV["TURNSTILE_SECRET_KEY"].to_s
  if turn_site.strip.empty? || turn_secret.strip.empty?
    errors << "turnstile"
    puts "[FAIL] turnstile: site_key or secret_key missing (credentials or TURNSTILE_* ENV)"
  else
    puts "[OK] turnstile: site_key and secret_key present"
  end

  # SMTP (required for mailers in prod/staging)
  smtp_user = Rails.application.credentials.dig(:smtp, :user_name)
  smtp_pass = Rails.application.credentials.dig(:smtp, :password)
  if smtp_user.to_s.strip.empty? || smtp_pass.to_s.strip.empty?
    puts "[WARN] smtp: user_name or password missing in credentials (mailers may fail)"
  else
    puts "[OK] smtp: credentials present"
  end
else
  puts "[SKIP] minio, turnstile, smtp: credentials decrypt failed"
end

# Optional DB connectivity (set SKIP_DB_CHECK=1 to skip)
if ENV["SKIP_DB_CHECK"] == "1"
  puts "[SKIP] database: SKIP_DB_CHECK=1"
else
  begin
    ActiveRecord::Base.connection.execute("SELECT 1")
    puts "[OK] database: connection works"
  rescue StandardError => e
    errors << "database"
    puts "[FAIL] database: #{e.class} — #{e.message}"
  end
end

puts "=== Result: #{errors.empty? ? 'OK' : 'FAIL (' + errors.join(', ') + ')'} ==="
exit(errors.empty? ? 0 : 1)
