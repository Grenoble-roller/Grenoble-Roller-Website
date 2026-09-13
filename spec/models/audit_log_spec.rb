require 'rails_helper'

RSpec.describe AuditLog, type: :model do
  include ActiveSupport::Testing::TimeHelpers

  let(:actor) { create_user }

  describe 'validations' do
    it 'is valid with required attributes' do
      log = AuditLog.new(actor_user: actor, action: 'event.publish', target_type: 'Event', target_id: 1)
      expect(log).to be_valid
    end

    it 'requires action, target_type, and target_id' do
      log = AuditLog.new(actor_user: actor)
      expect(log).to be_invalid
      expect(log.errors[:action]).to be_present
      expect(log.errors[:target_type]).to be_present
      expect(log.errors[:target_id]).to be_present
    end
  end

  describe 'scopes' do
    # User includes Auditable — creating users inserts action: "created" rows.
    # Wipe after all actors exist so scope examples only see intentional logs.
    def reset_audit_logs!
      AuditLog.delete_all
    end

    it 'filters by action' do
      actor
      reset_audit_logs!
      matching = AuditLog.create!(actor_user: actor, action: 'event.cancel', target_type: 'Event', target_id: 1)
      AuditLog.create!(actor_user: actor, action: 'user.promote', target_type: 'User', target_id: 2)

      expect(AuditLog.by_action('event.cancel')).to contain_exactly(matching)
    end

    it 'filters by target' do
      actor
      reset_audit_logs!
      target_log = AuditLog.create!(actor_user: actor, action: 'event.update', target_type: 'Event', target_id: 42)
      AuditLog.create!(actor_user: actor, action: 'event.update', target_type: 'Event', target_id: 99)

      expect(AuditLog.by_target('Event', 42)).to contain_exactly(target_log)
    end

    it 'filters by actor' do
      other_actor = create_user(email: 'other@example.com')
      actor
      reset_audit_logs!
      actor_log = AuditLog.create!(actor_user: actor, action: 'event.update', target_type: 'Event', target_id: 1)
      AuditLog.create!(actor_user: other_actor, action: 'event.update', target_type: 'Event', target_id: 2)

      expect(AuditLog.by_actor(actor.id)).to contain_exactly(actor_log)
    end

    it 'returns logs ordered by recency' do
      actor
      reset_audit_logs!

      old_log = travel_to(Time.zone.local(2025, 1, 1, 10)) do
        AuditLog.create!(actor_user: actor, action: 'event.create', target_type: 'Event', target_id: 1)
      end

      recent_log = travel_to(Time.zone.local(2025, 1, 2, 10)) do
        AuditLog.create!(actor_user: actor, action: 'event.publish', target_type: 'Event', target_id: 1)
      end

      expect(AuditLog.recent.to_a).to eq([ recent_log, old_log ])
    end
  end
end
