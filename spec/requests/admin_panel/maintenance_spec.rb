# frozen_string_literal: true

require "rails_helper"

RSpec.describe "AdminPanel::Maintenance", type: :request do
  include RequestAuthenticationHelper

  let(:superadmin_role) { Role.find_or_create_by!(code: "SUPERADMIN") { |r| r.name = "Super Administrateur"; r.level = 70 } }

  describe "PATCH /admin-panel/maintenance/toggle" do
    context "when user is superadmin (level 70)" do
      let(:superadmin_user) { create(:user, :superadmin) }

      before { login_user(superadmin_user) }

      it "allows toggle and redirects to admin panel root" do
        patch toggle_admin_panel_maintenance_path
        expect(response).to redirect_to(admin_panel_root_path)
        expect(flash[:notice]).to be_present
      end
    end

    context "when user is admin (level 60)" do
      let(:admin_user) { create(:user, :admin) }

      before { login_user(admin_user) }

      it "allows toggle (MaintenancePolicy uses level >= 60)" do
        patch toggle_admin_panel_maintenance_path
        expect(response).to redirect_to(admin_panel_root_path)
        expect(flash[:notice]).to be_present
      end
    end

    context "when user is organizer (level 40)" do
      let(:organizer_role) { Role.find_or_create_by!(code: "ORGANIZER") { |r| r.name = "Organisateur"; r.level = 40 } }
      let(:organizer_user) { create(:user, role: organizer_role) }

      before { login_user(organizer_user) }

      it "redirects with not authorized" do
        patch toggle_admin_panel_maintenance_path
        expect(response).to redirect_to(root_path)
        expect(flash[:alert]).to be_present
      end
    end

    context "when user is not signed in" do
      it "redirects to login" do
        patch toggle_admin_panel_maintenance_path
        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end
end
