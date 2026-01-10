# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'AdminPanel::Attendances', type: :request do
  let(:admin_role) { Role.find_or_create_by!(code: 'ADMIN') { |r| r.name = 'Administrateur'; r.level = 60 } }
  let(:organizer_role) { Role.find_or_create_by!(code: 'ORGANIZER') { |r| r.name = 'Organisateur'; r.level = 40 } }
  let(:user_role) { Role.find_or_create_by!(code: 'USER') { |r| r.name = 'Utilisateur'; r.level = 10 } }

  describe 'GET /admin-panel/attendances' do
    context 'when user is admin (level 60)' do
      let(:admin_user) { create(:user, :admin) }

      before { login_user(admin_user) }

      it 'returns success' do
        get admin_panel_attendances_path
        expect(response).to have_http_status(:success)
      end

      it 'displays attendances' do
        create_list(:attendance, 3)
        get admin_panel_attendances_path
        expect(response.body).to include('Participations')
      end
    end

    context 'when user is organizer (level 40)' do
      let(:organizer_user) { create(:user, :organizer) }

      before { login_user(organizer_user) }

      it 'redirects to root with alert' do
        get admin_panel_attendances_path
        expect(response).to redirect_to(root_path)
        expect(flash[:alert]).to include('Accès admin requis')
      end
    end

    context 'when user level is below 60' do
      let(:regular_user) { create(:user) }

      before { login_user(regular_user) }

      it 'redirects to root' do
        get admin_panel_attendances_path
        expect(response).to redirect_to(root_path)
      end
    end

    context 'when user is not signed in' do
      it 'redirects to login' do
        get admin_panel_attendances_path
        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end

  describe 'GET /admin-panel/attendances/:id' do
    let(:attendance) { create(:attendance) }

    context 'when user is admin (level 60)' do
      let(:admin_user) { create(:user, :admin) }

      before { login_user(admin_user) }

      it 'returns success' do
        get admin_panel_attendance_path(attendance)
        expect(response).to have_http_status(:success)
      end

      it 'displays attendance details' do
        get admin_panel_attendance_path(attendance)
        expect(response.body).to include('Participation')
      end
    end

    context 'when user is organizer (level 40)' do
      let(:organizer_user) { create(:user, :organizer) }

      before { login_user(organizer_user) }

      it 'redirects to root with alert' do
        get admin_panel_attendance_path(attendance)
        expect(response).to redirect_to(root_path)
      end
    end
  end

  describe 'GET /admin-panel/attendances/new' do
    context 'when user is admin (level 60)' do
      let(:admin_user) { create(:user, :admin) }

      before { login_user(admin_user) }

      it 'returns success' do
        get new_admin_panel_attendance_path
        expect(response).to have_http_status(:success)
      end
    end
  end

  describe 'POST /admin-panel/attendances' do
    context 'when user is admin (level 60)' do
      let(:admin_user) { create(:user, :admin) }
      let(:event) { create(:event) }
      let(:user) { create(:user) }

      before { login_user(admin_user) }

      context 'with valid params' do
        let(:valid_params) do
          {
            attendance: {
              user_id: user.id,
              event_id: event.id,
              status: 'registered',
              is_volunteer: false,
              free_trial_used: false,
              wants_reminder: false,
              needs_equipment: false
            }
          }
        end

        it 'creates a new attendance' do
          expect {
            post admin_panel_attendances_path, params: valid_params
          }.to change(Attendance, :count).by(1)
        end

        it 'redirects to the attendance show page' do
          post admin_panel_attendances_path, params: valid_params
          expect(response).to redirect_to(admin_panel_attendance_path(Attendance.last))
        end
      end

      context 'with invalid params' do
        let(:invalid_params) do
          {
            attendance: {
              user_id: nil,
              event_id: nil,
              status: 'invalid_status'
            }
          }
        end

        it 'does not create an attendance' do
          expect {
            post admin_panel_attendances_path, params: invalid_params
          }.not_to change(Attendance, :count)
        end

        it 'renders new template' do
          post admin_panel_attendances_path, params: invalid_params
          expect(response).to have_http_status(:unprocessable_entity)
        end
      end
    end
  end

  describe 'GET /admin-panel/attendances/:id/edit' do
    let(:attendance) { create(:attendance) }

    context 'when user is admin (level 60)' do
      let(:admin_user) { create(:user, :admin) }

      before { login_user(admin_user) }

      it 'returns success' do
        get edit_admin_panel_attendance_path(attendance)
        expect(response).to have_http_status(:success)
      end
    end
  end

  describe 'PATCH /admin-panel/attendances/:id' do
    let(:attendance) { create(:attendance) }

    context 'when user is admin (level 60)' do
      let(:admin_user) { create(:user, :admin) }

      before { login_user(admin_user) }

      context 'with valid params' do
        let(:update_params) do
          {
            attendance: {
              status: 'paid',
              is_volunteer: true
            }
          }
        end

        it 'updates the attendance' do
          patch admin_panel_attendance_path(attendance), params: update_params
          attendance.reload
          expect(attendance.status).to eq('paid')
          expect(attendance.is_volunteer).to be true
        end

        it 'redirects to the attendance show page' do
          patch admin_panel_attendance_path(attendance), params: update_params
          expect(response).to redirect_to(admin_panel_attendance_path(attendance))
        end
      end

      context 'with invalid params' do
        let(:invalid_params) do
          {
            attendance: {
              status: 'invalid_status'
            }
          }
        end

        it 'does not update the attendance' do
          original_status = attendance.status
          patch admin_panel_attendance_path(attendance), params: invalid_params
          attendance.reload
          expect(attendance.status).to eq(original_status)
        end

        it 'renders edit template' do
          patch admin_panel_attendance_path(attendance), params: invalid_params
          expect(response).to have_http_status(:unprocessable_entity)
        end
      end
    end
  end

  describe 'DELETE /admin-panel/attendances/:id' do
    let!(:attendance) { create(:attendance) }

    context 'when user is admin (level 60)' do
      let(:admin_user) { create(:user, :admin) }

      before { login_user(admin_user) }

      it 'deletes the attendance' do
        expect {
          delete admin_panel_attendance_path(attendance)
        }.to change(Attendance, :count).by(-1)
      end

      it 'redirects to attendances index' do
        delete admin_panel_attendance_path(attendance)
        expect(response).to redirect_to(admin_panel_attendances_path)
      end
    end
  end
end
