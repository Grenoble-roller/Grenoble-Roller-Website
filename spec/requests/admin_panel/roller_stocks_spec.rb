# frozen_string_literal: true

require "rails_helper"

RSpec.describe "AdminPanel::RollerStocks", type: :request do
  include RequestAuthenticationHelper

  let(:admin_role) { Role.find_or_create_by!(code: "ADMIN") { |r| r.name = "Administrateur"; r.level = 60 } }
  let(:admin_user) { create(:user, :admin) }
  let(:user_role) { Role.find_or_create_by!(code: "USER") { |r| r.name = "Utilisateur"; r.level = 10 } }
  let(:regular_user) { create(:user, role: user_role) }
  let!(:roller_stock) { create(:roller_stock, size: "38", quantity: 5, is_active: true) }

  describe "GET /admin-panel/roller-stocks" do
    context "when user is admin" do
      before { sign_in admin_user }

      it "returns success" do
        get admin_panel_roller_stocks_path
        expect(response).to have_http_status(:success)
      end

      it "displays roller stocks" do
        get admin_panel_roller_stocks_path
        expect(response.body).to include("Stock Rollers")
        expect(response.body).to include("38")
      end

      it "displays Tout remettre en stock button" do
        get admin_panel_roller_stocks_path
        expect(response.body).to include("Tout remettre en stock")
      end
    end

    context "when user is not admin" do
      before { sign_in regular_user }

      it "redirects with not authorized" do
        get admin_panel_roller_stocks_path
        expect(response).to redirect_to(root_path)
        expect(flash[:alert]).to be_present
      end
    end

    context "when user is not signed in" do
      it "redirects to login" do
        get admin_panel_roller_stocks_path
        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end

  describe "POST /admin-panel/roller-stocks/return_all" do
    context "when user is admin" do
      before { sign_in admin_user }

      context "when there are no finished initiations to process" do
        it "redirects with notice that nothing to process" do
          post return_all_admin_panel_roller_stocks_path
          expect(response).to redirect_to(admin_panel_roller_stocks_path)
          expect(flash[:notice]).to include("Aucune initiation terminée à traiter")
        end
      end

      context "when there are finished initiations with equipment not yet returned" do
        let!(:organizer_role) { Role.find_or_create_by!(code: "ORGANIZER") { |r| r.name = "Organisateur"; r.level = 40 } }
        let!(:organizer) { create(:user, role: organizer_role) }
        let!(:participant) { create(:user).tap { |u| create(:membership, user: u, status: :active, season: "2025-2026") } }
        let!(:initiation) do
          create(:event_initiation,
            status: "published",
            creator_user: organizer,
            start_at: 2.hours.ago,
            duration_min: 60)
        end
        let!(:attendance) do
          create(:attendance, :with_equipment, event: initiation, user: participant, status: "registered", roller_size: "38")
        end

        before do
          allow_any_instance_of(::Event::Initiation).to receive(:schedule_participants_report)
        end

        it "redirects with success notice and increments stock" do
          expect(initiation.stock_returned_at).to be_nil
          qty_before = roller_stock.reload.quantity

          post return_all_admin_panel_roller_stocks_path

          expect(response).to redirect_to(admin_panel_roller_stocks_path)
          expect(flash[:notice]).to match(/\d+ initiation\(s\) traitée\(s\).*\d+ roller\(s\) remis/)
          expect(initiation.reload.stock_returned_at).to be_present
          expect(roller_stock.reload.quantity).to eq(qty_before + 1)
        end
      end
    end

    context "when user is not admin" do
      before { sign_in regular_user }

      it "redirects with not authorized" do
        post return_all_admin_panel_roller_stocks_path
        expect(response).to redirect_to(root_path)
        expect(flash[:alert]).to be_present
      end
    end

    context "when user is not signed in" do
      it "redirects to login" do
        post return_all_admin_panel_roller_stocks_path
        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end
end
