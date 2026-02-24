require 'rails_helper'

RSpec.describe AdminPanel::Event::InitiationPolicy do
  subject(:policy) { described_class.new(user, initiation) }

  let(:creator_user) { create(:user) } # Utilisateur avec rôle par défaut
  let(:initiation) { create(:event_initiation, creator_user: creator_user) }
  let(:initiation_role) { Role.find_or_create_by!(code: 'INITIATION') { |r| r.name = 'Initiation'; r.level = 30 } }
  let(:organizer_role) { Role.find_or_create_by!(code: 'ORGANIZER') { |r| r.name = 'Organisateur'; r.level = 40 } }
  let(:moderator_role) { Role.find_or_create_by!(code: 'MODERATOR') { |r| r.name = 'Modérateur'; r.level = 50 } }
  let(:admin_role) { Role.find_or_create_by!(code: 'ADMIN') { |r| r.name = 'Administrateur'; r.level = 60 } }
  let(:superadmin_role) { Role.find_or_create_by!(code: 'SUPERADMIN') { |r| r.name = 'Super Administrateur'; r.level = 70 } }

  describe '#index?' do
    context 'when user is initiation (level 30)' do
      let(:user) { create(:user, role: initiation_role) }

      it { expect(policy.index?).to be(true) }
    end

    context 'when user is organizer (level 40)' do
      let(:user) { create(:user, role: organizer_role) }

      it { expect(policy.index?).to be(true) }
    end

    context 'when user is moderator (level 50)' do
      let(:user) { create(:user, role: moderator_role) }

      it { expect(policy.index?).to be(true) }
    end

    context 'when user is admin (level 60)' do
      let(:user) { create(:user, role: admin_role) }

      it { expect(policy.index?).to be(true) }
    end

    context 'when user is superadmin (level 70)' do
      let(:user) { create(:user, role: superadmin_role) }

      it { expect(policy.index?).to be(true) }
    end

    context 'when user level is below 30' do
      let(:user) { create(:user) } # level 10 par défaut

      it { expect(policy.index?).to be(false) }
    end

    context 'when user is nil' do
      let(:user) { nil }

      it { expect(policy.index?).to be(false) }
    end
  end

  describe '#show?' do
    context 'when user is organizer (level 40)' do
      let(:user) { create(:user, role: organizer_role) }

      it { expect(policy.show?).to be(true) }
    end

    context 'when user is admin (level 60)' do
      let(:user) { create(:user, role: admin_role) }

      it { expect(policy.show?).to be(true) }
    end

    context 'when user level is below 30' do
      let(:user) { create(:user) }

      it { expect(policy.show?).to be(false) }
    end
  end

  describe '#create?' do
    context 'when user is organizer (level 40)' do
      let(:user) { create(:user, role: organizer_role) }

      it { expect(policy.create?).to be(false) }
    end

    context 'when user is moderator (level 50)' do
      let(:user) { create(:user, role: moderator_role) }

      it { expect(policy.create?).to be(false) }
    end

    context 'when user is admin (level 60)' do
      let(:user) { create(:user, role: admin_role) }

      it { expect(policy.create?).to be(true) }
    end

    context 'when user is superadmin (level 70)' do
      let(:user) { create(:user, role: superadmin_role) }

      it { expect(policy.create?).to be(true) }
    end

    context 'when user is initiation (level 30)' do
      let(:user) { create(:user, role: initiation_role) }

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
    context 'when user is organizer (level 40)' do
      let(:user) { create(:user, role: organizer_role) }

      it { expect(policy.destroy?).to be(false) }
    end

    context 'when user is moderator (level 50)' do
      let(:user) { create(:user, role: moderator_role) }

      it { expect(policy.destroy?).to be(false) }
    end

    context 'when user is admin (level 60)' do
      let(:user) { create(:user, role: admin_role) }

      it { expect(policy.destroy?).to be(true) }
    end

    context 'when user is initiation (level 30)' do
      let(:user) { create(:user, role: initiation_role) }

      it { expect(policy.destroy?).to be(false) }
    end
  end

  describe '#presences?' do
    context 'when user is admin (level 60)' do
      let(:user) { create(:user, role: admin_role) }

      it { expect(policy.presences?).to be(true) }
    end

    context 'when user is organizer (level 40)' do
      let(:user) { create(:user, role: organizer_role) }

      it { expect(policy.presences?).to be(false) }
    end
  end

  describe '#update_presences?' do
    context 'when user is admin (level 60)' do
      let(:user) { create(:user, role: admin_role) }

      it { expect(policy.update_presences?).to be(true) }
    end

    context 'when user is organizer (level 40)' do
      let(:user) { create(:user, role: organizer_role) }

      it { expect(policy.update_presences?).to be(false) }
    end
  end

  describe '#convert_waitlist?' do
    context 'when user is admin (level 60)' do
      let(:user) { create(:user, role: admin_role) }

      it { expect(policy.convert_waitlist?).to be(true) }
    end

    context 'when user is organizer (level 40)' do
      let(:user) { create(:user, role: organizer_role) }

      it { expect(policy.convert_waitlist?).to be(false) }
    end
  end

  describe '#notify_waitlist?' do
    context 'when user is admin (level 60)' do
      let(:user) { create(:user, role: admin_role) }

      it { expect(policy.notify_waitlist?).to be(true) }
    end

    context 'when user is organizer (level 40)' do
      let(:user) { create(:user, role: organizer_role) }

      it { expect(policy.notify_waitlist?).to be(false) }
    end
  end

  describe '#toggle_volunteer?' do
    context 'when user is admin (level 60)' do
      let(:user) { create(:user, role: admin_role) }

      it { expect(policy.toggle_volunteer?).to be(true) }
    end

    context 'when user is organizer (level 40)' do
      let(:user) { create(:user, role: organizer_role) }

      it { expect(policy.toggle_volunteer?).to be(false) }
    end
  end
end
