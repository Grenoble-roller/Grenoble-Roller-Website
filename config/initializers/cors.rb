# Be sure to restart your server when you modify this file.

# Handle Cross-Origin Resource Sharing (CORS) in order to accept cross-origin AJAX requests.

# Read more: https://github.com/cyu/rack-cors

Rails.application.config.middleware.insert_before 0, Rack::Cors do
  allow do
    # Allowed origins for mobile and web apps
    origins do |origin, request|
      # Development: allow localhost
      if Rails.env.development?
        origin.nil? || origin.match?(/^https?:\/\/localhost(:\d+)?$/) ||
        origin.match?(/^https?:\/\/127\.0\.0\.1(:\d+)?$/) ||
        origin.match?(/^https?:\/\/.*\.flowtech-lab\.org$/)
      # Staging: RAILS_ENV=staging and/or APP_ENV/DEPLOY_ENV=staging
      elsif ENV["APP_ENV"] == "staging" || ENV["DEPLOY_ENV"] == "staging" || Rails.env.staging?
        staging_extra =
          if ENV["STAGING_PUBLIC_DOMAIN"].present?
            d = Regexp.escape(ENV["STAGING_PUBLIC_DOMAIN"].strip)
            origin.match?(/^https?:\/\/([a-z0-9.-]+\.)?#{d}$/i)
          else
            false
          end
        origin.nil? ||
        origin.match?(/^https?:\/\/.*\.flowtech-lab\.org$/) ||
        origin.match?(/^https?:\/\/.*\.localhost(:\d+)?$/) ||
        staging_extra
      # Production: allow production domain
      else
        origin.nil? ||
        origin.match?(/^https?:\/\/.*\.grenoble-roller\.org$/) ||
        origin.match?(/^https?:\/\/grenoble-roller\.org$/)
      end
    end

    # Allowed resources
    resource "*",
      headers: :any,
      methods: [ :get, :post, :put, :patch, :delete, :options, :head ],
      credentials: true, # Allow cookies / credentials on cross-origin requests
      expose: [ "Authorization", "X-Total-Count" ] # Headers exposed to the browser client
  end
end
