# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Event::InitiationPolicy do
  include TestDataHelper

  let(:user_role) { ensure_role(code: 'USER', name: 'Utilisateur', level: 10) }
  let(:user) { create_user(role: user_role) }
  let(:initiation) do
    create_event(
      type: 'Event::Initiation',
      status: 'published',
      max_participants: 30,
      allow_non_member_discovery: false
    )
  end

  describe '#attend?' do
    it 'allows signed-in user with membership when initiation is upcoming and has spots' do
      create(:membership, user: user, status: :active, season: '2025-2026')
      policy = described_class.new(user, initiation)
      expect(policy.attend?).to be(true)
    end

    it 'denies when initiation is past' do
      create(:membership, user: user, status: :active, season: '2025-2026')
      past_initiation = create_event(
        type: 'Event::Initiation',
        status: 'published',
        max_participants: 30,
        allow_non_member_discovery: false,
        start_at: 2.days.ago
      )
      policy = described_class.new(user, past_initiation)
      expect(policy.attend?).to be(false)
    end

    it 'denies guests' do
      policy = described_class.new(nil, initiation)
      expect(policy.attend?).to be(false)
    end
  end

  describe '#join_waitlist?' do
    def make_initiation_full(initiation)
      other_user = create_user(role: user_role)
      att = build(:attendance, event: initiation, user: other_user, status: 'registered', is_volunteer: false)
      att.save(validate: false)
      initiation.reload
    end

    it 'denies non-member when initiation is full' do
      full_initiation = create_event(
        type: 'Event::Initiation',
        status: 'published',
        max_participants: 1,
        allow_non_member_discovery: false
      )
      make_initiation_full(full_initiation)
      policy = described_class.new(user, full_initiation)
      expect(policy.join_waitlist?({})).to be(false)
    end

    it 'allows member (adult active membership) when initiation is full' do
      create(:membership, user: user, status: :active, season: '2025-2026', is_child_membership: false)
      full_initiation = create_event(
        type: 'Event::Initiation',
        status: 'published',
        max_participants: 1,
        allow_non_member_discovery: false
      )
      make_initiation_full(full_initiation)
      policy = described_class.new(user, full_initiation)
      expect(policy.join_waitlist?({})).to be(true)
    end

    it 'denies when initiation is not full' do
      create(:membership, user: user, status: :active, season: '2025-2026', is_child_membership: false)
      policy = described_class.new(user, initiation)
      expect(policy.join_waitlist?({})).to be(false)
    end

    it 'allows when signing up for child with active membership' do
      child_membership = create(:membership, :child, :with_health_questionnaire, user: user, season: '2025-2026', status: :active)
      full_initiation = create_event(
        type: 'Event::Initiation',
        status: 'published',
        max_participants: 1,
        allow_non_member_discovery: false
      )
      make_initiation_full(full_initiation)
      policy = described_class.new(user, full_initiation)
      expect(policy.join_waitlist?(child_membership_id: child_membership.id)).to be(true)
    end

    it 'denies when signing up for child with trial membership' do
      child_membership = create(:membership, :child, :trial, :with_health_questionnaire, user: user, season: '2025-2026')
      full_initiation = create_event(
        type: 'Event::Initiation',
        status: 'published',
        max_participants: 1,
        allow_non_member_discovery: false
      )
      make_initiation_full(full_initiation)
      policy = described_class.new(user, full_initiation)
      expect(policy.join_waitlist?(child_membership_id: child_membership.id)).to be(false)
    end

    it 'denies when signing up for child with pending membership' do
      child_membership = create(:membership, :child, :pending, :with_health_questionnaire, user: user, season: '2025-2026')
      full_initiation = create_event(
        type: 'Event::Initiation',
        status: 'published',
        max_participants: 1,
        allow_non_member_discovery: false
      )
      make_initiation_full(full_initiation)
      policy = described_class.new(user, full_initiation)
      expect(policy.join_waitlist?(child_membership_id: child_membership.id)).to be(false)
    end

    it 'denies when signing up for child with invalid child_membership_id' do
      full_initiation = create_event(
        type: 'Event::Initiation',
        status: 'published',
        max_participants: 1,
        allow_non_member_discovery: false
      )
      make_initiation_full(full_initiation)
      policy = described_class.new(user, full_initiation)
      expect(policy.join_waitlist?(child_membership_id: 99999)).to be(false)
    end
  end

  describe 'Scope' do
    it 'includes published and canceled initiations for guest users' do
      published_initiation = create_event(
        type: 'Event::Initiation',
        status: 'published',
        title: 'Publiée',
        max_participants: 30,
        allow_non_member_discovery: false
      )
      canceled_initiation = create_event(
        type: 'Event::Initiation',
        status: 'canceled',
        title: 'Annulée',
        max_participants: 30,
        allow_non_member_discovery: false
      )

      scope = described_class::Scope.new(nil, Event::Initiation.all).resolve

      expect(scope).to include(published_initiation)
      expect(scope).to include(canceled_initiation)
    end

    it 'includes published and canceled initiations for normal users' do
      user = create_user(role: user_role)
      published_initiation = create_event(
        type: 'Event::Initiation',
        status: 'published',
        title: 'Publiée',
        max_participants: 30,
        allow_non_member_discovery: false
      )
      canceled_initiation = create_event(
        type: 'Event::Initiation',
        status: 'canceled',
        title: 'Annulée',
        max_participants: 30,
        allow_non_member_discovery: false
      )

      scope = described_class::Scope.new(user, Event::Initiation.all).resolve

      expect(scope).to include(published_initiation)
      expect(scope).to include(canceled_initiation)
    end
  end
end
