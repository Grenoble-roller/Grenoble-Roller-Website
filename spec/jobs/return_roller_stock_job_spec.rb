# frozen_string_literal: true

require "rails_helper"

RSpec.describe ReturnRollerStockJob, type: :job do
  let!(:organizer_role) { ensure_role(code: "ORGANIZER", name: "Organisateur", level: 40) }
  let!(:organizer) { create_user(role: organizer_role) }
  let!(:roller_stock_38) { create(:roller_stock, size: "38", quantity: 5, is_active: true) }
  let!(:roller_stock_40) { create(:roller_stock, size: "40", quantity: 3, is_active: true) }

  before do
    allow_any_instance_of(Event::Initiation).to receive(:schedule_participants_report)
  end

  describe "#perform" do
    context "when there are no finished initiations" do
      it "does not change stock or stock_returned_at" do
        u = create_user
        create(:membership, user: u, status: :active, season: "2025-2026")
        initiation = create_event(
          type: "Event::Initiation",
          status: "published",
          creator_user: organizer,
          start_at: 1.week.from_now,
          duration_min: 60,
          max_participants: 20
        )
        create_attendance(user: u, event: initiation, status: "registered", needs_equipment: true, roller_size: "38")

        expect { ReturnRollerStockJob.perform_now }.not_to change { roller_stock_38.reload.quantity }
        expect(initiation.reload.stock_returned_at).to be_nil
      end
    end

    context "when there are finished initiations with equipment not yet returned" do
      let(:user1) { create_user.tap { |u| create(:membership, user: u, status: :active, season: "2025-2026") } }
      let(:user2) { create_user.tap { |u| create(:membership, user: u, status: :active, season: "2025-2026") } }
      let(:initiation) do
        create_event(
          type: "Event::Initiation",
          status: "published",
          creator_user: organizer,
          start_at: 2.hours.ago,
          duration_min: 60,
          max_participants: 20
        )
      end

      before do
        create_attendance(user: user1, event: initiation, status: "registered", needs_equipment: true, roller_size: "38")
        create_attendance(user: user2, event: initiation, status: "registered", needs_equipment: true, roller_size: "40")
      end

      it "increments stock and sets stock_returned_at for the initiation" do
        expect(initiation.stock_returned_at).to be_nil
        expect(roller_stock_38.reload.quantity).to eq(4)
        expect(roller_stock_40.reload.quantity).to eq(2)

        ReturnRollerStockJob.perform_now

        expect(roller_stock_38.reload.quantity).to eq(5)
        expect(roller_stock_40.reload.quantity).to eq(3)
        expect(initiation.reload.stock_returned_at).to be_present
      end
    end

    context "when initiation already has stock_returned_at set" do
      let(:user1) { create_user.tap { |u| create(:membership, user: u, status: :active, season: "2025-2026") } }
      let(:initiation) do
        create_event(
          type: "Event::Initiation",
          status: "published",
          creator_user: organizer,
          start_at: 2.hours.ago,
          duration_min: 60,
          max_participants: 20
        )
      end

      before do
        create_attendance(user: user1, event: initiation, status: "registered", needs_equipment: true, roller_size: "38")
        initiation.update_column(:stock_returned_at, 1.day.ago)
        roller_stock_38.reload
      end

      it "does not process the initiation again" do
        ReturnRollerStockJob.perform_now
        expect(roller_stock_38.reload.quantity).to eq(4)
      end
    end

    context "when initiation has only canceled attendances with equipment" do
      let(:user1) { create_user.tap { |u| create(:membership, user: u, status: :active, season: "2025-2026") } }
      let(:initiation) do
        create_event(
          type: "Event::Initiation",
          status: "published",
          creator_user: organizer,
          start_at: 2.hours.ago,
          duration_min: 60,
          max_participants: 20
        )
      end

      before do
        create_attendance(user: user1, event: initiation, status: "canceled", needs_equipment: true, roller_size: "38")
      end

      it "does not double-increment stock (canceled already gave back on status change)" do
        qty_before = roller_stock_38.reload.quantity
        ReturnRollerStockJob.perform_now
        expect(roller_stock_38.reload.quantity).to eq(qty_before)
        expect(initiation.reload.stock_returned_at).to be_nil
      end
    end
  end
end
