require 'rails_helper'

RSpec.describe Event::Initiation, type: :model do
  include ActiveSupport::Testing::TimeHelpers

  let(:creator) { create_user }

  def next_saturday_at_10_15
    today = Date.today
    days_until_saturday = (6 - today.wday) % 7
    days_until_saturday = 7 if days_until_saturday == 0 && Time.current.hour >= 10
    (today + days_until_saturday.days).beginning_of_day + 10.hours + 15.minutes
  end

  describe 'validations' do
    it 'is valid with default attributes' do
      initiation = build(:event_initiation, creator_user: creator)
      expect(initiation).to be_valid
    end

    # Les validations spécifiques sur saison / jour / heure / lieu ont été
    # simplifiées dans le modèle. On vérifie encore la cohérence métier minimale.
    it 'requires max_participants > 0' do
      initiation = build(:event_initiation, creator_user: creator, max_participants: 0)
      expect(initiation).to be_invalid
      expect(initiation.errors[:max_participants]).to be_present
    end
  end

  describe '#full?' do
    it 'returns true when no places available' do
      initiation = create(:event_initiation, creator_user: creator, max_participants: 2)
      # créer des participants adhérents pour respecter les validations Attendance
      2.times do
        participant = create_user
        create(:membership, user: participant, status: :active, season: '2025-2026')
        attendance = build(:attendance, event: initiation, user: participant, is_volunteer: false, status: 'registered')
        attendance.save!(validate: false)
      end
      expect(initiation.full?).to be true
    end

    it 'returns false when places available' do
      initiation = create(:event_initiation, creator_user: creator, max_participants: 30)
      10.times do
        participant = create_user
        create(:membership, user: participant, status: :active, season: '2025-2026')
        attendance = build(:attendance, event: initiation, user: participant, is_volunteer: false, status: 'registered')
        attendance.save!(validate: false)
      end
      expect(initiation.full?).to be false
    end

    it 'does not count volunteers' do
      initiation = create(:event_initiation, creator_user: creator, max_participants: 1)
      volunteer = create_user
      attendance = build(:attendance, event: initiation, user: volunteer, is_volunteer: true, status: 'registered')
      attendance.save!(validate: false)
      participant = create_user
      create(:membership, user: participant, status: :active, season: '2025-2026')
      attendance = build(:attendance, event: initiation, user: participant, is_volunteer: false, status: 'registered')
      attendance.save!(validate: false)
      expect(initiation.full?).to be true
    end
  end

  describe '#available_places' do
    it 'calculates correctly' do
      initiation = create(:event_initiation, creator_user: creator, max_participants: 30)
      5.times do
        participant = create_user
        create(:membership, user: participant, status: :active, season: '2025-2026')
        attendance = build(:attendance, event: initiation, user: participant, is_volunteer: false, status: 'registered')
        attendance.save!(validate: false)
      end
      expect(initiation.available_places).to eq(25)
    end

    it 'does not count volunteers' do
      initiation = create(:event_initiation, creator_user: creator, max_participants: 10)
      3.times do
        volunteer = create_user
        attendance = build(:attendance, event: initiation, user: volunteer, is_volunteer: true, status: 'registered')
        attendance.save!(validate: false)
      end
      5.times do
        participant = create_user
        create(:membership, user: participant, status: :active, season: '2025-2026')
        attendance = build(:attendance, event: initiation, user: participant, is_volunteer: false, status: 'registered')
        attendance.save!(validate: false)
      end
      expect(initiation.available_places).to eq(5) # 10 - 5 = 5
    end
  end

  describe '#participants_count' do
    it 'counts only non-volunteer attendances' do
      initiation = create(:event_initiation, creator_user: creator)
      3.times do
        participant = create_user
        create(:membership, user: participant, status: :active, season: '2025-2026')
        attendance = build(:attendance, event: initiation, user: participant, is_volunteer: false, status: 'registered')
        attendance.save!(validate: false)
      end
      2.times do
        volunteer = create_user
        attendance = build(:attendance, event: initiation, user: volunteer, is_volunteer: true, status: 'registered')
        attendance.save!(validate: false)
      end
      expect(initiation.participants_count).to eq(3)
    end

    it 'counts only registered and present status' do
      initiation = create(:event_initiation, creator_user: creator)
      %w[registered present canceled].each do |status|
        participant = create_user
        create(:membership, user: participant, status: :active, season: '2025-2026')
        attendance = build(:attendance, event: initiation, user: participant, is_volunteer: false, status: status)
        attendance.save!(validate: false)
      end
      expect(initiation.participants_count).to eq(2)
    end
  end

  describe '#volunteers_count' do
    it 'counts only volunteer attendances' do
      initiation = create(:event_initiation, creator_user: creator)
      3.times do
        volunteer = create_user
        attendance = build(:attendance, event: initiation, user: volunteer, is_volunteer: true, status: 'registered')
        attendance.save!(validate: false)
      end
      2.times do
        participant = create_user
        create(:membership, user: participant, status: :active, season: '2025-2026')
        attendance = build(:attendance, event: initiation, user: participant, is_volunteer: false, status: 'registered')
        attendance.save!(validate: false)
      end
      expect(initiation.volunteers_count).to eq(3)
    end
  end

  describe '#unlimited?' do
    it 'always returns false for initiations' do
      initiation = create(:event_initiation, creator_user: creator)
      expect(initiation.unlimited?).to be false
    end
  end

  describe '#available_non_member_places' do
    context 'when allow_non_member_discovery is false' do
      it 'returns 0' do
        initiation = create(:event_initiation,
          creator_user: creator,
          allow_non_member_discovery: false,
          non_member_discovery_slots: nil
        )
        expect(initiation.available_non_member_places).to eq(0)
      end
    end

    context 'when allow_non_member_discovery is true' do
      context 'when non_member_discovery_slots is nil (illimité)' do
        it 'returns Float::INFINITY' do
          initiation = create(:event_initiation,
            creator_user: creator,
            allow_non_member_discovery: true,
            non_member_discovery_slots: nil,
            max_participants: 30
          )
          expect(initiation.available_non_member_places).to eq(Float::INFINITY)
        end

        it 'returns Float::INFINITY even with non-member participants' do
          initiation = create(:event_initiation,
            creator_user: creator,
            allow_non_member_discovery: true,
            non_member_discovery_slots: nil,
            max_participants: 30
          )
          # Créer 10 participants non-adhérents
          10.times do
            user = create_user
            attendance = build(:attendance, event: initiation, user: user, is_volunteer: false, status: 'registered')
            attendance.save!(validate: false)
          end
          expect(initiation.available_non_member_places).to eq(Float::INFINITY)
        end
      end

      context 'when non_member_discovery_slots is defined (limité)' do
        it 'calculates available places correctly' do
          initiation = create(:event_initiation,
            creator_user: creator,
            allow_non_member_discovery: true,
            non_member_discovery_slots: 5,
            max_participants: 30
          )
          expect(initiation.available_non_member_places).to eq(5)
        end

        it 'decreases when non-member participants register' do
          initiation = create(:event_initiation,
            creator_user: creator,
            allow_non_member_discovery: true,
            non_member_discovery_slots: 5,
            max_participants: 30
          )
          # Créer 2 participants non-adhérents
          2.times do
            user = create_user
            attendance = build(:attendance, event: initiation, user: user, is_volunteer: false, status: 'registered')
            attendance.save!(validate: false)
          end
          expect(initiation.available_non_member_places).to eq(3) # 5 - 2 = 3
        end

        it 'returns 0 when limit is reached' do
          initiation = create(:event_initiation,
            creator_user: creator,
            allow_non_member_discovery: true,
            non_member_discovery_slots: 5,
            max_participants: 30
          )
          # Créer 5 participants non-adhérents
          5.times do
            user = create_user
            attendance = build(:attendance, event: initiation, user: user, is_volunteer: false, status: 'registered')
            attendance.save!(validate: false)
          end
          expect(initiation.available_non_member_places).to eq(0)
        end
      end
    end
  end

  describe '#full_for_non_members?' do
    context 'when allow_non_member_discovery is false' do
      it 'returns false' do
        initiation = create(:event_initiation,
          creator_user: creator,
          allow_non_member_discovery: false
        )
        expect(initiation.full_for_non_members?).to be false
      end
    end

    context 'when allow_non_member_discovery is true' do
      context 'when non_member_discovery_slots is nil (illimité)' do
        it 'returns false (never full)' do
          initiation = create(:event_initiation,
            creator_user: creator,
            allow_non_member_discovery: true,
            non_member_discovery_slots: nil,
            max_participants: 30
          )
          # Créer 100 participants non-adhérents (dépasse max_participants)
          100.times do
            user = create_user
            attendance = build(:attendance, event: initiation, user: user, is_volunteer: false, status: 'registered')
            attendance.save!(validate: false)
          end
          expect(initiation.full_for_non_members?).to be false
        end
      end

      context 'when non_member_discovery_slots is defined (limité)' do
        it 'returns false when places available' do
          initiation = create(:event_initiation,
            creator_user: creator,
            allow_non_member_discovery: true,
            non_member_discovery_slots: 5,
            max_participants: 30
          )
          expect(initiation.full_for_non_members?).to be false
        end

        it 'returns true when limit is reached' do
          initiation = create(:event_initiation,
            creator_user: creator,
            allow_non_member_discovery: true,
            non_member_discovery_slots: 5,
            max_participants: 30
          )
          # Créer 5 participants non-adhérents
          5.times do
            user = create_user
            attendance = build(:attendance, event: initiation, user: user, is_volunteer: false, status: 'registered')
            attendance.save!(validate: false)
          end
          expect(initiation.full_for_non_members?).to be true
        end
      end
    end
  end

  describe '#full? with allow_non_member_discovery' do
    context 'when non_member_discovery_slots is nil (illimité)' do
      it 'returns false if member places available, even if many non-members' do
        initiation = create(:event_initiation,
          creator_user: creator,
          allow_non_member_discovery: true,
          non_member_discovery_slots: nil,
          max_participants: 30
        )
        # Créer 1 participant adhérent
        member = create_user
        create(:membership, user: member, status: :active, season: '2025-2026')
        attendance = build(:attendance, event: initiation, user: member, is_volunteer: false, status: 'registered')
        attendance.save!(validate: false)
        # Créer 50 participants non-adhérents (dépasse max_participants mais illimité pour non-members)
        50.times do
          user = create_user
          attendance = build(:attendance, event: initiation, user: user, is_volunteer: false, status: 'registered')
          attendance.save!(validate: false)
        end
        expect(initiation.full?).to be false # Places adhérents disponibles
      end
    end

    context 'when non_member_discovery_slots is defined (limité)' do
      it 'returns true only when both member and non-member places are full' do
        initiation = create(:event_initiation,
          creator_user: creator,
          allow_non_member_discovery: true,
          non_member_discovery_slots: 5,
          max_participants: 30
        )
        # Remplir les places adhérents (30 - 5 = 25 places)
        25.times do
          member = create_user
          create(:membership, user: member, status: :active, season: '2025-2026')
          attendance = build(:attendance, event: initiation, user: member, is_volunteer: false, status: 'registered')
          attendance.save!(validate: false)
        end
        # Remplir les places non-adhérents (5 places)
        5.times do
          user = create_user
          attendance = build(:attendance, event: initiation, user: user, is_volunteer: false, status: 'registered')
          attendance.save!(validate: false)
        end
        expect(initiation.full?).to be true
      end
    end
  end

  describe 'scopes' do
    describe '.by_season' do
      it 'filters by season' do
        initiation_2025 = create(:event_initiation, creator_user: creator, season: '2025-2026')
        initiation_2026 = create(:event_initiation, creator_user: creator, season: '2026-2027')

        expect(Event::Initiation.by_season('2025-2026')).to contain_exactly(initiation_2025)
      end
    end

    describe '.upcoming_initiations' do
      it 'returns future and ongoing initiations, excluding finished ones' do
        future = create(:event_initiation, creator_user: creator, start_at: 1.week.from_now)
        ongoing = create(:event_initiation, creator_user: creator, start_at: 30.minutes.ago, duration_min: 120)
        past = create(:event_initiation, creator_user: creator, start_at: 2.hours.ago, duration_min: 60)

        expect(Event::Initiation.upcoming_initiations).to include(future, ongoing)
        expect(Event::Initiation.upcoming_initiations).not_to include(past)
      end
    end
  end

  it 'cannot enable payment_required via validation' do
    initiation = build(:event_initiation, creator_user: creator, payment_required: true)
    expect(initiation).to be_invalid
    expect(initiation.errors[:payment_required]).to be_present
  end

  it 'does not expose payment_required checkbox in admin form' do
    form_path = Rails.root.join('app/views/initiations/_form.html.erb')
    expect(File.read(form_path)).not_to include('payment_required')
  end
end
