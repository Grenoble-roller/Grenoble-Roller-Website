require 'rails_helper'

RSpec.describe EventPolicy do
  include TestDataHelper

  subject(:policy) { described_class.new(user, event) }

  let(:organizer_role) { Role.find_or_create_by!(code: 'ORGANIZER') { |r| r.name = 'Organisateur'; r.level = 40 } }
  let(:admin_role) { Role.find_or_create_by!(code: 'ADMIN') { |r| r.name = 'Administrateur'; r.level = 60 } }
  let(:user_role) { ensure_role(code: 'USER', name: 'Utilisateur', level: 10) }
  let(:owner) { create_user(role: organizer_role) }
  let(:event) { create(:event, creator_user: owner) }
  let(:user) { owner }

  describe '#show?' do
    context 'when event is published' do
      let(:event) { create(:event, :published, creator_user: owner) }

      it 'allows a guest' do
        user = nil
        expect(described_class.new(user, event).show?).to be(true)
      end
    end

    context 'when event is draft' do
      it 'denies a guest' do
        user = nil
        expect(described_class.new(user, event).show?).to be(false)
      end

      it 'allows the organizer-owner' do
        expect(described_class.new(owner, event).show?).to be(true)
      end
    end
  end

  describe '#create?' do
    it 'allows an organizer' do
      organizer = create_user(role: organizer_role)
      new_event = build(:event, creator_user: organizer)

      expect(described_class.new(organizer, new_event).create?).to be(true)
    end

    it 'denies a regular member' do
      member = create_user
      new_event = build(:event, creator_user: member)

      expect(described_class.new(member, new_event).create?).to be(false)
    end
  end

  describe '#update?' do
    it 'allows the organizer-owner' do
      expect(policy.update?).to be(true)
    end

    it 'denies an organizer who is not the owner' do
      other = create_user(role: organizer_role)
      expect(described_class.new(other, event).update?).to be(false)
    end

    it 'allows an admin' do
      admin = create_user(role: admin_role)
      expect(described_class.new(admin, event).update?).to be(true)
    end
  end

  describe '#destroy?' do
    it 'denies the owner' do
      expect(policy.destroy?).to be(false)
    end

    it 'allows an admin' do
      admin = create_user(role: admin_role)
      expect(described_class.new(admin, event).destroy?).to be(true)
    end

    it 'denies a regular member' do
      member = create_user
      expect(described_class.new(member, event).destroy?).to be(false)
    end

    it 'denies an organizer who is not admin' do
      organizer = create_user(role: organizer_role)
      expect(described_class.new(organizer, event).destroy?).to be(false)
    end
  end

  describe '#attend?' do
    it 'allows any signed-in user when event has available spots' do
      member = create_user(role: user_role)
      create(:membership, user: member, status: :active, season: '2025-2026')
      event = build_event(status: 'published', max_participants: 10)
      event.save!
      expect(described_class.new(member, event).attend?).to be(true)
    end

    it 'allows any signed-in user when event is unlimited' do
      member = create_user(role: user_role)
      create(:membership, user: member, status: :active, season: '2025-2026')
      event = build_event(status: 'published', max_participants: 0)
      event.save!
      expect(described_class.new(member, event).attend?).to be(true)
    end

    it 'denies when event is full' do
      member = create_user(role: user_role)
      create(:membership, user: member, status: :active, season: '2025-2026')
      event = build_event(status: 'published', max_participants: 2)
      event.save!
      # Fill the event
      user1 = create_user(role: user_role)
      user2 = create_user(role: user_role)
      create(:membership, user: user1, status: :active, season: '2025-2026')
      create(:membership, user: user2, status: :active, season: '2025-2026')
      create(:attendance, event: event, user: user1, status: 'registered')
      create(:attendance, event: event, user: user2, status: 'registered')
      event.reload
      expect(described_class.new(member, event).attend?).to be(false)
    end

    it 'denies guests' do
      expect(described_class.new(nil, event).attend?).to be(false)
    end
  end

  describe '#can_attend?' do
    let(:member) { create_user(role: user_role) }
    let!(:member_membership) { create(:membership, user: member, status: :active, season: '2025-2026') }
    let(:event) do
      e = build_event(status: 'published', max_participants: 10)
      e.save!
      e
    end

    it 'returns true when user can attend and is not already registered' do
      expect(described_class.new(member, event).can_attend?).to be(true)
    end

    it 'returns false when user is already registered' do
      create(:attendance, event: event, user: member, status: 'registered')
      event.reload
      expect(described_class.new(member, event).can_attend?).to be(false)
    end

    it 'returns false when event is full' do
      full_event = build_event(status: 'published', max_participants: 1)
      full_event.save!
      user = create_user(role: user_role)
      create(:membership, user: user, status: :active, season: '2025-2026')
      create(:attendance, event: full_event, user: user, status: 'registered')
      full_event.reload
      expect(described_class.new(member, full_event).can_attend?).to be(false)
    end
  end

  describe '#user_has_attendance?' do
    let(:member) { create_user(role: user_role) }
    let!(:member_membership) { create(:membership, user: member, status: :active, season: '2025-2026') }
    let(:event) do
      e = build_event(status: 'published')
      e.save!
      e
    end

    it 'returns true when user has an attendance' do
      create(:attendance, event: event, user: member, status: 'registered')
      event.reload
      expect(described_class.new(member, event).user_has_attendance?).to be(true)
    end

    it 'returns false when user does not have an attendance' do
      expect(described_class.new(member, event).user_has_attendance?).to be(false)
    end

    it 'returns false when user is nil' do
      expect(described_class.new(nil, event).user_has_attendance?).to be(false)
    end
  end

  describe 'Scope' do
    before do
      Attendance.delete_all
      Event.delete_all
    end

    let!(:published_event) do
      e = build_event(status: 'published')
      e.save!
      e
    end
    let!(:draft_event) do
      e = build_event(status: 'draft', creator_user: owner)
      e.save!
      e
    end

    it 'returns only published events for guests' do
      scope = described_class::Scope.new(nil, Event.all).resolve

      expect(scope).to contain_exactly(published_event)
    end

    it 'returns published + own events for a member' do
      member = create_user
      scope = described_class::Scope.new(member, Event.all).resolve

      expect(scope).to include(published_event)
      expect(scope).not_to include(draft_event)
    end

    it 'returns published + own events for organizer' do
      organizer = owner
      scope = described_class::Scope.new(organizer, Event.all).resolve

      expect(scope).to include(published_event, draft_event)
    end

    it 'returns all events for admin' do
      admin = create_user(role: admin_role)
      scope = described_class::Scope.new(admin, Event.all).resolve

      expect(scope).to include(published_event, draft_event)
    end
  end
end
