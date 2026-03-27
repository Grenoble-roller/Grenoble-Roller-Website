
class HelloassoService
  require "net/http"
  require "uri"
  require "json"

  # OAuth2 token endpoint (client_credentials)
  # HelloAsso docs typically use /oauth2/token to obtain the token
  HELLOASSO_SANDBOX_OAUTH_URL = "https://api.helloasso-sandbox.com/oauth2/token"
  HELLOASSO_PRODUCTION_OAUTH_URL = "https://api.helloasso.com/oauth2/token"

  HELLOASSO_SANDBOX_API_BASE_URL = "https://api.helloasso-sandbox.com/v5"
  HELLOASSO_PRODUCTION_API_BASE_URL = "https://api.helloasso.com/v5"

  class << self
    # Raw helloasso config from Rails credentials
    def config
      Rails.application.credentials.helloasso || {}
    end

    # Resolves which HelloAsso API environment to use (sandbox vs production)
    # Safe default: HelloAsso **sandbox** unless production is explicit (deploy flags, credentials helloasso.environment: production, or HELLOASSO_USE_PRODUCTION).
    # In RAILS_ENV=production, we do *not* assume live API from Rails alone — avoids staging containers misconfigured as production.
    def environment
      return "sandbox" if Rails.env.staging?

      return "sandbox" if ENV["HELLOASSO_USE_SANDBOX"] == "true"
      return "production" if ENV["HELLOASSO_USE_PRODUCTION"] == "true"

      is_staging = ENV["APP_ENV"] == "staging" ||
                   ENV["DEPLOY_ENV"] == "staging" ||
                   (Rails.env.production? && ActionMailer::Base.default_url_options[:host]&.include?("flowtech-lab.org"))

      return "sandbox" if is_staging

      if Rails.env.production?
        return "production" if production_helloasso_deploy? || config[:environment].to_s == "production"
        return "sandbox"
      end

      config[:environment].presence || "sandbox"
    end

    # True when Dokploy / ops marks this container as real production (HelloAsso live API).
    def production_helloasso_deploy?
      return true if ENV["HELLOASSO_USE_PRODUCTION"] == "true"
      return false if ENV["APP_ENV"] == "staging" || ENV["DEPLOY_ENV"] == "staging"
      return true if ENV["DEPLOY_ENV"] == "production"
      return true if ENV["APP_ENV"] == "production" && ENV["DEPLOY_ENV"] != "staging"

      false
    end

    def sandbox?
      environment == "sandbox"
    end

    def production?
      environment == "production"
    end

    # client_id for current HelloAsso environment
    def client_id
      if production?
        config[:client_id_production] || config[:client_id]
      else
        config[:client_id]
      end
    end

    # client_secret for current HelloAsso environment
    def client_secret
      if production?
        config[:client_secret_production] || config[:client_secret]
      else
        config[:client_secret]
      end
    end

    def organization_slug
      config[:organization_slug]
    end

    def oauth_token_url
      production? ? HELLOASSO_PRODUCTION_OAUTH_URL : HELLOASSO_SANDBOX_OAUTH_URL
    end

    def api_base_url
      production? ? HELLOASSO_PRODUCTION_API_BASE_URL : HELLOASSO_SANDBOX_API_BASE_URL
    end

    # Non-secret fields for ops / script/verify_runtime_config.rb (checkout URLs follow the API host).
    def diagnostic_summary
      {
        resolved_api_environment: environment,
        api_base_url: api_base_url,
        oauth_token_url: oauth_token_url,
        credentials_environment: config[:environment].to_s.presence || "(unset)",
        rails_env: Rails.env.to_s,
        app_env: ENV["APP_ENV"].presence || "(unset)",
        deploy_env: ENV["DEPLOY_ENV"].presence || "(unset)",
        production_helloasso_deploy: production_helloasso_deploy?,
        env_helloasso_use_sandbox: ENV["HELLOASSO_USE_SANDBOX"].presence || "(unset)",
        env_helloasso_use_production: ENV["HELLOASSO_USE_PRODUCTION"].presence || "(unset)"
      }
    end

    # ---- Payload helpers (no network) -------------------------------------------

    # Builds the JSON payload (Ruby Hash) to initialize a HelloAsso checkout.
    #
    # - order: local Order-like object (id, total_cents, currency, order_items)
    # - donation_cents: extra donation amount in cents (Integer)
    # - back_url: URL if the user goes back
    # - error_url: URL on checkout error
    # - return_url: URL after payment (success or failure)
    #
    # NOTE: no HTTP calls here; only builds a Hash.
    def build_checkout_intent_payload(order, donation_cents:, back_url:, error_url:, return_url:)
      raise ArgumentError, "order is required" unless order
      raise "HelloAsso organization_slug manquant" if organization_slug.to_s.strip.empty?

      # Donation from order if present, else param
      donation = order.respond_to?(:donation_cents) ? (order.donation_cents || 0) : donation_cents.to_i

      # Line items for the order
      items = []

      # Add line items when order_items is present
      if order.respond_to?(:order_items) && order.order_items.any?
        order.order_items.each do |order_item|
          product_name = if order_item.respond_to?(:variant) && order_item.variant
            order_item.variant.product&.name || "Article ##{order_item.variant_id}"
          elsif order_item.respond_to?(:product)
            order_item.product&.name || "Article ##{order_item.id}"
          else
            "Article ##{order_item.id}"
          end

          items << {
            name: product_name,
            quantity: order_item.quantity.to_i,
            amount: order_item.unit_price_cents.to_i,
            type: "Product"
          }
        end
      else
        # Fallback: no order_items — single generic line for article total
        articles_cents = order.total_cents.to_i - donation
        if articles_cents > 0
          items << {
            name: "Commande ##{order.id} - Boutique Grenoble Roller",
            quantity: 1,
            amount: articles_cents,
            type: "Product"
          }
        end
      end

      # Add donation as its own line if > 0 (per HelloAsso docs)
      if donation > 0
        items << {
          name: "Contribution à l'association",
          quantity: 1,
          amount: donation,
          type: "Donation"
        }
      end

      # Payload shape for checkout-intents
      # NOTE: /checkout-intents may differ from /orders; HelloAsso docs use totalAmount/initialAmount, not items
      # We may try items first and handle 400 fallback

      total_cents = items.sum { |item| item[:amount] * item[:quantity] }

      # checkout-intents structure (validated in earlier integration tests)
      {
        totalAmount: total_cents,
        initialAmount: total_cents,
        itemName: items.any? ? items.map { |i| "#{i[:name]} x#{i[:quantity]}" }.join(", ") : "Commande ##{order.id}",
        backUrl: back_url,
        errorUrl: error_url,
        returnUrl: return_url,
        containsDonation: donation.positive?,
        metadata: {
          localOrderId: order.id,
          environment: environment,
          donationCents: donation,
          items: items # keep line items in metadata for reference
        }
      }
    end

    # ---- OAuth2 / Token management -------------------------------------------------

    # Calls HelloAsso OAuth2 to obtain an access_token (client_credentials flow, no end user)
    #
    # Returns a Hash with at least:
    #   {
    #     access_token: "xxx",
    #     token_type:   "Bearer",
    #     expires_in:   3600,
    #     raw:          <full JSON response>
    #   }
    #
    # Raises RuntimeError on network error or HTTP != 200.
    def fetch_access_token!
      raise "HelloAsso client_id manquant dans les credentials" if client_id.to_s.strip.empty?
      raise "HelloAsso client_secret manquant dans les credentials" if client_secret.to_s.strip.empty?

      uri = URI.parse(oauth_token_url)

      request = Net::HTTP::Post.new(uri)
      request["Content-Type"] = "application/x-www-form-urlencoded"
      request.set_form_data(
        "grant_type" => "client_credentials",
        "client_id" => client_id,
        "client_secret" => client_secret
      )

      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = (uri.scheme == "https")

      response = http.request(request)

      unless response.is_a?(Net::HTTPSuccess)
        error_msg = if response.code.to_i == 429
          "HelloAsso OAuth error (429): Rate limit atteint. " \
          "Les serveurs HelloAsso sont surchargés. Réessayez dans quelques minutes."
        else
          "HelloAsso OAuth error (#{response.code}): #{response.body[0..200]}"
        end
        raise error_msg
      end

      body = JSON.parse(response.body)

      {
        access_token: body["access_token"],
        token_type: body["token_type"],
        expires_in: body["expires_in"],
        raw: body
      }
    rescue JSON::ParserError => e
      raise "HelloAsso OAuth JSON parse error: #{e.message}"
    end

    # Returns the token string or nil on error (no caching; fresh token each call to avoid expiry issues)
    def access_token
      result = fetch_access_token!
      token = result[:access_token]

      if token.to_s.strip.empty?
        Rails.logger.error("[HelloassoService] access_token vide dans la réponse : #{result.inspect}")
        return nil
      end

      token
    rescue => e
      Rails.logger.error("[HelloassoService] Impossible de récupérer l'access_token : #{e.class} - #{e.message}")
      Rails.logger.error("[HelloassoService] Backtrace: #{e.backtrace.first(5).join("\n")}")
      nil
    end

    # ---- Checkout intents (REST) -----------------------------------------------

    # Creates a HelloAsso checkout via:
    # POST /v5/organizations/{organizationSlug}/checkout-intents
    #
    # - order: local Order-like object (id, total_cents, currency)
    # - donation_cents: extra donation in cents (Integer)
    # - back_url, error_url, return_url: redirect URLs (see HelloAsso docs)
    #
    # Returns a Hash:
    #   {
    #     status: 200,
    #     success: true/false,
    #     body: { "id" => ..., "redirectUrl" => "..." }
    #   }
    def create_checkout_intent(order, donation_cents:, back_url:, error_url:, return_url:)
      # Preconditions
      raise "HelloAsso organization_slug manquant" if organization_slug.to_s.strip.empty?

      # Obtain token (retry once if needed)
      token = access_token
      if token.to_s.strip.empty?
        Rails.logger.error("[HelloassoService] Tentative de récupération du token échouée")
        # One retry
        begin
          token = fetch_access_token![:access_token]
        rescue => e
          Rails.logger.error("[HelloassoService] Échec définitif de récupération du token : #{e.message}")
          raise "HelloAsso access_token introuvable. Vérifiez les credentials (client_id, client_secret) dans Rails credentials."
        end
      end

      raise "HelloAsso access_token introuvable après retry" if token.to_s.strip.empty?

      payload = build_checkout_intent_payload(
        order,
        donation_cents: donation_cents,
        back_url: back_url,
        error_url: error_url,
        return_url: return_url
      )

      # Debug: log payload
      Rails.logger.info("[HelloassoService] Payload checkout-intent: #{payload.to_json}")

      uri = URI.parse("#{api_base_url}/organizations/#{organization_slug}/checkout-intents")

      request = Net::HTTP::Post.new(uri)
      request["Authorization"] = "Bearer #{token}"
      request["accept"] = "application/json"
      request["content-type"] = "application/json"
      request.body = payload.to_json

      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = (uri.scheme == "https")

      response = http.request(request)

      # On 401, token may have expired — retry once with a new token
      if response.code.to_i == 401
        Rails.logger.warn("[HelloassoService] Token expiré (401) lors de create_checkout_intent, réessai avec un nouveau token...")
        token = fetch_access_token![:access_token]
        request["Authorization"] = "Bearer #{token}"
        response = http.request(request)
      end

      body =
        begin
          JSON.parse(response.body)
        rescue JSON::ParserError
          { "raw_body" => response.body }
        end

      result = {
        status: response.code.to_i,
        success: response.is_a?(Net::HTTPSuccess),
        body: body
      }

      # Detailed log for debugging
      if response.code.to_i != 200
        Rails.logger.error("[HelloassoService] create_checkout_intent ERROR (#{response.code}): #{response.body}")
      else
        Rails.logger.info("[HelloassoService] create_checkout_intent SUCCESS: #{result.inspect}")
      end

      result
    end

    # Returns redirect URL when checkout intent creation succeeds.
    def checkout_redirect_url(order, donation_cents:, back_url:, error_url:, return_url:)
      result = create_checkout_intent(
        order,
        donation_cents: donation_cents,
        back_url: back_url,
        error_url: error_url,
        return_url: return_url
      )

      return nil unless result[:success]

      result.dig(:body, "redirectUrl")
    end

    # Redirect URL for an existing checkout intent (resume interrupted payment).
    def checkout_redirect_url_for_intent(checkout_intent_id)
      intent = fetch_checkout_intent(checkout_intent_id)
      intent["redirectUrl"]
    end

    # ---- Payment sync (polling) -------------------------------------------------

    # Fetches HelloAsso payment state and updates Payment and related Order.
    # GET /v5/organizations/{slug}/checkout-intents/{checkoutIntentId}
    # When checkout-intent includes an order, fetch order state from /orders/{orderId}
    def fetch_and_update_payment(payment)
      # provider_payment_id stores the checkout-intent id
      checkout_intent_id = payment.provider_payment_id

      # 1. Load checkout-intent
      intent = fetch_checkout_intent(checkout_intent_id)

      # 2. If an order exists, load its state via /orders/{orderId}
      state = nil
      if intent.key?("order") && intent["order"].present?
        order_id = intent.dig("order", "id") || intent.dig("order", "orderId")

        if order_id
          begin
            order_data = fetch_helloasso_order(order_id)
            state = order_data["state"] if order_data
          rescue StandardError => e
            Rails.logger.warn(
              "[HelloassoService] Failed to fetch order #{order_id}, " \
              "using checkout-intent status: #{e.message}"
            )
          end
        end
      end

      # 3. Map HelloAsso state to local payment status
      new_status = if state
        case state
        when "Confirmed" then "succeeded"
        when "Refused" then "failed"
        when "Refunded" then "refunded"
        else "pending"
        end
      elsif intent.key?("order") && intent["order"].present?
        # Order present but no state — treat as confirmed
        "succeeded"
      else
        # No order yet — pending or abandoned
        payment.created_at < 45.minutes.ago ? "abandoned" : "pending"
      end

      return payment if new_status == payment.status

      # 4. Update payment
      payment.update!(status: new_status)

      # 5. Update related orders
      order_status = case new_status
      when "succeeded" then "paid"
      when "failed", "refunded", "abandoned" then "failed"
      else "pending"
      end

      payment.orders.each { |order| order.update!(status: order_status) }

      # 6. Update related memberships
      membership_status = case new_status
      when "succeeded" then "active"
      when "failed", "refunded", "abandoned" then "expired"
      else "pending"
      end

      # Single membership (has_one :membership)
      if payment.membership
        old_status = payment.membership.status
        payment.membership.update!(status: membership_status)

        # Email on failed payment
        if new_status == "failed" && old_status == "pending"
          MembershipMailer.payment_failed(payment.membership).deliver_later if defined?(MembershipMailer)
        end
      end

      # Multiple child memberships (has_many :memberships)
      if payment.memberships.any?
        payment.memberships.each do |membership|
          old_status = membership.status
          membership.update!(status: membership_status)

          # Email on failed payment
          if new_status == "failed" && old_status == "pending"
            MembershipMailer.payment_failed(membership).deliver_later if defined?(MembershipMailer)
          end
        end
      end

      membership_ids = []
      membership_ids << payment.membership.id if payment.membership
      membership_ids.concat(payment.memberships.pluck(:id)) if payment.memberships.any?

      Rails.logger.info(
        "[HelloassoService] Payment ##{payment.id} updated to #{new_status}. " \
        "Orders: #{payment.orders.pluck(:id).join(', ')}, " \
        "Memberships: #{membership_ids.join(', ')}"
      )

      payment
    end

    # Fetches HelloAsso order state: GET /orders/{orderId}
    def fetch_helloasso_order(order_id)
      uri = URI.parse(
        "#{api_base_url}/organizations/#{organization_slug}/orders/#{order_id}"
      )

      # Fresh token
      token = access_token
      raise "HelloAsso access_token introuvable" if token.to_s.strip.empty?

      request = Net::HTTP::Get.new(uri)
      request["Authorization"] = "Bearer #{token}"
      request["accept"] = "application/json"

      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = (uri.scheme == "https")

      response = http.request(request)

      # On 401, retry once with a new token
      if response.code.to_i == 401
        Rails.logger.warn("[HelloassoService] Token expiré (401), réessai avec un nouveau token...")
        token = fetch_access_token![:access_token]
        request["Authorization"] = "Bearer #{token}"
        response = http.request(request)
      end

      unless response.is_a?(Net::HTTPSuccess)
        raise "HelloAsso order fetch error (#{response.code}): #{response.body}"
      end

      JSON.parse(response.body)
    end

    # Extracts donation amount from HelloAsso order or checkout-intent JSON.
    # Looks for an item with type "Donation" in items[].
    #
    # - response_data: parsed HelloAsso JSON as Hash
    #
    # Returns amount in cents (Integer), or 0 if no donation line.
    def extract_donation_from_response(response_data)
      return 0 unless response_data.is_a?(Hash)

      items = response_data["items"] || response_data[:items] || []
      return 0 unless items.is_a?(Array)

      donation_item = items.find { |item|
        (item["type"] || item[:type]) == "Donation"
      }

      return 0 unless donation_item

      (donation_item["amount"] || donation_item[:amount] || 0).to_i
    end

    # ---- Memberships (simplified checkout-intent) --------------------------------

    # Creates a HelloAsso checkout-intent for a single membership.
    # Simplified payload (total amount + itemName, no line items array).
    #
    # - membership: Membership record
    # - back_url, error_url, return_url: redirect URLs
    #
    # Returns Hash with status, success, body (id, redirectUrl)
    def create_membership_checkout_intent(membership, back_url:, error_url:, return_url:)
      raise ArgumentError, "membership is required" unless membership
      raise "HelloAsso organization_slug manquant" if organization_slug.to_s.strip.empty?

      token = access_token
      if token.to_s.strip.empty?
        begin
          token = fetch_access_token![:access_token]
        rescue => e
          Rails.logger.error("[HelloassoService] Échec récupération token : #{e.message}")
          raise "HelloAsso access_token introuvable"
        end
      end

      # Build membership payload (optional t-shirt); same pattern as shop orders (itemName)
      category_name = membership.category == "standard" ? "Cotisation Adhérent Grenoble Roller" :
                      membership.category == "with_ffrs" ? "Cotisation Adhérent Grenoble Roller + Licence FFRS" :
                      "Adhésion"
      season_name = membership.season || Membership.current_season_name

      # Total = membership + optional t-shirt
      total_amount = membership.total_amount_cents

      # itemName string (same style as orders)
      item_name_parts = [ "#{category_name} Saison #{season_name}" ]

      # Append t-shirt if selected
      if membership.tshirt_variant_id.present?
        tshirt_size = membership.tshirt_variant&.option_values&.find { |ov|
          ov.option_type.name.downcase.include?("taille") ||
          ov.option_type.name.downcase.include?("size") ||
          ov.option_type.name.downcase.include?("dimension")
        }&.value || "Taille standard"

        item_name_parts << "T-shirt Grenoble Roller (#{tshirt_size})"
      end

      item_name = item_name_parts.join(", ")

      payload = {
        organizationSlug: organization_slug,
        initialAmount: total_amount,
        totalAmount: total_amount,
        itemName: item_name,
        containsDonation: false,
        metadata: {
          membership_id: membership.id,
          user_id: membership.user_id,
          category: membership.category,
          season: season_name,
          tshirt_variant_id: membership.tshirt_variant_id,
          environment: environment
        },
        backUrl: back_url,
        errorUrl: error_url,
        returnUrl: return_url
      }

      Rails.logger.info("[HelloassoService] Payload membership checkout-intent: #{payload.to_json}")
      Rails.logger.info("[HelloassoService] Membership ##{membership.id} - amount_cents: #{membership.amount_cents}, tshirt_price: #{membership.tshirt_price_cents}, total: #{membership.total_amount_cents}")

      uri = URI.parse("#{api_base_url}/organizations/#{organization_slug}/checkout-intents")
      request = Net::HTTP::Post.new(uri)
      request["Authorization"] = "Bearer #{token}"
      request["accept"] = "application/json"
      request["content-type"] = "application/json"
      request.body = payload.to_json

      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = (uri.scheme == "https")
      http.read_timeout = 30
      http.open_timeout = 10

      response = http.request(request)

      Rails.logger.info("[HelloassoService] Response status: #{response.code}, body: #{response.body[0..500]}")

      # Retry on 401 with fresh token
      if response.code.to_i == 401
        Rails.logger.warn("[HelloassoService] Token expiré (401), réessai...")
        token = fetch_access_token![:access_token]
        request["Authorization"] = "Bearer #{token}"
        response = http.request(request)
      end

      body = begin
        JSON.parse(response.body)
      rescue JSON::ParserError
        { "raw_body" => response.body }
      end

      success = response.is_a?(Net::HTTPSuccess)

      Rails.logger.info("[HelloassoService] create_membership_checkout_intent response: #{{
        status: response.code.to_i,
        success: success,
        body: body
      }.inspect}")

      {
        status: response.code.to_i,
        success: success,
        body: body
      }
    end

    # HelloAsso redirect URL for a membership checkout; returns :redirect_url and :checkout_id
    def membership_checkout_redirect_url(membership, back_url:, error_url:, return_url:)
      result = create_membership_checkout_intent(
        membership,
        back_url: back_url,
        error_url: error_url,
        return_url: return_url
      )

      unless result[:success]
        error_msg = if result[:body].is_a?(Hash)
          result[:body]["message"] ||
          (result[:body]["errors"].is_a?(Hash) ? result[:body]["errors"].to_json : result[:body]["errors"]) ||
          result[:body]["title"] ||
          result[:body].inspect
        else
          result[:body].to_s
        end
        Rails.logger.error("[HelloassoService] Échec création checkout-intent pour membership ##{membership.id}")
        Rails.logger.error("[HelloassoService] Status: #{result[:status]}, Body: #{result[:body].inspect}")
        Rails.logger.error("[HelloassoService] Message d'erreur: #{error_msg}")
        # nil signals error to controller
        return nil
      end

      redirect_url = result[:body]["redirectUrl"] || result[:body][:redirectUrl]
      checkout_id = result[:body]["id"] || result[:body][:id]

      unless redirect_url
        Rails.logger.error("[HelloassoService] Pas de redirectUrl dans la réponse pour membership ##{membership.id}: #{result[:body].inspect}")
        return nil
      end

      # Return both redirect URL and checkout id
      {
        redirect_url: redirect_url,
        checkout_id: checkout_id
      }
    end

    # Single checkout-intent for multiple child memberships (one payment)
    def create_multiple_memberships_checkout_intent(memberships, back_url:, error_url:, return_url:)
      raise ArgumentError, "memberships must be an array" unless memberships.is_a?(Array)
      raise ArgumentError, "at least one membership required" if memberships.empty?
      raise "HelloAsso organization_slug manquant" if organization_slug.to_s.strip.empty?

      token = access_token
      if token.to_s.strip.empty?
        begin
          token = fetch_access_token![:access_token]
        rescue => e
          Rails.logger.error("[HelloassoService] Échec récupération token : #{e.message}")
          raise "HelloAsso access_token introuvable"
        end
      end

      # Build itemName (same style as shop orders)
      item_name_parts = []
      total_amount = 0
      season_name = Membership.current_season_name

      memberships.each_with_index do |membership, index|
        category_name = membership.category == "standard" ? "Cotisation Adhérent Grenoble Roller" :
                        membership.category == "with_ffrs" ? "Cotisation Adhérent Grenoble Roller + Licence FFRS" :
                        "Adhésion"

        child_name = membership.is_child_membership? ? "#{membership.child_first_name} #{membership.child_last_name}" : nil

        item_name_parts << (child_name ? "#{category_name} - #{child_name} (Saison #{season_name})" : "#{category_name} Saison #{season_name}")
        total_amount += membership.amount_cents

        # Add t-shirt line if selected
        if membership.tshirt_variant_id.present?
          tshirt_size = membership.tshirt_variant&.option_values&.find { |ov|
            ov.option_type.name.downcase.include?("taille") ||
            ov.option_type.name.downcase.include?("size") ||
            ov.option_type.name.downcase.include?("dimension")
          }&.value || "Taille standard"

          item_name_parts << (child_name ? "T-shirt Grenoble Roller (#{tshirt_size}) - #{child_name}" : "T-shirt Grenoble Roller (#{tshirt_size})")
          total_amount += (membership.tshirt_price_cents || 1400)
        end
      end

      item_name = item_name_parts.join(", ")

      payload = {
        organizationSlug: organization_slug,
        initialAmount: total_amount,
        totalAmount: total_amount,
        itemName: item_name,
        containsDonation: false,
        metadata: {
          memberships_count: memberships.size,
          memberships_ids: memberships.map(&:id),
          user_id: memberships.first.user_id,
          season: season_name,
          environment: environment
        },
        backUrl: back_url,
        errorUrl: error_url,
        returnUrl: return_url
      }

      Rails.logger.info("[HelloassoService] Payload multiple memberships checkout-intent: #{payload.to_json}")

      uri = URI.parse("#{api_base_url}/organizations/#{organization_slug}/checkout-intents")
      request = Net::HTTP::Post.new(uri)
      request["Authorization"] = "Bearer #{token}"
      request["accept"] = "application/json"
      request["content-type"] = "application/json"
      request.body = payload.to_json

      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = (uri.scheme == "https")

      response = http.request(request)

      # Retry on 401 with fresh token
      if response.code.to_i == 401
        Rails.logger.warn("[HelloassoService] Token expiré (401), réessai...")
        token = fetch_access_token![:access_token]
        request["Authorization"] = "Bearer #{token}"
        response = http.request(request)
      end

      body = response.body.present? ? JSON.parse(response.body) : {}
      success = response.is_a?(Net::HTTPSuccess)

      Rails.logger.info("[HelloassoService] create_multiple_memberships_checkout_intent response: #{{
        status: response.code.to_i,
        success: success,
        body: body
      }.to_json}")

      {
        status: response.code.to_i,
        success: success,
        body: body
      }
    end

    # Redirect URL for multi-membership checkout
    def multiple_memberships_checkout_redirect_url(memberships, back_url:, error_url:, return_url:)
      result = create_multiple_memberships_checkout_intent(
        memberships,
        back_url: back_url,
        error_url: error_url,
        return_url: return_url
      )

      return nil unless result[:success]
      result[:body]["redirectUrl"]
    end

    private

    # GET /v5/organizations/{organizationSlug}/checkout-intents/{checkoutIntentId}
    def fetch_checkout_intent(checkout_intent_id)
      uri = URI.parse(
        "#{api_base_url}/organizations/#{organization_slug}/checkout-intents/#{checkout_intent_id}"
      )

      # Fresh token
      token = access_token
      raise "HelloAsso access_token introuvable" if token.to_s.strip.empty?

      request = Net::HTTP::Get.new(uri)
      request["Authorization"] = "Bearer #{token}"
      request["accept"] = "application/json"

      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = (uri.scheme == "https")

      response = http.request(request)

      # On 401, retry once with a new token
      if response.code.to_i == 401
        Rails.logger.warn("[HelloassoService] Token expiré (401), réessai avec un nouveau token...")
        token = fetch_access_token![:access_token]
        request["Authorization"] = "Bearer #{token}"
        response = http.request(request)
      end

      unless response.is_a?(Net::HTTPSuccess)
        raise "HelloAsso checkout-intent fetch error (#{response.code}): #{response.body}"
      end

      JSON.parse(response.body)
    end
  end
end
