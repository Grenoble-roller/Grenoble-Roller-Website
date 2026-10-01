# frozen_string_literal: true

require "rails_helper"

# Dual waitlist for initiations with allow_non_member_discovery:
# member pool vs discovery (non-member) pool have separate queues so a freed
# spot notifies someone eligible for that pool — not a global FIFO across pools.
RSpec.describe "Event::Initiation dual waitlist (discovery)", type: :model do
  include WaitlistTestHelper

  let(:role) { ensure_role(code: "USER", name: "Utilisateur", level: 10) }
  let(:creator) { create(:user, role: role, confirmed_at: Time.current) }

  # 2 member slots + 2 discovery slots
  let(:initiation) do
    create(
      :event_initiation,
      :published,
      :upcoming,
      creator_user: creator,
      max_participants: 4,
      allow_non_member_discovery: true,
      non_member_discovery_slots: 2
    )
  end

  def create_member_user
    user = create(:user, role: role, confirmed_at: Time.current)
    create(:membership, user: user, status: :active, season: "2025-2026", is_child_membership: false)
    user
  end

  def create_discovery_user
    create(:user, role: role, confirmed_at: Time.current)
  end

  def register!(event, user, free_trial: false)
    attendance = build(
      :attendance,
      event: event,
      user: user,
      status: "registered",
      is_volunteer: false,
      free_trial_used: free_trial
    )
    attendance.save!(validate: false)
    attendance
  end

  def fill_member_slots!(event, count)
    count.times { register!(event, create_member_user) }
    event.reload
  end

  def fill_discovery_slots!(event, count)
    count.times { register!(event, create_discovery_user, free_trial: true) }
    event.reload
  end

  def policy_for(user, record)
    Event::InitiationPolicy.new(user, record)
  end

  describe "capacity split (baseline)" do
    it "is not full? when only member slots are taken" do
      fill_member_slots!(initiation, 2)

      expect(initiation.full_for_members?).to be true
      expect(initiation.full_for_non_members?).to be false
      expect(initiation.full?).to be false
      expect(initiation.available_non_member_places).to eq(2)
    end

    it "is not full? when only discovery slots are taken" do
      fill_discovery_slots!(initiation, 2)

      expect(initiation.full_for_non_members?).to be true
      expect(initiation.full_for_members?).to be false
      expect(initiation.full?).to be false
      expect(initiation.available_member_places).to eq(2)
    end

    it "is full? only when both pools are full" do
      fill_member_slots!(initiation, 2)
      fill_discovery_slots!(initiation, 2)

      expect(initiation.full_for_members?).to be true
      expect(initiation.full_for_non_members?).to be true
      expect(initiation.full?).to be true
    end
  end

  describe "guards when own pool still has seats" do
    it "does not put a member on waitlist when member slots are still open (even if discovery is full)" do
      fill_discovery_slots!(initiation, 2)
      member = create_member_user

      expect(initiation.full_for_members?).to be false
      expect(policy_for(member, initiation).join_waitlist?({})).to be false
      expect(WaitlistEntry.add_to_waitlist(member, initiation)).to be_nil
    end

    it "does not put a discovery user on waitlist when discovery slots are still open (even if members are full)" do
      fill_member_slots!(initiation, 2)
      discovery_user = create_discovery_user

      expect(initiation.full_for_non_members?).to be false
      expect(policy_for(discovery_user, initiation).join_waitlist?({})).to be false
      expect(WaitlistEntry.add_to_waitlist(discovery_user, initiation)).to be_nil
    end
  end

  describe "dual waitlist" do
    it "lets a member join the member waitlist when only member slots are full" do
      fill_member_slots!(initiation, 2)
      member = create_member_user

      expect(initiation.full_for_members?).to be true
      expect(policy_for(member, initiation).join_waitlist?({})).to be true

      entry = WaitlistEntry.add_to_waitlist(member, initiation)
      expect(entry).to be_present
      expect(entry.status).to eq("pending")
      expect(entry.pool).to eq("member")
    end

    it "lets a discovery user join the discovery waitlist when only discovery slots are full" do
      fill_discovery_slots!(initiation, 2)
      discovery_user = create_discovery_user

      expect(initiation.full_for_non_members?).to be true
      expect(policy_for(discovery_user, initiation).join_waitlist?({})).to be true

      entry = WaitlistEntry.add_to_waitlist(discovery_user, initiation)
      expect(entry).to be_present
      expect(entry.pool).to eq("discovery")
    end

    it "notifies the next discovery waiter when a discovery spot frees (not a member ahead in FIFO)" do
      fill_member_slots!(initiation, 2)
      discovery_attendees = Array.new(2) { register!(initiation, create_discovery_user, free_trial: true) }
      initiation.reload

      member_waiting = create_member_user
      discovery_waiting = create_discovery_user
      member_entry = WaitlistEntry.add_to_waitlist(member_waiting, initiation)
      discovery_entry = WaitlistEntry.add_to_waitlist(discovery_waiting, initiation)
      expect(member_entry.pool).to eq("member")
      expect(discovery_entry.pool).to eq("discovery")

      discovery_attendees.first.update_column(:status, "canceled")
      initiation.reload
      WaitlistEntry.notify_next_in_queue(initiation, pool: "discovery")

      expect(discovery_entry.reload.status).to eq("notified")
      expect(member_entry.reload.status).to eq("pending")
    end

    it "notifies the next member waiter when a member spot frees (not a discovery waiter ahead in FIFO)" do
      member_attendees = Array.new(2) { register!(initiation, create_member_user) }
      fill_discovery_slots!(initiation, 2)
      initiation.reload

      discovery_waiting = create_discovery_user
      member_waiting = create_member_user
      discovery_entry = WaitlistEntry.add_to_waitlist(discovery_waiting, initiation)
      member_entry = WaitlistEntry.add_to_waitlist(member_waiting, initiation)

      member_attendees.first.update_column(:status, "canceled")
      initiation.reload
      WaitlistEntry.notify_next_in_queue(initiation, pool: "member")

      expect(member_entry.reload.status).to eq("notified")
      expect(discovery_entry.reload.status).to eq("pending")
    end

    it "allows both pools to wait independently when the initiation is fully full" do
      fill_member_slots!(initiation, 2)
      fill_discovery_slots!(initiation, 2)

      member = create_member_user
      discovery_user = create_discovery_user

      expect(policy_for(member, initiation).join_waitlist?({})).to be true
      expect(policy_for(discovery_user, initiation).join_waitlist?({})).to be true

      member_entry = WaitlistEntry.add_to_waitlist(member, initiation)
      discovery_entry = WaitlistEntry.add_to_waitlist(discovery_user, initiation)

      expect(member_entry.pool).to eq("member")
      expect(discovery_entry.pool).to eq("discovery")
    end

    it "notifies discovery pool via Attendance destroy callback when a discovery attendance is destroyed" do
      fill_member_slots!(initiation, 2)
      discovery_attendees = Array.new(2) { register!(initiation, create_discovery_user, free_trial: true) }
      initiation.reload

      member_waiting = create_member_user
      discovery_waiting = create_discovery_user
      member_entry = WaitlistEntry.add_to_waitlist(member_waiting, initiation)
      discovery_entry = WaitlistEntry.add_to_waitlist(discovery_waiting, initiation)

      discovery_attendees.first.destroy
      initiation.reload

      expect(discovery_entry.reload.status).to eq("notified")
      expect(member_entry.reload.status).to eq("pending")
    end
  end
end
