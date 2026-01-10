# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'AdminPanel::Events', type: :request do
  include RequestAuthenticationHelper
  include WaitlistTestHelper

  let(:admin_role) { Role.find_or_create_by!(code: 'ADMIN') { |r| r.name = 'Administrateur'; r.level = 60 } }
  let(:organizer_role) { Role.find_or_create_by!(code: 'ORGANIZER') { |r| r.name = 'Organisateur'; r.level = 40 } }

  describe 'GET /admin-panel/events' do
    context 'when user is admin (level 60)' do
      let(:admin_user) { create(:user, :admin) }

      before do
        login_user(admin_user)
      end

      it 'returns success' do
        get admin_panel_events_path
        expect(response).to have_http_status(:success)
      end

      it 'displays events' do
        create(:event, :published, start_at: 1.week.from_now)
        get admin_panel_events_path
        expect(response.body).to include('Événements')
      end

      it 'excludes initiations' do
        event = create(:event, :published, start_at: 1.week.from_now, max_participants: 0)
        initiation = create(:event_initiation, :published, start_at: 1.week.from_now)

        get admin_panel_events_path

        expect(@controller.instance_variable_get(:@upcoming_events).map(&:id)).to include(event.id)
        expect(@controller.instance_variable_get(:@upcoming_events).map(&:id)).not_to include(initiation.id)
      end

      it 'filters by status' do
        published_event = create(:event, :published, start_at: 1.week.from_now)
        draft_event = create(:event, status: 'draft', start_at: 1.week.from_now)

        get admin_panel_events_path, params: { status: 'published' }

        expect(@controller.instance_variable_get(:@upcoming_events)).to include(published_event)
        expect(@controller.instance_variable_get(:@upcoming_events)).not_to include(draft_event)
      end
    end

    context 'when user is organizer (level 40)' do
      let(:organizer_user) { create(:user, :organizer) }

      before do
        login_user(organizer_user)
      end

      it 'redirects to root with alert' do
        get admin_panel_events_path
        expect(response).to redirect_to(root_path)
        expect(flash[:alert]).to include('Accès admin requis')
      end
    end

    context 'when user is not signed in' do
      it 'redirects to login' do
        get admin_panel_events_path
        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end

  describe 'GET /admin-panel/events/:id' do
    context 'when user is admin (level 60)' do
      let(:admin_user) { create(:user, :admin) }
      let(:event) { create(:event, :published, start_at: 1.week.from_now) }

      before do
        login_user(admin_user)
      end

      it 'returns success' do
        get admin_panel_event_path(event)
        expect(response).to have_http_status(:success)
      end

      it 'displays event details' do
        get admin_panel_event_path(event)
        expect(response.body).to include(event.title)
      end

      it 'displays attendances' do
        attendance = create(:attendance, event: event)
        get admin_panel_event_path(event)
        expect(@controller.instance_variable_get(:@attendances)).to include(attendance)
      end

      it 'displays waitlist entries' do
        # Créer un événement complet pour pouvoir créer une waitlist entry
        full_event = create(:event, :published, start_at: 1.week.from_now, max_participants: 2)
        fill_event_to_capacity(full_event, 2)
        waitlist_entry = create(:waitlist_entry, event: full_event, status: 'pending')

        get admin_panel_event_path(full_event)
        expect(@controller.instance_variable_get(:@waitlist_entries).map(&:id)).to include(waitlist_entry.id)
      end
    end

    context 'when user is organizer (level 40)' do
      let(:organizer_user) { create(:user, :organizer) }
      let(:event) { create(:event, :published, start_at: 1.week.from_now) }

      before do
        login_user(organizer_user)
      end

      it 'redirects to root with alert' do
        get admin_panel_event_path(event)
        expect(response).to redirect_to(root_path)
        expect(flash[:alert]).to include('Accès admin requis')
      end
    end

    context 'when user is not signed in' do
      let(:event) { create(:event, :published, start_at: 1.week.from_now) }

      it 'redirects to login' do
        get admin_panel_event_path(event)
        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end

  describe 'DELETE /admin-panel/events/:id' do
    context 'when user is admin (level 60)' do
      let(:admin_user) { create(:user, :admin) }
      let!(:event) { create(:event, :published, start_at: 1.week.from_now) }

      before do
        login_user(admin_user)
      end

      it 'deletes the event' do
        expect {
          delete admin_panel_event_path(event)
        }.to change(Event, :count).by(-1)
      end

      it 'redirects to events index' do
        delete admin_panel_event_path(event)
        expect(response).to redirect_to(admin_panel_events_path)
      end

      it 'shows success message' do
        delete admin_panel_event_path(event)
        expect(flash[:notice]).to include('supprimé avec succès')
      end
    end

    context 'when user is organizer (level 40)' do
      let(:organizer_user) { create(:user, :organizer) }
      let!(:event) { create(:event, :published, start_at: 1.week.from_now) }

      before do
        login_user(organizer_user)
      end

      it 'redirects to root with alert' do
        delete admin_panel_event_path(event)
        expect(response).to redirect_to(root_path)
        expect(flash[:alert]).to include('Accès admin requis')
      end

      it 'does not delete the event' do
        expect {
          delete admin_panel_event_path(event)
        }.not_to change(Event, :count)
      end
    end
  end

  describe 'POST /admin-panel/events/:id/convert_waitlist' do
    context 'when user is admin (level 60)' do
      let(:admin_user) { create(:user, :admin) }
      let(:event) { create(:event, :published, start_at: 1.week.from_now, max_participants: 2) }
      let(:user) { create(:user) }
      let!(:pending_attendance) { nil }
      let!(:waitlist_entry) { nil }

      before do
        login_user(admin_user)
        # Remplir l'événement pour permettre la création de waitlist
        fill_event_to_capacity(event, 2)
        # Créer waitlist entry notifiée avec attendance pending
        pending_attendance, waitlist_entry = create_notified_waitlist_with_pending_attendance(user, event)
        @pending_attendance = pending_attendance
        @waitlist_entry = waitlist_entry
      end

      it 'converts waitlist entry to attendance' do
        post convert_waitlist_admin_panel_event_path(event), params: { waitlist_entry_id: @waitlist_entry.hashid }

        expect(@pending_attendance.reload.status).to eq('registered')
        expect(@waitlist_entry.reload.status).to eq('converted')
      end

      it 'redirects to event show' do
        post convert_waitlist_admin_panel_event_path(event), params: { waitlist_entry_id: @waitlist_entry.hashid }
        expect(response).to redirect_to(admin_panel_event_path(event))
      end
    end
  end

  describe 'POST /admin-panel/events/:id/notify_waitlist' do
    context 'when user is admin (level 60)' do
      let(:admin_user) { create(:user, :admin) }
      let(:event) { create(:event, :published, start_at: 1.week.from_now, max_participants: 2) }
      let(:user) { create(:user) }
      let!(:waitlist_entry) { nil }

      before do
        login_user(admin_user)
        # Remplir l'événement pour permettre la création de waitlist
        fill_event_to_capacity(event, 2)
        # Créer waitlist entry en pending (sans validation pour éviter l'erreur)
        waitlist_entry = build(:waitlist_entry, event: event, user: user, status: 'pending')
        waitlist_entry.save(validate: false)
        @waitlist_entry = waitlist_entry.reload
      end

      it 'notifies waitlist entry' do
        expect {
          post notify_waitlist_admin_panel_event_path(event), params: { waitlist_entry_id: @waitlist_entry.hashid }
        }.to change { @waitlist_entry.reload.status }.from('pending').to('notified')
      end

      it 'redirects to event show' do
        post notify_waitlist_admin_panel_event_path(event), params: { waitlist_entry_id: @waitlist_entry.hashid }
        expect(response).to redirect_to(admin_panel_event_path(event))
      end
    end
  end
end
