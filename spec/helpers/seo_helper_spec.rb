# frozen_string_literal: true

require "rails_helper"

RSpec.describe SeoHelper, type: :helper do
  describe "#seo_json_ld" do
    it "puts JSON-LD in the script body, not a content attribute" do
      html = helper.seo_json_ld

      expect(html).to include('type="application/ld+json"')
      expect(html).not_to match(/<script[^>]*\scontent="/)
      expect(html).to include('"@type":"Organization"')
      expect(html).to match(%r{</script>\z})
    end
  end

  describe "#seo_og_tags" do
    it "includes a non-empty og:description from the default copy" do
      html = helper.seo_og_tags

      expect(html).to include('property="og:description"')
      expect(html).to include("Boutique en ligne")
    end
  end
end
