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

    it 'returns French messages for short description (no missing translation)' do
      event = build_event(creator_user: creator, route: create_route, description: "trop court")
      expect(event).to be_invalid
      message = event.errors.full_messages.find { |m| m.include?("Description") }
      expect(message).to include("20 caractères")
      expect(message).not_to include("Translation missing")
    end

    it 'enforces duration to be a positive multiple of 5' do
      event = build_event(creator_user: creator, duration_min: 42)
      expect(event).to be_invalid
      expect(event.errors[:duration_min]).to include('doit être un multiple de 5')
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

    it 'keeps started-but-not-finished events in upcoming scope' do
      ongoing_event = create_event(creator_user: creator, start_at: 30.minutes.ago, duration_min: 120)
      finished_event = create_event(creator_user: creator, start_at: 3.hours.ago, duration_min: 60)

      expect(Event.upcoming).to include(ongoing_event)
      expect(Event.upcoming).not_to include(finished_event)
      expect(Event.past).to include(finished_event)
      expect(Event.past).not_to include(ongoing_event)
    end

    it 'returns published events for published scope' do
      published_event = create_event(creator_user: creator, status: 'published')
      create_event(creator_user: creator, status: 'draft')

      expect(Event.published).to contain_exactly(published_event)
    end
  end

  describe '#started?, #past?, #finished?' do
    it 'marks an ongoing event as started but not past' do
      event = create_event(creator_user: creator, start_at: 30.minutes.ago, duration_min: 120)

      expect(event.started?).to be(true)
      expect(event.ongoing?).to be(true)
      expect(event.finished?).to be(false)
      expect(event.past?).to be(false)
    end

    it 'marks a finished event as past' do
      event = create_event(creator_user: creator, start_at: 2.hours.ago, duration_min: 60)

      expect(event.started?).to be(true)
      expect(event.finished?).to be(true)
      expect(event.past?).to be(true)
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

  describe '#requires_online_payment?' do
    it 'returns true when payment_required is true on a rando' do
      event = build_event(creator_user: creator, payment_required: true, price_cents: 500)
      expect(event.requires_online_payment?).to be true
    end

    it 'returns false when payment_required is false even if price_cents is positive' do
      event = build_event(creator_user: creator, payment_required: false, price_cents: 500)
      expect(event.requires_online_payment?).to be false
    end

    it 'returns false for Initiation even if payment_required is true' do
      initiation = build_event(type: 'Event::Initiation', creator_user: creator, payment_required: true, price_cents: 0, max_participants: 10)
      expect(initiation.requires_online_payment?).to be false
    end
  end

  describe 'payment_required validation' do
    it 'rejects payment_required on Initiation' do
      initiation = build_event(type: 'Event::Initiation', creator_user: creator, payment_required: true, max_participants: 10)
      expect(initiation).to be_invalid
      expect(initiation.errors[:payment_required]).to be_present
    end
  end

  describe '#full? when payment_required' do
    it 'counts pending attendances with payment_expires_at toward capacity' do
      event = create_event(creator_user: creator, max_participants: 1, payment_required: true, price_cents: 500)
      user = create_user(role: user_role)
      create(:attendance, event: event, user: user, status: :pending, payment_expires_at: 10.minutes.from_now)
      event.reload
      expect(event.full?).to be true
    end

    it 'does not count payment-pending attendances when payment_required is false' do
      event = create_event(creator_user: creator, max_participants: 1, payment_required: false)
      user = create_user(role: user_role)
      create(:attendance, event: event, user: user, status: :pending, payment_expires_at: 10.minutes.from_now)
      event.reload
      expect(event.full?).to be false
    end
  end

  describe '#has_available_spots? when payment_required' do
    it 'returns false when pending payment holds fill capacity' do
      event = create_event(creator_user: creator, max_participants: 1, payment_required: true, price_cents: 500)
      user = create_user(role: user_role)
      create(:attendance, event: event, user: user, status: :pending, payment_expires_at: 10.minutes.from_now)
      event.reload
      expect(event.has_available_spots?).to be false
    end
  end

  describe '#loop_distance_km_values' do
    let(:route1) { create_route(name: 'Boucle principale') }
    let(:route2) { create_route(name: 'Boucle secondaire', distance_km: 15.0) }

    it 'returns a single distance for one loop' do
      event = create_event(creator_user: creator, route: route1, distance_km: 10.0, loops_count: 1)

      expect(event.loop_distance_km_values).to eq([ 10.0 ])
    end

    it 'returns each loop distance without summing when event_loop_routes exist' do
      event = create_event(
        creator_user: creator,
        route: route1,
        loops_count: 3,
        distance_km: 10.0
      )
      event.event_loop_routes.create!(loop_number: 1, route: route1, distance_km: 10.0)
      event.event_loop_routes.create!(loop_number: 2, route: route2, distance_km: 15.0)
      event.event_loop_routes.create!(loop_number: 3, route: route1, distance_km: 12.0)

      expect(event.loop_distance_km_values).to eq([ 10.0, 15.0, 12.0 ])
      expect(event.total_distance_km).to eq(37.0)
    end

    it 'repeats distance_km for each loop in legacy multi-loop mode' do
      event = create_event(
        creator_user: creator,
        route: route1,
        loops_count: 2,
        distance_km: 5.0
      )

      expect(event.loop_distance_km_values).to eq([ 5.0, 5.0 ])
    end
  end
  describe 'audit trail' do
    let!(:creator) { create_user }

    it 'creates an audit log on creation' do
      expect {
        create_event(creator_user: creator, title: "Test Event", description: "A test event description", start_at: 1.day.from_now, duration_min: 60, location_text: "Test Location", price_cents: 0, currency: "EUR", max_participants: 20, level: "beginner", distance_km: 10.0)
      }.to change { AuditLog.count }.by(1)

      log = AuditLog.last
      expect(log.actor_user).to eq(creator)
      expect(log.action).to eq('created')
      expect(log.target_type).to eq('Event')
      expect(log.metadata['title']).to eq('Test Event')
      expect(log.metadata['status']).to eq('draft')
    end

    it 'updates audit log on update' do
      event = create_event(creator_user: creator, title: "Test Event", description: "A test event description", start_at: 1.day.from_now, duration_min: 60, location_text: "Test Location", price_cents: 0, currency: "EUR", max_participants: 20, level: "beginner", distance_km: 10.0)
      expect {
        event.update!(title: 'Updated Test Event')
      }.to change { AuditLog.count }.by(1)

      log = AuditLog.last
      expect(log.action).to eq('updated')
      expect(log.metadata).to have_key('changes')
      changes = log.metadata['changes']
      expect(changes).to be_a(Hash)
      expect(changes['title']).to eq([ 'Test Event', 'Updated Test Event' ])
    end

    it 'creates audit log on destruction' do
      event = create_event(creator_user: creator, title: "Test Event", description: "A test event description", start_at: 1.day.from_now, duration_min: 60, location_text: "Test Location", price_cents: 0, currency: "EUR", max_participants: 20, level: "beginner", distance_km: 10.0)
      expect {
        event.destroy
      }.to change { AuditLog.count }.by(1)

      log = AuditLog.last
      expect(log.action).to eq('destroyed')
      expect(log.metadata['title']).to eq('Test Event')
    end
  end
  describe 'audit trail' do
    let!(:creator) { create_user }

    it 'creates an audit log on creation' do
      expect {
        create_event(creator_user: creator, title: "Test Event", description: "A test event description", start_at: 1.day.from_now, duration_min: 60, location_text: "Test Location", price_cents: 0, currency: "EUR", max_participants: 20, level: "beginner", distance_km: 10.0)
      }.to change { AuditLog.count }.by(1)

      log = AuditLog.last
      expect(log.actor_user).to eq(creator)
      expect(log.action).to eq('created')
      expect(log.target_type).to eq('Event')
      expect(log.metadata['title']).to eq('Test Event')
      expect(log.metadata['status']).to eq('draft')
    end

    it 'updates audit log on update' do
      event = create_event(creator_user: creator, title: "Test Event", description: "A test event description", start_at: 1.day.from_now, duration_min: 60, location_text: "Test Location", price_cents: 0, currency: "EUR", max_participants: 20, level: "beginner", distance_km: 10.0)
      expect {
        event.update!(title: 'Updated Test Event')
      }.to change { AuditLog.count }.by(1)

      log = AuditLog.last
      expect(log.action).to eq('updated')
      expect(log.metadata).to have_key('changes')
      changes = log.metadata['changes']
      expect(changes).to be_a(Hash)
      expect(changes['title']).to eq([ 'Test Event', 'Updated Test Event' ])
    end

    it 'creates audit log on destruction' do
      event = create_event(creator_user: creator, title: "Test Event", description: "A test event description", start_at: 1.day.from_now, duration_min: 60, location_text: "Test Location", price_cents: 0, currency: "EUR", max_participants: 20, level: "beginner", distance_km: 10.0)
      expect {
        event.destroy
      }.to change { AuditLog.count }.by(1)

      log = AuditLog.last
      expect(log.action).to eq('destroyed')
      expect(log.metadata['title']).to eq('Test Event')
    end
  end
end
