# frozen_string_literal: true

require "rails_helper"

RSpec.describe HelloassoService do
  describe ".environment" do
    let(:helloasso_creds) { { environment: "sandbox" } }

    before do
      allow(Rails.application).to receive(:credentials).and_return(
        double(helloasso: helloasso_creds)
      )
      allow(Rails.env).to receive(:staging?).and_return(false)
      allow(Rails.env).to receive(:production?).and_return(production_mode)
    end

    context "when Rails is production, credentials say sandbox, and deploy is not marked production" do
      let(:production_mode) { true }

      before do
        ENV.delete("APP_ENV")
        ENV.delete("DEPLOY_ENV")
        ENV.delete("HELLOASSO_USE_PRODUCTION")
        ENV.delete("HELLOASSO_USE_SANDBOX")
        allow(ActionMailer::Base).to receive(:default_url_options).and_return({ host: "example.com" })
      end

      after do
        ENV.delete("APP_ENV")
        ENV.delete("DEPLOY_ENV")
        ENV.delete("HELLOASSO_USE_PRODUCTION")
        ENV.delete("HELLOASSO_USE_SANDBOX")
      end

      it "uses HelloAsso sandbox API (shared credentials)" do
        expect(described_class.environment).to eq("sandbox")
      end
    end

    context "when Rails is production, credentials say sandbox, and DEPLOY_ENV is production" do
      let(:production_mode) { true }

      before do
        ENV["DEPLOY_ENV"] = "production"
        ENV["APP_ENV"] = "production"
        allow(ActionMailer::Base).to receive(:default_url_options).and_return({ host: "example.com" })
      end

      after do
        ENV.delete("DEPLOY_ENV")
        ENV.delete("APP_ENV")
      end

      it "uses HelloAsso production API" do
        expect(described_class.environment).to eq("production")
      end
    end

    context "when HELLOASSO_USE_PRODUCTION is set" do
      let(:production_mode) { true }

      before do
        ENV["HELLOASSO_USE_PRODUCTION"] = "true"
        allow(ActionMailer::Base).to receive(:default_url_options).and_return({ host: "example.com" })
      end

      after do
        ENV.delete("HELLOASSO_USE_PRODUCTION")
      end

      it "uses HelloAsso production API" do
        expect(described_class.environment).to eq("production")
      end
    end

    context "when Rails is production, credentials omit helloasso.environment, and deploy is not marked production" do
      let(:production_mode) { true }
      let(:helloasso_creds) { {} }

      before do
        ENV.delete("APP_ENV")
        ENV.delete("DEPLOY_ENV")
        allow(ActionMailer::Base).to receive(:default_url_options).and_return({ host: "example.com" })
      end

      after do
        ENV.delete("APP_ENV")
        ENV.delete("DEPLOY_ENV")
      end

      it "defaults to HelloAsso sandbox API" do
        expect(described_class.environment).to eq("sandbox")
      end
    end

    context "when Rails is production, credentials say environment production, and deploy vars are unset" do
      let(:production_mode) { true }
      let(:helloasso_creds) { { environment: "production" } }

      before do
        ENV.delete("APP_ENV")
        ENV.delete("DEPLOY_ENV")
        allow(ActionMailer::Base).to receive(:default_url_options).and_return({ host: "example.com" })
      end

      after do
        ENV.delete("APP_ENV")
        ENV.delete("DEPLOY_ENV")
      end

      it "uses HelloAsso production API (explicit credentials)" do
        expect(described_class.environment).to eq("production")
      end
    end
  end

  describe ".build_unified_checkout_intent_payload" do
    let(:helloasso_creds) { { organization_slug: "grenoble-roller", environment: "sandbox" } }
    let(:checkout) { create(:checkout, donation_cents: 500, total_cents: 5500) }
    let!(:product_line) { create(:checkout_line, :product, checkout: checkout) }
    let!(:membership_line) { create(:checkout_line, :membership, checkout: checkout) }
    let!(:event_line) { create(:checkout_line, :event, checkout: checkout) }
    let(:urls) do
      {
        back_url: "https://example.com/back",
        error_url: "https://example.com/error",
        return_url: "https://example.com/return"
      }
    end

    before do
      allow(Rails.application).to receive(:credentials).and_return(double(helloasso: helloasso_creds))
      subtotal = checkout.checkout_lines.sum(&:subtotal_cents)
      checkout.update!(subtotal_cents: subtotal, total_cents: subtotal + checkout.donation_cents)
      checkout.reload
    end

    it "includes product line items in metadata" do
      payload = described_class.build_unified_checkout_intent_payload(checkout, **urls)
      product_items = payload[:metadata][:items].select { |i| i[:lineType] == "product_variant" }

      expect(product_items).not_to be_empty
      expect(product_items.first[:metadata]).to include("sku" => "SKU-TSHIRT")
    end

    it "includes membership line items in metadata" do
      payload = described_class.build_unified_checkout_intent_payload(checkout, **urls)
      membership_items = payload[:metadata][:items].select { |i| i[:lineType] == "membership" }

      expect(membership_items).not_to be_empty
      expect(payload[:metadata][:membershipIds]).to include(membership_line.reference_id)
    end

    it "includes event_registration line items in metadata" do
      payload = described_class.build_unified_checkout_intent_payload(checkout, **urls)
      event_items = payload[:metadata][:items].select { |i| i[:lineType] == "event_registration" }

      expect(event_items).not_to be_empty
      expect(payload[:metadata][:attendanceIds]).to include(event_line.reference_id)
    end

    it "adds a Donation line when donation_cents is positive" do
      payload = described_class.build_unified_checkout_intent_payload(checkout, **urls)
      donation_items = payload[:metadata][:items].select { |i| i[:type] == "Donation" }

      expect(donation_items.size).to eq(1)
      expect(donation_items.first[:amount]).to eq(500)
    end

    it "sets totalAmount to subtotal_cents plus donation_cents" do
      payload = described_class.build_unified_checkout_intent_payload(checkout, **urls)

      expect(payload[:totalAmount]).to eq(checkout.subtotal_cents + checkout.donation_cents)
      expect(payload[:initialAmount]).to eq(payload[:totalAmount])
    end

    it "sets containsDonation to true when donation is positive" do
      payload = described_class.build_unified_checkout_intent_payload(checkout, **urls)

      expect(payload[:containsDonation]).to be(true)
    end

    it "sets containsDonation to false when donation is zero" do
      checkout_no_donation = create(:checkout, donation_cents: 0)
      create(:checkout_line, :product, checkout: checkout_no_donation)
      checkout_no_donation.update!(
        subtotal_cents: checkout_no_donation.checkout_lines.sum(&:subtotal_cents),
        total_cents: checkout_no_donation.checkout_lines.sum(&:subtotal_cents)
      )
      payload = described_class.build_unified_checkout_intent_payload(checkout_no_donation, **urls)

      expect(payload[:containsDonation]).to be(false)
    end

    it "clamps itemName to 250 chars for multi-membership carts (Recoura case)" do
      long_checkout = create(:checkout, donation_cents: 0, subtotal_cents: 4000, total_cents: 4000)
      labels = [
        "Cotisation Adhérent Grenoble Roller — Saison 2025-2026 (Recoura Eric)",
        "Cotisation Adhérent Grenoble Roller — Saison 2025-2026 (Recoura Suzanne)",
        "Cotisation Adhérent Grenoble Roller — Saison 2025-2026 (Recoura Salomé)",
        "Cotisation Adhérent Grenoble Roller — Saison 2025-2026 (Recoura Elie)"
      ]
      labels.each do |label|
        create(
          :checkout_line,
          :membership,
          checkout: long_checkout,
          label: label,
          amount_cents: 1000,
          quantity: 1
        )
      end
      long_checkout.reload

      joined = labels.map { |label| "#{label} x1" }.join(", ")
      expect(joined.length).to be > described_class::ITEM_NAME_MAX_LENGTH

      payload = described_class.build_unified_checkout_intent_payload(long_checkout, **urls)

      expect(payload[:itemName].length).to be <= described_class::ITEM_NAME_MAX_LENGTH
      expect(payload[:itemName]).to eq("Panier Grenoble Roller (4 articles)")
      expect(payload[:metadata][:items].size).to eq(4)
      expect(payload[:totalAmount]).to eq(4000)
    end
  end

  describe ".clamp_item_name" do
    it "returns joined parts when under the limit" do
      expect(described_class.clamp_item_name([ "A x1", "B x2" ], fallback: "Panier")).to eq("A x1, B x2")
    end

    it "returns fallback when joined parts exceed the limit" do
      parts = Array.new(10) { "Cotisation Adhérent Grenoble Roller — Saison 2025-2026 (Nom Très Long) x1" }
      expect(parts.join(", ").length).to be > described_class::ITEM_NAME_MAX_LENGTH

      result = described_class.clamp_item_name(parts, fallback: "Panier Grenoble Roller (10 articles)")
      expect(result).to eq("Panier Grenoble Roller (10 articles)")
      expect(result.length).to be <= described_class::ITEM_NAME_MAX_LENGTH
    end

    it "truncates fallback when fallback itself exceeds the limit" do
      long_fallback = "X" * (described_class::ITEM_NAME_MAX_LENGTH + 40)
      result = described_class.clamp_item_name([ long_fallback ], fallback: long_fallback)

      expect(result.length).to eq(described_class::ITEM_NAME_MAX_LENGTH)
      expect(result).to end_with("…")
      expect(result[0, described_class::ITEM_NAME_MAX_LENGTH - 1]).to eq("X" * (described_class::ITEM_NAME_MAX_LENGTH - 1))
    end
  end

  describe ".compact_checkout_metadata" do
    it "slims nested item metadata when over the soft byte limit" do
      stub_const("#{described_class}::METADATA_MAX_BYTES", 1_200)

      fat_items = Array.new(4) do |i|
        {
          name: "Article #{i}",
          quantity: 1,
          amount: 1000,
          type: "Membership",
          metadata: { "sku" => "SKU-#{i}", "nested" => { "blob" => "x" * 400 } }
        }
      end
      metadata = {
        checkoutId: 42,
        membershipIds: [ 1, 2, 3 ],
        items: fat_items
      }

      expect(metadata.to_json.bytesize).to be > described_class::METADATA_MAX_BYTES

      compacted = described_class.compact_checkout_metadata(metadata)

      expect(compacted.to_json.bytesize).to be <= described_class::METADATA_MAX_BYTES
      expect(compacted[:checkoutId]).to eq(42)
      expect(compacted[:membershipIds]).to eq([ 1, 2, 3 ])
      expect(compacted[:items]).to be_an(Array)
      expect(compacted[:items].size).to eq(4)
      expect(compacted[:items].first).not_to have_key("metadata")
      expect(compacted[:items].first).not_to have_key(:metadata)
    end
  end

  describe ".create_unified_checkout_intent" do
    let(:helloasso_creds) do
      {
        organization_slug: "grenoble-roller",
        environment: "sandbox",
        client_id: "cid",
        client_secret: "secret"
      }
    end
    let(:checkout) do
      c = create(:checkout, donation_cents: 200, subtotal_cents: 1000, total_cents: 1200)
      create(:checkout_line, :product, checkout: c, amount_cents: 1000)
      c.reload
    end
    let(:urls) do
      {
        back_url: "https://example.com/back",
        error_url: "https://example.com/error",
        return_url: "https://example.com/return"
      }
    end

    before do
      allow(Rails.application).to receive(:credentials).and_return(double(helloasso: helloasso_creds))
      allow(described_class).to receive(:access_token).and_return("token")
    end

    it "posts to checkout-intents with correct totalAmount" do
      http = instance_double(Net::HTTP)
      response = instance_double(Net::HTTPSuccess, body: { id: "ci_1", redirectUrl: "https://pay.example" }.to_json)
      allow(response).to receive(:is_a?).with(Net::HTTPSuccess).and_return(true)
      allow(response).to receive(:code).and_return("200")
      allow(Net::HTTP).to receive(:new).and_return(http)
      allow(http).to receive(:use_ssl=)
      allow(http).to receive(:request).and_return(response)

      result = described_class.create_unified_checkout_intent(checkout, **urls)
      expect(result[:success]).to be(true)
      expect(checkout.reload.total_cents).to eq(1200)
    end

    it "includes donation in totalAmount and metadata donationCents" do
      captured_payload = nil
      http = instance_double(Net::HTTP)
      response = instance_double(Net::HTTPSuccess, body: { id: "ci_2", redirectUrl: "https://pay.example" }.to_json)
      allow(response).to receive(:is_a?).with(Net::HTTPSuccess).and_return(true)
      allow(response).to receive(:code).and_return("200")
      allow(Net::HTTP).to receive(:new).and_return(http)
      allow(http).to receive(:use_ssl=)
      allow(http).to receive(:request) do |request|
        captured_payload = JSON.parse(request.body)
        response
      end

      described_class.create_unified_checkout_intent(checkout, **urls)
      expect(captured_payload["totalAmount"]).to eq(1200)
      expect(captured_payload.dig("metadata", "donationCents")).to eq(200)
    end

    it "includes checkoutId in metadata" do
      captured_payload = nil
      http = instance_double(Net::HTTP)
      response = instance_double(Net::HTTPSuccess, body: { id: "ci_3", redirectUrl: "https://pay.example" }.to_json)
      allow(response).to receive(:is_a?).with(Net::HTTPSuccess).and_return(true)
      allow(response).to receive(:code).and_return("200")
      allow(Net::HTTP).to receive(:new).and_return(http)
      allow(http).to receive(:use_ssl=)
      allow(http).to receive(:request) do |request|
        captured_payload = JSON.parse(request.body)
        response
      end

      described_class.create_unified_checkout_intent(checkout, **urls)
      expect(captured_payload.dig("metadata", "checkoutId")).to eq(checkout.id)
    end

    it "returns redirectUrl on success" do
      http = instance_double(Net::HTTP)
      response = instance_double(Net::HTTPSuccess, body: { id: "ci_4", redirectUrl: "https://pay.example/redirect" }.to_json)
      allow(response).to receive(:is_a?).with(Net::HTTPSuccess).and_return(true)
      allow(response).to receive(:code).and_return("200")
      allow(Net::HTTP).to receive(:new).and_return(http)
      allow(http).to receive(:use_ssl=)
      allow(http).to receive(:request).and_return(response)

      result = described_class.create_unified_checkout_intent(checkout, **urls)
      expect(result.dig(:body, "redirectUrl")).to eq("https://pay.example/redirect")
    end

    it "logs ERROR with response body on HTTP 400" do
      http = instance_double(Net::HTTP)
      error_body = { "message" => "itemName too long" }.to_json
      response = instance_double(Net::HTTPBadRequest, body: error_body, code: "400")
      allow(response).to receive(:is_a?).with(Net::HTTPSuccess).and_return(false)
      allow(Net::HTTP).to receive(:new).and_return(http)
      allow(http).to receive(:use_ssl=)
      allow(http).to receive(:request).and_return(response)

      expect(Rails.logger).to receive(:error).with(
        a_string_matching(/create_unified_checkout_intent ERROR \(400\):.*itemName too long/)
      )

      result = described_class.create_unified_checkout_intent(checkout, **urls)
      expect(result[:success]).to be(false)
      expect(result[:status]).to eq(400)
    end
  end

  describe ".fetch_and_update_payment" do
    let(:helloasso_creds) do
      {
        organization_slug: "grenoble-roller",
        environment: "sandbox",
        client_id: "cid",
        client_secret: "secret"
      }
    end

    before do
      allow(Rails.application).to receive(:credentials).and_return(double(helloasso: helloasso_creds))
      allow(described_class).to receive(:access_token).and_return("token")
    end

    context "when payment is linked to a checkout" do
      it "calls CheckoutFulfillmentService on success" do
        payment = create(:payment, provider: "helloasso", status: "pending", provider_payment_id: "intent_checkout")
        checkout = create(:checkout, :processing, payment: payment)
        create(:checkout_line, checkout: checkout, line_type: :membership, reference: create(:membership, :pending, :with_health_questionnaire))

        allow(described_class).to receive(:fetch_checkout_intent).and_return({ "order" => { "id" => "ha_order_1" } })
        allow(described_class).to receive(:fetch_helloasso_order).and_return({ "state" => "Confirmed" })

        expect(CheckoutFulfillmentService).to receive(:fulfill!).with(having_attributes(id: checkout.id), payment: kind_of(Payment))

        described_class.fetch_and_update_payment(payment)
      end

      it "does not fulfill when payment still pending" do
        payment = create(:payment, provider: "helloasso", status: "pending", provider_payment_id: "intent_pending")
        create(:checkout, :processing, payment: payment)

        allow(described_class).to receive(:fetch_checkout_intent).and_return({})

        expect(CheckoutFulfillmentService).not_to receive(:fulfill!)

        described_class.fetch_and_update_payment(payment)
        expect(payment.reload.status).to eq("pending")
      end
    end

    context "legacy order-only payment" do
      it "still updates order status without checkout" do
        payment = create(:payment, provider: "helloasso", status: "pending", provider_payment_id: "intent_order")
        order = create(:order, payment: payment, status: "pending")

        allow(described_class).to receive(:fetch_checkout_intent).and_return({ "order" => { "id" => "ha_order_2" } })
        allow(described_class).to receive(:fetch_helloasso_order).and_return({ "state" => "Confirmed" })

        described_class.fetch_and_update_payment(payment)
        expect(order.reload.status).to eq("paid")
      end
    end

    context "legacy membership-only payment" do
      it "still activates membership without checkout" do
        payment = create(:payment, provider: "helloasso", status: "pending", provider_payment_id: "intent_mem")
        membership = create(:membership, :pending, :with_health_questionnaire, payment: payment)

        allow(described_class).to receive(:fetch_checkout_intent).and_return({ "order" => { "id" => "ha_order_3" } })
        allow(described_class).to receive(:fetch_helloasso_order).and_return({ "state" => "Confirmed" })

        described_class.fetch_and_update_payment(payment)
        expect(membership.reload).to be_active
      end
    end
  end
end
