require 'rails_helper'

RSpec.describe AdminPanel::HomepageCarouselPolicy do
  subject(:policy) { described_class.new(user, carousel) }

  let(:carousel) { HomepageCarousel.new }
  let(:organizer_role) { Role.find_or_create_by!(code: 'ORGANIZER') { |r| r.name = 'Organisateur'; r.level = 40 } }
  let(:admin_role) { Role.find_or_create_by!(code: 'ADMIN') { |r| r.name = 'Administrateur'; r.level = 60 } }
  let(:user_role) { Role.find_or_create_by!(code: 'USER') { |r| r.name = 'Utilisateur'; r.level = 10 } }

  describe '#index?' do
    context 'when user is organizer (level 40)' do
      let(:user) { create(:user, role: organizer_role) }

      it { expect(policy.index?).to be(true) }
    end

    context 'when user is admin (level 60)' do
      let(:user) { create(:user, role: admin_role) }

      it { expect(policy.index?).to be(true) }
    end

    context 'when user is below organizer (level 10)' do
      let(:user) { create(:user, role: user_role) }

      it { expect(policy.index?).to be(false) }
    end

    context 'when user is nil' do
      let(:user) { nil }

      it { expect(policy.index?).to be(false) }
    end
  end

  describe 'when user is organizer' do
    let(:user) { create(:user, role: organizer_role) }

    it { expect(policy.show?).to be(true) }
    it { expect(policy.create?).to be(true) }
    it { expect(policy.update?).to be(true) }
    it { expect(policy.destroy?).to be(true) }
  end
end
