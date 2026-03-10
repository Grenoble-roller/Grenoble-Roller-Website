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

  describe "GET /admin-panel/homepage-carousels/:id (show)" do
    before { login_user(organizer_user) }

    it "returns success for an existing carousel" do
      carousel = create(:homepage_carousel, :with_image, position: 1)
      get admin_panel_homepage_carousel_path(carousel)
      expect(response).to have_http_status(:success)
      expect(response.body).to include(carousel.title)
    end
  end

  describe "POST /admin-panel/homepage-carousels (create)" do
    before { login_user(organizer_user) }

    it "creates a carousel with valid params and redirects with flash" do
      expect {
        post admin_panel_homepage_carousels_path, params: {
          homepage_carousel: { title: "Nouveau slide", subtitle: "Sous-titre", position: 1, published: false }
        }
      }.to change(HomepageCarousel, :count).by(1)

      expect(response).to redirect_to(admin_panel_homepage_carousel_path(HomepageCarousel.last))
      expect(flash[:notice]).to eq("Slide créé avec succès")
    end
  end

  describe "PATCH /admin-panel/homepage-carousels/:id (update)" do
    before { login_user(organizer_user) }

    it "updates the carousel and redirects" do
      carousel = create(:homepage_carousel, title: "Ancien titre", position: 1)
      patch admin_panel_homepage_carousel_path(carousel), params: {
        homepage_carousel: { title: "Nouveau titre", subtitle: carousel.subtitle, position: carousel.position, published: carousel.published }
      }
      expect(response).to redirect_to(admin_panel_homepage_carousel_path(carousel))
      expect(flash[:notice]).to eq("Slide mis à jour avec succès")
      expect(carousel.reload.title).to eq("Nouveau titre")
    end
  end

  describe "DELETE /admin-panel/homepage-carousels/:id (destroy)" do
    before { login_user(organizer_user) }

    it "destroys the carousel and redirects to index" do
      carousel = create(:homepage_carousel, position: 1)
      expect {
        delete admin_panel_homepage_carousel_path(carousel)
      }.to change(HomepageCarousel, :count).by(-1)
      expect(response).to redirect_to(admin_panel_homepage_carousels_path)
      expect(flash[:notice]).to eq("Slide supprimé avec succès")
    end
  end

  describe "POST publish / unpublish" do
    before { login_user(organizer_user) }

    it "publish sets published to true and redirects" do
      carousel = create(:homepage_carousel, :with_image, position: 1, published: false)
      post publish_admin_panel_homepage_carousel_path(carousel)
      expect(response).to redirect_to(admin_panel_homepage_carousel_path(carousel))
      expect(flash[:notice]).to eq("Slide publié avec succès")
      expect(carousel.reload.published).to eq(true)
    end

    it "unpublish sets published to false and redirects" do
      carousel = create(:homepage_carousel, :with_image, position: 1, published: true)
      post unpublish_admin_panel_homepage_carousel_path(carousel)
      expect(response).to redirect_to(admin_panel_homepage_carousel_path(carousel))
      expect(flash[:notice]).to eq("Slide dépublié avec succès")
      expect(carousel.reload.published).to eq(false)
    end
  end

  describe "PATCH move_up / move_down" do
    before { login_user(organizer_user) }

    it "move_up redirects to index" do
      c1 = create(:homepage_carousel, position: 1)
      c2 = create(:homepage_carousel, position: 2)
      patch move_up_admin_panel_homepage_carousel_path(c2)
      expect(response).to redirect_to(admin_panel_homepage_carousels_path)
    end

    it "move_down redirects to index" do
      c1 = create(:homepage_carousel, position: 1)
      c2 = create(:homepage_carousel, position: 2)
      patch move_down_admin_panel_homepage_carousel_path(c1)
      expect(response).to redirect_to(admin_panel_homepage_carousels_path)
    end
  end
end
