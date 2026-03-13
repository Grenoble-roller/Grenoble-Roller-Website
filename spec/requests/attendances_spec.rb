# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Attendances', type: :request do
  include RequestAuthenticationHelper
  include TestDataHelper

  let(:role) { ensure_role(code: 'USER', name: 'Utilisateur', level: 10) }
  let(:user) do
    u = create_user(role: role, confirmed_at: Time.current)
    # Créer une adhésion active pour l'utilisateur
    create(:membership, user: u, status: :active, season: '2025-2026', start_date: Date.today.beginning_of_year, end_date: Date.today.end_of_year)
    u
  end
  let(:event) do
    e = build_event(status: 'published', start_at: 1.week.from_now)
    e.save!
    e
  end
  let(:initiation) do
    e = build_event(type: 'Event::Initiation', status: 'published', start_at: 1.week.from_now, max_participants: 30, allow_non_member_discovery: false)
    e.save!
    e
  end

  # Stubber l'envoi d'emails pour éviter les erreurs SMTP
  before do
    allow_any_instance_of(User).to receive(:send_confirmation_instructions).and_return(true)
    allow_any_instance_of(User).to receive(:send_welcome_email_and_confirmation).and_return(true)
  end

  describe 'PATCH /events/:event_id/attendances/toggle_reminder' do
    let(:attendance) { create_attendance(user: user, event: event, wants_reminder: false) }

    it 'requires authentication' do
      patch toggle_reminder_event_attendances_path(event)

      expect(response).to redirect_to(new_user_session_path)
    end

    it 'toggles reminder preference for authenticated user' do
      login_user(user)

      expect {
        patch toggle_reminder_event_attendances_path(event)
      }.to change { attendance.reload.wants_reminder }.from(false).to(true)

      expect(response).to redirect_to(event_path(event))
      expect(flash[:notice]).to be_present
    end

    it 'toggles reminder from true to false' do
      attendance.update!(wants_reminder: true)
      login_user(user)

      expect {
        patch toggle_reminder_event_attendances_path(event)
      }.to change { attendance.reload.wants_reminder }.from(true).to(false)

      expect(response).to redirect_to(event_path(event))
    end
  end

  describe 'PATCH /initiations/:initiation_id/attendances/toggle_reminder' do
    let(:attendance) { create_attendance(user: user, event: initiation, wants_reminder: false) }

    it 'requires authentication' do
      patch toggle_reminder_initiation_attendances_path(initiation)

      expect(response).to redirect_to(new_user_session_path)
    end

    it 'toggles reminder preference for authenticated user' do
      login_user(user)

      expect {
        patch toggle_reminder_initiation_attendances_path(initiation)
      }.to change { attendance.reload.wants_reminder }.from(false).to(true)

      expect(response).to redirect_to(initiation_path(initiation))
      expect(flash[:notice]).to be_present
    end
  end
end
