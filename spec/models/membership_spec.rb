require 'rails_helper'

RSpec.describe Membership, type: :model do
  include ActiveSupport::Testing::TimeHelpers

  describe 'season and activity over time' do
    it 'considers memberships inactive after season end via active_now scope' do
      # Créer un utilisateur valide avec un rôle, puis une adhésion active
      role = Role.find_or_create_by!(code: 'USER') { |r| r.name = 'User'; r.level = 10 }
      user = User.create!(
        first_name: 'Season',
        last_name: 'Tester',
        email: 'season.tester@example.com',
        password: 'password12345',
        skill_level: 'intermediate',
        role: role
      )

      membership = Membership.create!(
        user: user,
        status: :active,
        category: :standard,
        start_date: Date.new(2025, 9, 1),
        end_date: Date.new(2026, 8, 31),
        amount_cents: 1000,
        currency: 'EUR',
        season: '2025-2026',
        is_child_membership: false,
        rgpd_consent: true,
        legal_notices_accepted: true
      )

      inside_season_date = membership.start_date + 30.days
      after_season_date  = membership.end_date + 1.day

      travel_to inside_season_date do
        expect(Membership.active_now).to include(membership)
        expect(membership.active?).to be(true)
      end

      # Après la fin de saison, l'adhésion ne doit plus être considérée "active maintenant"
      travel_to after_season_date do
        expect(Membership.active_now).not_to include(membership)
        expect(membership.active?).to be(false)
      end
    end
  end

  describe 'sale season (opens next season from 1 August)' do
    it 'uses running season before 1 August' do
      travel_to Date.new(2026, 6, 5) do
        expect(Membership.sale_season_name).to eq('2025-2026')
        expect(Membership.current_season_name).to eq('2025-2026')
      end

      travel_to Date.new(2026, 7, 31) do
        expect(Membership.sale_season_name).to eq('2025-2026')
        expect(Membership.current_season_name).to eq('2025-2026')
      end
    end

    it 'opens next season from 1 August until end of August' do
      travel_to Date.new(2026, 8, 1) do
        expect(Membership.sale_season_name).to eq('2026-2027')
        expect(Membership.current_season_name).to eq('2025-2026')
      end

      travel_to Date.new(2026, 8, 14) do
        expect(Membership.sale_season_name).to eq('2026-2027')
        expect(Membership.current_season_name).to eq('2025-2026')
      end

      travel_to Date.new(2026, 8, 20) do
        expect(Membership.sale_season_name).to eq('2026-2027')
        expect(Membership.current_season_name).to eq('2025-2026')
      end

      travel_to Date.new(2026, 8, 31) do
        expect(Membership.sale_season_name).to eq('2026-2027')
        expect(Membership.current_season_name).to eq('2025-2026')
      end
    end

    describe '#renewable_now?' do
      it 'is true for expired memberships' do
        membership = create(:membership, :expired, end_date: Date.new(2026, 7, 1), start_date: Date.new(2025, 9, 1), season: '2025-2026')
        travel_to Date.new(2026, 8, 2) do
          expect(membership.renewable_now?).to be(true)
        end
      end

      it 'is true for active memberships within 30 days of end_date' do
        membership = create(:membership, status: :active, end_date: Date.new(2026, 8, 31), start_date: Date.new(2025, 9, 1), season: '2025-2026')
        travel_to Date.new(2026, 8, 2) do
          expect(membership.renewable_now?).to be(true)
        end
      end

      it 'is false for active memberships more than 30 days from end_date' do
        membership = create(:membership, status: :active, end_date: Date.new(2026, 8, 31), start_date: Date.new(2025, 9, 1), season: '2025-2026')
        travel_to Date.new(2026, 6, 1) do
          expect(membership.renewable_now?).to be(false)
        end
      end

      it 'is false when a sale-season membership already exists (already renewed)' do
        user = create(:user)
        old = create(:membership, user: user, status: :active, end_date: Date.new(2026, 8, 31), start_date: Date.new(2025, 9, 1), season: '2025-2026')
        create(:membership, user: user, status: :active, end_date: Date.new(2027, 8, 31), start_date: Date.new(2026, 9, 1), season: '2026-2027')
        travel_to Date.new(2026, 8, 2) do
          expect(old.renewable_now?).to be(false)
        end
      end

      it 'is false for a child when a sale-season child membership already exists' do
        user = create(:user)
        old = create(:membership, :child, user: user, status: :active,
                     end_date: Date.new(2026, 8, 31), start_date: Date.new(2025, 9, 1), season: '2025-2026',
                     child_first_name: 'Emma', child_last_name: 'Test', child_date_of_birth: Date.new(2018, 1, 1))
        create(:membership, :child, user: user, status: :pending,
               end_date: Date.new(2027, 8, 31), start_date: Date.new(2026, 9, 1), season: '2026-2027',
               child_first_name: 'Emma', child_last_name: 'Test', child_date_of_birth: Date.new(2018, 1, 1))
        travel_to Date.new(2026, 8, 2) do
          expect(old.renewable_now?).to be(false)
        end
      end
    end

    it 'uses new running season from 1 September' do
      travel_to Date.new(2026, 9, 1) do
        expect(Membership.sale_season_name).to eq('2026-2027')
        expect(Membership.current_season_name).to eq('2026-2027')
      end

      travel_to Date.new(2026, 9, 5) do
        expect(Membership.sale_season_name).to eq('2026-2027')
        expect(Membership.current_season_name).to eq('2026-2027')
      end
    end

    it 'returns sale season date boundaries' do
      travel_to Date.new(2026, 6, 5) do
        expect(Membership.sale_season_dates).to eq([ Date.new(2025, 9, 1), Date.new(2026, 8, 31) ])
      end

      travel_to Date.new(2026, 8, 20) do
        expect(Membership.sale_season_dates).to eq([ Date.new(2026, 9, 1), Date.new(2027, 8, 31) ])
      end
    end

    describe '#sale_season_aligned?' do
      let(:role) { Role.find_or_create_by!(code: 'USER') { |r| r.name = 'User'; r.level = 10 } }
      let(:user) do
        User.create!(
          first_name: 'Align',
          last_name: 'Test',
          email: 'align.test@example.com',
          password: 'password12345',
          skill_level: 'intermediate',
          role: role
        )
      end

      it 'is true when season and dates match sale season' do
        travel_to Date.new(2026, 6, 5) do
          membership = Membership.create!(
            user: user,
            status: :pending,
            category: :standard,
            start_date: Date.new(2025, 9, 1),
            end_date: Date.new(2026, 8, 31),
            amount_cents: 1000,
            currency: 'EUR',
            season: '2025-2026',
            is_child_membership: false,
            rgpd_consent: true,
            legal_notices_accepted: true
          )

          expect(membership.sale_season_aligned?).to be(true)
        end
      end

      it 'is false when season is ahead of sale window' do
        travel_to Date.new(2026, 6, 5) do
          membership = Membership.create!(
            user: user,
            status: :pending,
            category: :standard,
            start_date: Date.new(2026, 9, 1),
            end_date: Date.new(2027, 8, 31),
            amount_cents: 1000,
            currency: 'EUR',
            season: '2026-2027',
            is_child_membership: false,
            rgpd_consent: true,
            legal_notices_accepted: true
          )

          expect(membership.sale_season_aligned?).to be(false)
        end
      end
    end

    it 'align_to_sale_season! fixes pending membership on wrong season' do
      travel_to Date.new(2026, 6, 5) do
        role = Role.find_or_create_by!(code: 'USER') { |r| r.name = 'User'; r.level = 10 }
        user = User.create!(
          first_name: 'Parent',
          last_name: 'Test',
          email: 'parent.season@example.com',
          password: 'password12345',
          skill_level: 'intermediate',
          role: role
        )
        membership = Membership.create!(
          user: user,
          status: :pending,
          category: :standard,
          start_date: Date.new(2026, 9, 1),
          end_date: Date.new(2027, 8, 31),
          amount_cents: 1000,
          currency: 'EUR',
          season: '2026-2027',
          is_child_membership: true,
          child_first_name: 'Max',
          child_last_name: 'Test',
          child_date_of_birth: Date.new(2017, 6, 4),
          rgpd_consent: true,
          legal_notices_accepted: true,
          parent_authorization: true
        )

        membership.align_to_sale_season!

        expect(membership.reload.season).to eq('2025-2026')
        expect(membership.start_date).to eq(Date.new(2025, 9, 1))
        expect(membership.end_date).to eq(Date.new(2026, 8, 31))
      end
    end

    it 'align_to_sale_season! is a no-op when already aligned' do
      travel_to Date.new(2026, 6, 5) do
        membership = create(
          :membership,
          :pending,
          user: create_user,
          season: '2025-2026',
          start_date: Date.new(2025, 9, 1),
          end_date: Date.new(2026, 8, 31)
        )

        expect {
          membership.align_to_sale_season!
        }.not_to change {
          membership.reload.attributes.slice('season', 'start_date', 'end_date')
        }
      end
    end

    it 'align_to_sale_season! fixes trial membership on wrong season' do
      travel_to Date.new(2026, 6, 5) do
        membership = create(
          :membership,
          :child,
          :trial,
          user: create_user,
          season: '2026-2027',
          start_date: Date.new(2026, 9, 1),
          end_date: Date.new(2027, 8, 31)
        )

        membership.align_to_sale_season!

        expect(membership.reload.season).to eq('2025-2026')
      end
    end

    it 'align_to_sale_season! does not change active memberships' do
      travel_to Date.new(2026, 6, 5) do
        membership = create(
          :membership,
          user: create_user,
          status: :active,
          season: '2026-2027',
          start_date: Date.new(2026, 9, 1),
          end_date: Date.new(2027, 8, 31)
        )

        membership.align_to_sale_season!

        expect(membership.reload.season).to eq('2026-2027')
      end
    end

    it 'align_to_sale_season! promotes to next season during August sale window' do
      travel_to Date.new(2026, 8, 20) do
        membership = create(
          :membership,
          :pending,
          user: create_user,
          season: '2025-2026',
          start_date: Date.new(2025, 9, 1),
          end_date: Date.new(2026, 8, 31)
        )

        membership.align_to_sale_season!

        expect(membership.reload.season).to eq('2026-2027')
        expect(membership.start_date).to eq(Date.new(2026, 9, 1))
        expect(membership.end_date).to eq(Date.new(2027, 8, 31))
      end
    end
  end

  describe 'audit trail' do
    let(:role) { Role.find_or_create_by!(code: 'USER') { |r| r.name = 'User'; r.level = 10 } }
    let(:user) do
      User.create!(
        first_name: 'Test',
        last_name: 'User',
        email: 'test@example.com',
        password: 'password12345',
        skill_level: 'beginner',
        role: role
      )
    end

    it 'creates an audit log on creation' do
      membership = nil
      expect {
        membership = Membership.create!(
          user: user,
          status: :active,
          category: :standard,
          start_date: Date.new(2025, 9, 1),
          end_date: Date.new(2026, 8, 31),
          amount_cents: 1000,
          currency: 'EUR',
          season: '2025-2026',
          is_child_membership: false,
          rgpd_consent: true,
          legal_notices_accepted: true
        )
      }.to change { AuditLog.where(target_type: 'Membership').count }.by(1)

      log = AuditLog.where(target_type: 'Membership').last
      expect(log.action).to eq('created')
      expect(log.target_type).to eq('Membership')
      expect(log.target_id).to eq(membership.id)
      expect(log.actor_user_id).to eq(user.id)
      expect(log.metadata).to include(
        'user_id' => user.id,
        'status' => 'active',
        'category' => 'standard'
      )
    end

    it 'creates an audit log on update' do
      membership = Membership.create!(
        user: user,
        status: :active,
        category: :standard,
        start_date: Date.new(2025, 9, 1),
        end_date: Date.new(2026, 8, 31),
        amount_cents: 1000,
        currency: 'EUR',
        season: '2025-2026',
        is_child_membership: false,
        rgpd_consent: true,
        legal_notices_accepted: true
      )

      expect {
        membership.update!(status: :expired)
      }.to change { AuditLog.where(target_type: 'Membership').count }.by(1)

      log = AuditLog.where(target_type: 'Membership').last
      expect(log.action).to eq('updated')
      expect(log.target_type).to eq('Membership')
      expect(log.target_id).to eq(membership.id)
      expect(log.actor_user_id).to eq(user.id)
      expect(log.metadata).to include(
        'id' => membership.id,
        'status' => 'expired',
        'category' => 'standard'
      )
      expect(log.metadata['changes']).to include('status')
    end

    it 'creates an audit log on destruction' do
      membership = Membership.create!(
        user: user,
        status: :active,
        category: :standard,
        start_date: Date.new(2025, 9, 1),
        end_date: Date.new(2026, 8, 31),
        amount_cents: 1000,
        currency: 'EUR',
        season: '2025-2026',
        is_child_membership: false,
        rgpd_consent: true,
        legal_notices_accepted: true
      )

      expect {
        membership.destroy
      }.to change { AuditLog.where(target_type: 'Membership').count }.by(1)

      log = AuditLog.where(target_type: 'Membership').last
      expect(log.action).to eq('destroyed')
      expect(log.target_type).to eq('Membership')
      expect(log.target_id).to eq(membership.id)
      expect(log.actor_user_id).to eq(user.id)
      expect(log.metadata).to include(
        'user_id' => user.id,
        'status' => 'active',
        'category' => 'standard'
      )
    end
  end
end
