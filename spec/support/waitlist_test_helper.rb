# frozen_string_literal: true

module WaitlistTestHelper
  # Remplir l'événement jusqu'à sa capacité
  def fill_event_to_capacity(event, count = 2)
    role = Role.find_or_create_by!(code: 'USER', name: 'Utilisateur', level: 10)
    count.times do
      user = create(:user, role: role, confirmed_at: Time.current)
      attendance = build(:attendance, event: event, user: user, status: 'registered', is_volunteer: false)
      attendance.save(validate: false)
    end
    event.attendances.reload
    event.update_column(:attendances_count, event.attendances.count)
    event.reload
  end

  # Créer une waitlist entry notifiée avec son attendance pending associée
  # Retourne [pending_attendance, waitlist_entry]
  def create_notified_waitlist_with_pending_attendance(user, event)
    # Créer l'attendance PENDING (la place réservée)
    pending_attendance = event.attendances.build(
      user: user,
      child_membership_id: nil,
      status: "pending",
      wants_reminder: false,
      needs_equipment: false,
      roller_size: nil,
      free_trial_used: false
    )
    pending_attendance.save(validate: false)

    # Créer la waitlist_entry
    waitlist_entry = build(:waitlist_entry, user: user, event: event, child_membership_id: nil, wants_reminder: false)
    waitlist_entry.save(validate: false)

    # Mettre à jour le statut
    waitlist_entry.update_column(:status, 'notified')
    waitlist_entry.update_column(:notified_at, 1.hour.ago)

    [ pending_attendance.reload, waitlist_entry.reload ]
  end
end

RSpec.configure do |config|
  config.include WaitlistTestHelper, type: :request
end
