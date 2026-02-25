# frozen_string_literal: true

require "rails_helper"

RSpec.describe "AdminPanel::HomepageCarousels", type: :request do
  include RequestAuthenticationHelper

  let(:admin_user) { create(:user, :admin) }
  let(:organizer_role) { Role.find_or_create_by!(code: "ORGANIZER") { |r| r.name = "Organisateur"; r.level = 40 } }
  let(:organizer_user) { create(:user, role: organizer_role) }

  describe "GET /admin-panel/homepage-carousels" do
    context "when user is admin (level 60)" do
      before { login_user(admin_user) }

      it "returns success" do
        get admin_panel_homepage_carousels_path
        expect(response).to have_http_status(:success)
      end
    end

    context "when user is organizer (level 40)" do
      before { login_user(organizer_user) }

      it "returns success (organizer+ can access)" do
        get admin_panel_homepage_carousels_path
        expect(response).to have_http_status(:success)
      end
    end

    context "when user is not signed in" do
      it "redirects to login" do
        get admin_panel_homepage_carousels_path
        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end

  describe "GET /admin-panel/homepage-carousels/new" do
    before { login_user(admin_user) }

    it "returns success" do
      get new_admin_panel_homepage_carousel_path
      expect(response).to have_http_status(:success)
    end
  end
end
