# frozen_string_literal: true

require 'rails_helper'

RSpec.describe AdminPanel::InventoryPolicy do
  subject(:policy) { described_class.new(user, inventory) }

  let(:inventory) { build(:inventory) }
  let(:admin_role) { Role.find_or_create_by!(code: 'ADMIN') { |r| r.name = 'Administrateur'; r.level = 60 } }
  let(:organizer_role) { Role.find_or_create_by!(code: 'ORGANIZER') { |r| r.name = 'Organisateur'; r.level = 40 } }

  describe '#index?' do
    context 'when user is admin (level 60)' do
      let(:user) { create(:user, role: admin_role) }

      it { expect(policy.index?).to be(true) }
    end

    context 'when user is organizer (level 40)' do
      let(:user) { create(:user, role: organizer_role) }

      it { expect(policy.index?).to be(false) }
    end

    context 'when user has no role' do
      let(:user) { create(:user, role: nil) }

      it { expect(policy.index?).to be(false) }
    end
  end

  describe '#show?' do
    context 'when user is admin (level 60)' do
      let(:user) { create(:user, role: admin_role) }

      it { expect(policy.show?).to be(true) }
    end

    context 'when user is organizer (level 40)' do
      let(:user) { create(:user, role: organizer_role) }

      it { expect(policy.show?).to be(false) }
    end
  end

  describe '#create?' do
    context 'when user is admin (level 60)' do
      let(:user) { create(:user, role: admin_role) }

      it { expect(policy.create?).to be(true) }
    end

    context 'when user is organizer (level 40)' do
      let(:user) { create(:user, role: organizer_role) }

      it { expect(policy.create?).to be(false) }
    end
  end

  describe '#update?' do
    context 'when user is admin (level 60)' do
      let(:user) { create(:user, role: admin_role) }

      it { expect(policy.update?).to be(true) }
    end

    context 'when user is organizer (level 40)' do
      let(:user) { create(:user, role: organizer_role) }

      it { expect(policy.update?).to be(false) }
    end
  end

  describe '#destroy?' do
    context 'when user is admin (level 60)' do
      let(:user) { create(:user, role: admin_role) }

      it { expect(policy.destroy?).to be(true) }
    end

    context 'when user is organizer (level 40)' do
      let(:user) { create(:user, role: organizer_role) }

      it { expect(policy.destroy?).to be(false) }
    end
  end

  describe '#transfers?' do
    context 'when user is admin (level 60)' do
      let(:user) { create(:user, role: admin_role) }

      it { expect(policy.transfers?).to be(true) }
    end

    context 'when user is organizer (level 40)' do
      let(:user) { create(:user, role: organizer_role) }

      it { expect(policy.transfers?).to be(false) }
    end
  end

  describe '#adjust_stock?' do
    context 'when user is admin (level 60)' do
      let(:user) { create(:user, role: admin_role) }

      it { expect(policy.adjust_stock?).to be(true) }
    end

    context 'when user is organizer (level 40)' do
      let(:user) { create(:user, role: organizer_role) }

      it { expect(policy.adjust_stock?).to be(false) }
    end
  end
end
