require 'rails_helper'

RSpec.describe AdminPanel::RolePolicy do
  subject(:policy) { described_class.new(user, role) }

  let(:role) { create(:role) }
  let(:admin_role) { Role.find_or_create_by!(code: 'ADMIN') { |r| r.name = 'Administrateur'; r.level = 60 } }
  let(:organizer_role) { Role.find_or_create_by!(code: 'ORGANIZER') { |r| r.name = 'Organisateur'; r.level = 40 } }
  let(:superadmin_role) { Role.find_or_create_by!(code: 'SUPERADMIN') { |r| r.name = 'Super Administrateur'; r.level = 70 } }

  describe '#index?' do
    context 'when user is superadmin (level 70)' do
      let(:user) { create(:user, role: superadmin_role) }

      it { expect(policy.index?).to be(true) }
    end

    context 'when user is admin (level 60)' do
      let(:user) { create(:user, role: admin_role) }

      it { expect(policy.index?).to be(false) }
    end

    context 'when user is organizer (level 40)' do
      let(:user) { create(:user, role: organizer_role) }

      it { expect(policy.index?).to be(false) }
    end
  end

  describe '#show?' do
    context 'when user is superadmin (level 70)' do
      let(:user) { create(:user, role: superadmin_role) }

      it { expect(policy.show?).to be(true) }
    end

    context 'when user is admin (level 60)' do
      let(:user) { create(:user, role: admin_role) }

      it { expect(policy.show?).to be(false) }
    end

    context 'when user is organizer (level 40)' do
      let(:user) { create(:user, role: organizer_role) }

      it { expect(policy.show?).to be(false) }
    end
  end

  describe '#create?' do
    context 'when user is superadmin (level 70)' do
      let(:user) { create(:user, role: superadmin_role) }

      it { expect(policy.create?).to be(true) }
    end

    context 'when user is admin (level 60)' do
      let(:user) { create(:user, role: admin_role) }

      it { expect(policy.create?).to be(false) }
    end

    context 'when user is organizer (level 40)' do
      let(:user) { create(:user, role: organizer_role) }

      it { expect(policy.create?).to be(false) }
    end
  end

  describe '#update?' do
    context 'when user is superadmin (level 70)' do
      let(:user) { create(:user, role: superadmin_role) }

      it { expect(policy.update?).to be(true) }
    end

    context 'when user is admin (level 60)' do
      let(:user) { create(:user, role: admin_role) }

      it { expect(policy.update?).to be(false) }
    end

    context 'when user is organizer (level 40)' do
      let(:user) { create(:user, role: organizer_role) }

      it { expect(policy.update?).to be(false) }
    end
  end

  describe '#destroy?' do
    context 'when user is superadmin (level 70)' do
      let(:user) { create(:user, role: superadmin_role) }

      it { expect(policy.destroy?).to be(true) }
    end

    context 'when user is admin (level 60)' do
      let(:user) { create(:user, role: admin_role) }

      it { expect(policy.destroy?).to be(false) }
    end

    context 'when user is organizer (level 40)' do
      let(:user) { create(:user, role: organizer_role) }

      it { expect(policy.destroy?).to be(false) }
    end
  end
end
