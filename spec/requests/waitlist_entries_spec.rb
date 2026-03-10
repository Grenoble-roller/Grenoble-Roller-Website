# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Waitlist Entries', type: :request do
  include RequestAuthenticationHelper
  include WaitlistTestHelper

  let(:role) { ensure_role(code: 'USER', name: 'Utilisateur', level: 10) }
  let(:user) { create(:user, role: role, confirmed_at: Time.current) }
  let(:event) do
    creator = create(:user, role: role, confirmed_at: Time.current)
    event = build(:event, :published, :upcoming, max_participants: 2, creator_user: creator)
    # S'assurer que l'image est attachée avant la validation
    unless event.cover_image.attached?
      test_image_path = Rails.root.join('spec', 'fixtures', 'files', 'test-image.jpg')
      FileUtils.mkdir_p(test_image_path.dirname)
      unless test_image_path.exist?
        jpeg_data = "\xFF\xD8\xFF\xE0\x00\x10JFIF\x00\x01\x01\x01\x00H\x00H\x00\x00\xFF\xDB\x00C\x00\x08\x06\x06\x07\x06\x05\x08\x07\x07\x07\t\t\x08\n\f\x14\r\f\x0B\x0B\f\x19\x12\x13\x0F\x14\x1D\x1A\x1F\x1E\x1D\x1A\x1C\x1C $.' \",#\x1C\x1C(7),01444\x1F'9=82<.342\xFF\xC0\x00\x0B\x08\x00\x01\x00\x01\x01\x01\x11\x00\xFF\xC4\x00\x14\x00\x01\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x08\xFF\xC4\x00\x14\x10\x01\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\xFF\xDA\x00\x08\x01\x01\x00\x00?\x00\xAA\xFF\xD9"
        File.binwrite(test_image_path, jpeg_data)
      end
      event.cover_image.attach(
        io: File.open(test_image_path),
        filename: 'test-image.jpg',
        content_type: 'image/jpeg'
      )
    end
    event.save!
    event
  end
  let(:initiation) { create(:event_initiation, :published, :upcoming, max_participants: 2) }

  # Stubber l'envoi d'emails pour éviter les erreurs SMTP
  before do
    allow_any_instance_of(User).to receive(:send_confirmation_instructions).and_return(true)
    allow_any_instance_of(User).to receive(:send_welcome_email_and_confirmation).and_return(true)
  end

  describe 'POST /events/:event_id/waitlist_entries' do
    context 'when event is full' do
      before do
        fill_event_to_capacity(event, 2)
      end

      it 'requires authentication' do
        post event_waitlist_entries_path(event)

        expect(response).to redirect_to(new_user_session_path)
      end

      it 'creates a waitlist entry' do
        login_user(user)

        expect {
          post event_waitlist_entries_path(event), params: { waitlist_entry: { wants_reminder: false } }
        }.to change { WaitlistEntry.count }.by(1)

        expect(response).to redirect_to(event_path(event))
        expect(flash[:notice]).to be_present
      end
    end
  end

  describe 'POST /initiations/:initiation_id/waitlist_entries' do
    context 'when initiation is full' do
      before do
        fill_event_to_capacity(initiation, 2)
      end

      it 'requires authentication' do
        post initiation_waitlist_entries_path(initiation)

        expect(response).to redirect_to(new_user_session_path)
      end

      it 'prevents non-member from joining initiation waitlist (members only)' do
        login_user(user)
        expect(user.memberships.active_now.where(is_child_membership: false).exists?).to be(false)

        expect {
          post initiation_waitlist_entries_path(initiation), params: {
            use_free_trial: '1',
            wants_reminder: false
          }
        }.not_to change { WaitlistEntry.count }

        expect(response).to redirect_to(initiation_path(initiation))
        expect(flash[:alert]).to include("réservée aux adhérents")
      end

      context 'with parent (member)' do
        before do
          create(:membership, user: user, status: :active, season: '2025-2026', is_child_membership: false)
        end

        it 'allows member to join waitlist with free trial if not already used' do
          login_user(user)

          expect {
            post initiation_waitlist_entries_path(initiation), params: {
              use_free_trial: '1',
              wants_reminder: false
            }
          }.to change { WaitlistEntry.count }.by(1)

          waitlist_entry = WaitlistEntry.last
          expect(waitlist_entry.use_free_trial).to be true
          expect(waitlist_entry.child_membership_id).to be_nil
          expect(response).to redirect_to(initiation_path(initiation))
          expect(flash[:notice]).to be_present
        end

        it 'prevents parent from joining waitlist if free trial already used' do
          other_initiation = create(:event_initiation, :published, :upcoming, max_participants: 10)
          create(:attendance,
            user: user,
            event: other_initiation,
            status: 'registered',
            free_trial_used: true,
            child_membership_id: nil
          )

          login_user(user)

          expect {
            post initiation_waitlist_entries_path(initiation), params: {
              use_free_trial: '1',
              wants_reminder: false
            }
          }.not_to change { WaitlistEntry.count }

          expect(response).to redirect_to(initiation_path(initiation))
          expect(flash[:alert]).to include("Vous avez déjà utilisé votre essai gratuit")
        end
      end

      context 'with child trial membership' do
        let(:child_membership) do
          create(:membership, :child, :trial, :with_health_questionnaire,
            user: user,
            season: '2025-2026'
          )
        end

        it 'prevents child with trial from joining initiation waitlist (members only, active child)' do
          login_user(user)

          expect {
            post initiation_waitlist_entries_path(initiation), params: {
              child_membership_id: child_membership.id,
              use_free_trial: '1',
              wants_reminder: false
            }
          }.not_to change { WaitlistEntry.count }

          expect(response).to redirect_to(initiation_path(initiation))
          expect(flash[:alert]).to include("réservée aux adhérents")
        end
      end

      context 'with child pending membership' do
        let(:child_membership) do
          create(:membership, :child, :pending, :with_health_questionnaire,
            user: user,
            season: '2025-2026'
          )
        end

        it 'prevents child with pending from joining initiation waitlist (members only, active child)' do
          login_user(user)

          expect {
            post initiation_waitlist_entries_path(initiation), params: {
              child_membership_id: child_membership.id,
              use_free_trial: '1',
              wants_reminder: false
            }
          }.not_to change { WaitlistEntry.count }

          expect(response).to redirect_to(initiation_path(initiation))
          expect(flash[:alert]).to include("réservée aux adhérents")
        end
      end

      context 'with child active membership' do
        let(:child_membership) do
          create(:membership, :child, :with_health_questionnaire,
            user: user,
            season: '2025-2026',
            status: :active
          )
        end

        it 'allows child with active membership to join waitlist' do
          login_user(user)

          expect {
            post initiation_waitlist_entries_path(initiation), params: {
              child_membership_id: child_membership.id,
              wants_reminder: false
            }
          }.to change { WaitlistEntry.count }.by(1)

          waitlist_entry = WaitlistEntry.last
          expect(waitlist_entry.child_membership_id).to eq(child_membership.id)
          expect(response).to redirect_to(initiation_path(initiation))
          expect(flash[:notice]).to be_present
        end
      end
    end
  end

  describe 'DELETE /waitlist_entries/:id' do
    # Créer dans before block pour éviter le cache d'association RSpec
    before do
      # Remplir l'événement d'abord (requis pour créer une waitlist_entry)
      fill_event_to_capacity(event, 2)
      @waitlist_entry = build(:waitlist_entry, user: user, event: event)
      @waitlist_entry.save(validate: false)
      # Recharger pour avoir l'ID et le hashid
      @waitlist_entry.reload
      event.waitlist_entries.reload  # ← Critique pour les politiques Pundit!
    end

    it 'requires authentication' do
      delete waitlist_entry_path(@waitlist_entry)

      expect(response).to redirect_to(new_user_session_path)
    end

    it 'cancels the waitlist entry' do
      login_user(user)

      expect {
        delete waitlist_entry_path(@waitlist_entry)
      }.to change { @waitlist_entry.reload.status }.from('pending').to('cancelled')

      expect(response).to redirect_to(event_path(event))
      expect(flash[:notice]).to be_present
    end
  end

  describe 'POST /waitlist_entries/:id/convert_to_attendance' do
    # Créer dans before block pour éviter le cache d'association RSpec
    before do
      # Remplir l'événement d'abord (requis pour créer une waitlist_entry)
      fill_event_to_capacity(event, 2)

      @waitlist_entry = build(:waitlist_entry, user: user, event: event)
      @waitlist_entry.save(validate: false)
      @waitlist_entry.update_column(:status, 'notified')
      @waitlist_entry.update_column(:notified_at, 1.hour.ago)

      # Créer l'attendance pending associée
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
      event.attendances.reload  # ← Critique!
      event.waitlist_entries.reload  # ← Critique pour les politiques Pundit!
      event.reload
    end

    it 'requires authentication' do
      post convert_to_attendance_waitlist_entry_path(@waitlist_entry)

      expect(response).to redirect_to(new_user_session_path)
    end

    it 'converts waitlist entry to attendance' do
      login_user(user)

      expect {
        post convert_to_attendance_waitlist_entry_path(@waitlist_entry)
      }.to change { @waitlist_entry.reload.status }.from('notified').to('converted')

      expect(response).to redirect_to(event_path(event))
      expect(flash[:notice]).to be_present
    end
  end

  describe 'POST /waitlist_entries/:id/refuse' do
    # Créer dans before block pour éviter le cache d'association RSpec
    before do
      # Remplir l'événement d'abord (requis pour créer une waitlist_entry)
      fill_event_to_capacity(event, 2)

      @waitlist_entry = build(:waitlist_entry, user: user, event: event)
      @waitlist_entry.save(validate: false)
      @waitlist_entry.update_column(:status, 'notified')
      @waitlist_entry.update_column(:notified_at, 1.hour.ago)

      # Créer l'attendance pending associée
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
      event.attendances.reload  # ← Critique!
      event.waitlist_entries.reload  # ← Critique pour les politiques Pundit!
      event.reload
    end

    it 'requires authentication' do
      post refuse_waitlist_entry_path(@waitlist_entry)

      expect(response).to redirect_to(new_user_session_path)
    end

    it 'refuses the waitlist entry' do
      login_user(user)

      expect {
        post refuse_waitlist_entry_path(@waitlist_entry)
      }.to change { @waitlist_entry.reload.status }.from('notified').to('cancelled')

      expect(response).to redirect_to(event_path(event))
      expect(flash[:notice]).to be_present
    end
  end

  describe 'GET /waitlist_entries/:id/confirm' do
    # Créer dans before block pour éviter le cache d'association RSpec
    before do
      # Remplir l'événement d'abord (requis pour créer une waitlist_entry)
      fill_event_to_capacity(event, 2)

      @pending_attendance, @waitlist_entry = create_notified_waitlist_with_pending_attendance(user, event)
      event.attendances.reload  # ← Critique!
      event.waitlist_entries.reload  # ← Critique pour les politiques Pundit!
      event.reload  # Recharger l'événement pour mettre à jour le counter_cache
    end

    it 'requires authentication' do
      get confirm_waitlist_entry_path(@waitlist_entry)

      expect(response).to redirect_to(new_user_session_path)
    end

    it 'confirms waitlist entry via GET (from email link)' do
      login_user(user)

      expect {
        get confirm_waitlist_entry_path(@waitlist_entry)
      }.to change { @waitlist_entry.reload.status }.from('notified').to('converted')
        .and change { @pending_attendance.reload.status }.from('pending').to('registered')

      expect(response).to redirect_to(event_path(event))
      expect(flash[:notice]).to be_present
      expect(flash[:notice]).to include('Inscription confirmée')
    end
  end

  describe 'GET /waitlist_entries/:id/decline' do
    # Créer dans before block pour éviter le cache d'association RSpec
    before do
      # Remplir l'événement d'abord (requis pour créer une waitlist_entry)
      fill_event_to_capacity(event, 2)

      @pending_attendance, @waitlist_entry = create_notified_waitlist_with_pending_attendance(user, event)
      event.attendances.reload  # ← Critique!
      event.waitlist_entries.reload  # ← Critique pour les politiques Pundit!
      event.reload  # Recharger l'événement pour mettre à jour le counter_cache
    end

    it 'requires authentication' do
      get decline_waitlist_entry_path(@waitlist_entry)

      expect(response).to redirect_to(new_user_session_path)
    end

    it 'declines waitlist entry via GET (from email link)' do
      initial_count = event.attendances.where(user: user, status: 'pending').count

      login_user(user)

      expect {
        get decline_waitlist_entry_path(@waitlist_entry)
      }.to change { @waitlist_entry.reload.status }.from('notified').to('cancelled')
        .and change { event.attendances.where(user: user, status: 'pending').count }.from(initial_count).to(initial_count - 1)

      expect(response).to redirect_to(event_path(event))
      expect(flash[:notice]).to be_present
      expect(flash[:notice]).to include('refusé')
    end
  end
end
