require 'rails_helper'

RSpec.describe Event, type: :model do
  include ActiveSupport::Testing::TimeHelpers

  around do |example|
    travel_to(Time.zone.local(2025, 1, 1, 12)) { example.run }
  end

  let(:creator) { create_user }
  let(:user_role) { ensure_role(code: 'USER', name: 'Utilisateur', level: 10) }

  describe 'validations' do
    it 'is valid with default attributes' do
      event = build_event(creator_user: creator, route: create_route)
      expect(event).to be_valid
    end

    it 'requires mandatory attributes' do
      event = Event.new
      expect(event).to be_invalid
      expect(event.errors[:creator_user]).to be_present
      expect(event.errors[:title]).to be_present
      expect(event.errors[:description]).to be_present
      expect(event.errors[:start_at]).to be_present
      expect(event.errors[:duration_min]).to be_present
      expect(event.errors[:location_text]).to be_present
    end

    it 'enforces duration to be a positive multiple of 5' do
      event = build_event(creator_user: creator, duration_min: 42)
      expect(event).to be_invalid
      expect(event.errors[:duration_min]).to include('must be a multiple of 5')
    end

    it 'requires non-negative pricing' do
      event = build_event(creator_user: creator, price_cents: -10)
      expect(event).to be_invalid
      expect(event.errors[:price_cents]).to be_present
    end

    it 'requires max_participants to be non-negative' do
      event = build_event(creator_user: creator, max_participants: -1)
      expect(event).to be_invalid
      expect(event.errors[:max_participants]).to be_present
    end

    it 'allows max_participants to be 0 (unlimited)' do
      event = build_event(creator_user: creator, max_participants: 0)
      expect(event).to be_valid
      expect(event.unlimited?).to be true
    end
  end

  describe 'scopes' do
    before do
      Attendance.delete_all
      Event.delete_all
    end
    it 'returns events with future dates for upcoming scope' do
      future_event = create_event(creator_user: creator, start_at: 2.days.from_now)
      create_event(creator_user: creator, start_at: 2.days.ago)

      expect(Event.upcoming).to contain_exactly(future_event)
    end

    it 'returns past events for past scope' do
      past_event = create_event(creator_user: creator, start_at: 3.days.ago)
      create_event(creator_user: creator, start_at: 2.days.from_now)

      expect(Event.past).to contain_exactly(past_event)
    end

    it 'returns published events for published scope' do
      published_event = create_event(creator_user: creator, status: 'published')
      create_event(creator_user: creator, status: 'draft')

      expect(Event.published).to contain_exactly(published_event)
    end
  end

  describe '#unlimited?' do
    it 'returns true when max_participants is 0' do
      event = create_event(creator_user: creator, max_participants: 0)
      expect(event.unlimited?).to be true
    end

    it 'returns false when max_participants is greater than 0' do
      event = create_event(creator_user: creator, max_participants: 10)
      expect(event.unlimited?).to be false
    end
  end

  describe '#full?' do
    it 'returns false when unlimited (max_participants = 0)' do
      event = create_event(creator_user: creator, max_participants: 0)
      expect(event.full?).to be false
    end

    it 'returns false when not at capacity' do
      event = create_event(creator_user: creator, max_participants: 10)
      user = create_user(role: user_role)
      create(:membership, user: user, status: :active, season: '2025-2026')
      create_attendance(event: event, user: user)
      expect(event.full?).to be false
    end

    it 'returns true when at capacity' do
      event = create_event(creator_user: creator, max_participants: 2)
      user1 = create_user(role: user_role)
      user2 = create_user(role: user_role)
      create(:membership, user: user1, status: :active, season: '2025-2026')
      create(:membership, user: user2, status: :active, season: '2025-2026')
      create_attendance(event: event, user: user1)
      create_attendance(event: event, user: user2)
      event.reload
      expect(event.full?).to be true
    end

    it 'does not count canceled attendances' do
      event = create_event(creator_user: creator, max_participants: 1)
      user1 = create_user(role: user_role)
      user2 = create_user(role: user_role)
      create(:membership, user: user1, status: :active, season: '2025-2026')
      create(:membership, user: user2, status: :active, season: '2025-2026')
      # Create canceled attendance first (should not count toward limit)
      canceled_attendance = create_attendance(event: event, user: user1, status: 'canceled')
      # Then create active attendance (should work because only canceled exists)
      active_attendance = create_attendance(event: event, user: user2, status: 'registered')
      event.reload
      expect(event.full?).to be true # 1 active attendance, event is full
      # But if we cancel the active one, event should not be full anymore
      active_attendance.update(status: 'canceled')
      event.reload
      expect(event.full?).to be false # Only canceled attendances remain
    end
  end

  describe '#remaining_spots' do
    it 'returns nil when unlimited' do
      event = create_event(creator_user: creator, max_participants: 0)
      expect(event.remaining_spots).to be_nil
    end

    it 'returns correct number of remaining spots' do
      event = create_event(creator_user: creator, max_participants: 10)
      user = create_user(role: user_role)
      create(:membership, user: user, status: :active, season: '2025-2026')
      create_attendance(event: event, user: user)
      event.reload
      expect(event.remaining_spots).to eq(9)
    end

    it 'returns 0 when full' do
      event = create_event(creator_user: creator, max_participants: 2)
      user1 = create_user(role: user_role)
      user2 = create_user(role: user_role)
      create(:membership, user: user1, status: :active, season: '2025-2026')
      create(:membership, user: user2, status: :active, season: '2025-2026')
      create_attendance(event: event, user: user1)
      create_attendance(event: event, user: user2)
      event.reload
      expect(event.remaining_spots).to eq(0)
    end

    it 'does not count canceled attendances' do
      event = create_event(creator_user: creator, max_participants: 2)
      user1 = create_user(role: user_role)
      user2 = create_user(role: user_role)
      create(:membership, user: user1, status: :active, season: '2025-2026')
      create(:membership, user: user2, status: :active, season: '2025-2026')
      create_attendance(event: event, user: user1, status: 'registered')
      create_attendance(event: event, user: user2, status: 'canceled')
      event.reload
      expect(event.remaining_spots).to eq(1) # Only 1 active attendance
    end
  end

  describe '#has_available_spots?' do
    it 'returns true when unlimited' do
      event = create_event(creator_user: creator, max_participants: 0)
      expect(event.has_available_spots?).to be true
    end

    it 'returns true when not at capacity' do
      event = create_event(creator_user: creator, max_participants: 10)
      user = create_user(role: user_role)
      create(:membership, user: user, status: :active, season: '2025-2026')
      create_attendance(event: event, user: user)
      event.reload
      expect(event.has_available_spots?).to be true
    end

    it 'returns false when at capacity' do
      event = create_event(creator_user: creator, max_participants: 2)
      user1 = create_user(role: user_role)
      user2 = create_user(role: user_role)
      create(:membership, user: user1, status: :active, season: '2025-2026')
      create(:membership, user: user2, status: :active, season: '2025-2026')
      create_attendance(event: event, user: user1)
      create_attendance(event: event, user: user2)
      event.reload
      expect(event.has_available_spots?).to be false
    end
  end
end
