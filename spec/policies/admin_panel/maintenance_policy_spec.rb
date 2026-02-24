# frozen_string_literal: true

require "rails_helper"

RSpec.describe AdminPanel::MaintenancePolicy do
  subject(:policy) { described_class.new(user, :maintenance) }

  let(:admin_role) { Role.find_or_create_by!(code: "ADMIN") { |r| r.name = "Administrateur"; r.level = 60 } }
  let(:superadmin_role) { Role.find_or_create_by!(code: "SUPERADMIN") { |r| r.name = "Super Administrateur"; r.level = 70 } }
  let(:organizer_role) { Role.find_or_create_by!(code: "ORGANIZER") { |r| r.name = "Organisateur"; r.level = 40 } }

  describe "#toggle?" do
    context "when user is superadmin (level 70)" do
      let(:user) { create(:user, role: superadmin_role) }

      it { expect(policy.toggle?).to be(true) }
    end

    context "when user is admin (level 60)" do
      let(:user) { create(:user, role: admin_role) }

      it { expect(policy.toggle?).to be(true) }
    end

    context "when user is organizer (level 40)" do
      let(:user) { create(:user, role: organizer_role) }

      it { expect(policy.toggle?).to be(false) }
    end

    context "when user is nil" do
      let(:user) { nil }

      it { expect(policy.toggle?).to be(false) }
    end
  end
end
