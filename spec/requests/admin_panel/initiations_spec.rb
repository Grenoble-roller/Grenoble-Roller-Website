require 'rails_helper'

RSpec.describe 'AdminPanel::Initiations', type: :request do
  include RequestAuthenticationHelper
  include WaitlistTestHelper

  let(:initiation_role) { Role.find_or_create_by!(code: 'INITIATION') { |r| r.name = 'Initiation'; r.level = 30 } }
  let(:organizer_role) { Role.find_or_create_by!(code: 'ORGANIZER') { |r| r.name = 'Organisateur'; r.level = 40 } }
  let(:admin_role) { Role.find_or_create_by!(code: 'ADMIN') { |r| r.name = 'Administrateur'; r.level = 60 } }
  let(:superadmin_role) { Role.find_or_create_by!(code: 'SUPERADMIN') { |r| r.name = 'Super Administrateur'; r.level = 70 } }
  let(:user_role) { Role.find_or_create_by!(code: 'USER') { |r| r.name = 'Utilisateur'; r.level = 10 } }

  let(:initiation) { create(:event_initiation, max_participants: 2) }

  describe 'GET /admin-panel/initiations' do
    context 'when user is admin (level 60)' do
      let(:admin_user) { create(:user, :admin) }

      before { sign_in admin_user }

      it 'returns success' do
        get admin_panel_initiations_path
        expect(response).to have_http_status(:success)
      end

      it 'displays initiations' do
        create_list(:event_initiation, 3)
        get admin_panel_initiations_path
        expect(response.body).to include('Initiations')
      end
    end

    context 'when user is organizer (level 40)' do
      let(:organizer_user) { create(:user, :organizer) }

      before { sign_in organizer_user }

      it 'returns success' do
        get admin_panel_initiations_path
        expect(response).to have_http_status(:success)
      end

      it 'can view initiations' do
        create_list(:event_initiation, 2)
        get admin_panel_initiations_path
        expect(response.body).to include('Initiations')
      end
    end

    context 'when user is initiation (level 30)' do
      let(:initiation_user) { create(:user, :initiation) }

      before { sign_in initiation_user }

      it 'returns success' do
        get admin_panel_initiations_path
        expect(response).to have_http_status(:success)
      end
    end

    context 'when user level is below 30' do
      let(:regular_user) { create(:user, role: user_role) }

      before { sign_in regular_user }

      it 'redirects to root with alert' do
        get admin_panel_initiations_path
        expect(response).to redirect_to(root_path)
        expect(flash[:alert]).to include('Accès non autorisé')
      end
    end

    context 'when user is not signed in' do
      it 'redirects to login' do
        get admin_panel_initiations_path
        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end

  describe 'GET /admin-panel/initiations/:id' do
    context 'when user is admin (level 60)' do
      let(:admin_user) { create(:user, :admin) }

      before { sign_in admin_user }

      it 'returns success' do
        get admin_panel_initiation_path(initiation)
        expect(response).to have_http_status(:success)
      end

      it 'displays initiation details' do
        get admin_panel_initiation_path(initiation)
        expect(response.body).to include(initiation.title)
      end
    end

    context 'when user is organizer (level 40)' do
      let(:organizer_user) { create(:user, :organizer) }

      before { sign_in organizer_user }

      it 'returns success' do
        get admin_panel_initiation_path(initiation)
        expect(response).to have_http_status(:success)
      end
    end

    context 'when user level is below 30' do
      let(:regular_user) { create(:user, role: user_role) }

      before { sign_in regular_user }

      it 'redirects to root' do
        get admin_panel_initiation_path(initiation)
        expect(response).to redirect_to(root_path)
      end
    end
  end

  describe 'GET /admin-panel/initiations/:id/presences' do
    context 'when user is admin (level 60)' do
      let(:admin_user) { create(:user, :admin) }

      before { sign_in admin_user }

      it 'returns success' do
        get presences_admin_panel_initiation_path(initiation)
        expect(response).to have_http_status(:success)
      end
    end

    context 'when user is organizer (level 40)' do
      let(:organizer_user) { create(:user, :organizer) }

      before { sign_in organizer_user }

      it 'redirects with not authorized' do
        get presences_admin_panel_initiation_path(initiation)
        expect(response).to redirect_to(admin_panel_root_path)
        expect(flash[:alert]).to be_present
      end
    end
  end

  describe 'PATCH /admin-panel/initiations/:id/update_presences' do
    let(:attendance_user) { create(:user) }
    let!(:membership) { create(:membership, user: attendance_user, status: :active, season: '2025-2026') }
    let(:attendance) { create(:attendance, event: initiation, user: attendance_user, status: 'registered') }

    context 'when user is admin (level 60)' do
      let(:admin_user) { create(:user, :admin) }

      before { sign_in admin_user }

      it 'updates presences' do
        patch update_presences_admin_panel_initiation_path(initiation), params: {
          attendance_ids: [ attendance.id ],
          presences: { attendance.id.to_s => 'present' }
        }
        expect(response).to redirect_to(presences_admin_panel_initiation_path(initiation))
        expect(attendance.reload.status).to eq('present')
      end
    end

    context 'when user is organizer (level 40)' do
      let(:organizer_user) { create(:user, :organizer) }

      before { sign_in organizer_user }

      it 'redirects with not authorized' do
        patch update_presences_admin_panel_initiation_path(initiation), params: {
          attendance_ids: [ attendance.id ],
          presences: { attendance.id.to_s => 'present' }
        }
        expect(response).to redirect_to(admin_panel_root_path)
      end
    end
  end

  describe 'POST /admin-panel/initiations/:id/notify_waitlist' do
    let(:waitlist_user) { create(:user, confirmed_at: Time.current) }
    let!(:waitlist_entry) do
      fill_event_to_capacity(initiation, 2)
      create(:waitlist_entry, event: initiation, user: waitlist_user, status: 'pending')
    end

    context 'when user is admin (level 60)' do
      let(:admin_user) { create(:user, :admin) }

      before { sign_in admin_user }

      it 'notifies waitlist entry and redirects' do
        post notify_waitlist_admin_panel_initiation_path(initiation),
             params: { waitlist_entry_id: waitlist_entry.hashid }
        expect(response).to redirect_to(admin_panel_initiation_path(initiation))
        expect(flash[:notice].present? || flash[:alert].present?).to be true
      end
    end

    context 'when user is organizer (level 40)' do
      let(:organizer_user) { create(:user, :organizer) }

      before { sign_in organizer_user }

      it 'allows access and redirects' do
        post notify_waitlist_admin_panel_initiation_path(initiation),
             params: { waitlist_entry_id: waitlist_entry.hashid }
        expect(response).to redirect_to(admin_panel_initiation_path(initiation))
      end
    end
  end

  describe 'POST /admin-panel/initiations/:id/convert_waitlist' do
    let(:waitlist_user) { create(:user, confirmed_at: Time.current) }
    let!(:waitlist_entry) do
      fill_event_to_capacity(initiation, 2)
      _pending, entry = create_notified_waitlist_with_pending_attendance(waitlist_user, initiation)
      entry
    end

    context 'when user is admin (level 60)' do
      let(:admin_user) { create(:user, :admin) }

      before { sign_in admin_user }

      it 'converts waitlist to registration and redirects' do
        post convert_waitlist_admin_panel_initiation_path(initiation),
             params: { waitlist_entry_id: waitlist_entry.hashid }
        expect(response).to redirect_to(admin_panel_initiation_path(initiation))
      end
    end
  end

  describe 'PATCH /admin-panel/initiations/:id/toggle_volunteer' do
    let(:attendance_user) { create(:user) }
    let!(:membership) { create(:membership, user: attendance_user, status: :active, season: '2025-2026') }
    let!(:attendance) { create(:attendance, event: initiation, user: attendance_user, status: 'registered', is_volunteer: false) }

    context 'when user is admin (level 60)' do
      let(:admin_user) { create(:user, :admin) }

      before { sign_in admin_user }

      it 'toggles volunteer status and redirects' do
        patch toggle_volunteer_admin_panel_initiation_path(initiation),
              params: { attendance_id: attendance.id }
        expect(response).to redirect_to(admin_panel_initiation_path(initiation))
        expect(flash[:notice]).to be_present
      end
    end
  end

  describe 'POST /admin-panel/initiations/:id/return_material' do
    let(:past_initiation) do
      create(:event_initiation, start_at: 2.hours.ago, duration_min: 60, stock_returned_at: nil)
    end

    context 'when user is admin (level 60)' do
      let(:admin_user) { create(:user, :admin) }

      before { sign_in admin_user }

      it 'returns material and redirects to presences' do
        post return_material_admin_panel_initiation_path(past_initiation)
        expect(response).to redirect_to(presences_admin_panel_initiation_path(past_initiation))
        expect(flash[:notice]).to be_present
      end
    end

    context 'when initiation is in the future' do
      let(:admin_user) { create(:user, :admin) }
      let(:future_initiation) { create(:event_initiation, start_at: 1.hour.from_now, stock_returned_at: nil) }

      before { sign_in admin_user }

      it 'redirects with alert' do
        post return_material_admin_panel_initiation_path(future_initiation)
        expect(response).to redirect_to(presences_admin_panel_initiation_path(future_initiation))
        expect(flash[:alert]).to include('pas encore terminée')
      end
    end
  end
end
