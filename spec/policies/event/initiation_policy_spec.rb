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
