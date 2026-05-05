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
end
