require 'rails_helper'

RSpec.describe 'AdminPanel::MailLogs', type: :request do
  include RequestAuthenticationHelper

  describe 'GET /admin-panel/mail-logs' do
    context 'when user is superadmin (level 70)' do
      let(:superadmin_user) { create(:user, :superadmin) }

      before { login_user(superadmin_user) }

      it 'returns success' do
        get admin_panel_mail_logs_path
        expect(response).to have_http_status(:success)
      end
    end

    context 'when user is admin (level 60)' do
      let(:admin_user) { create(:user, :admin) }

      before { login_user(admin_user) }

      it 'redirects with alert reserved to superadmins' do
        get admin_panel_mail_logs_path
        expect(response).to redirect_to(admin_panel_initiations_path)
        expect(flash[:alert]).to include('super-administrateurs')
      end
    end

    context 'when user is not signed in' do
      it 'redirects to login' do
        get admin_panel_mail_logs_path
        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end
end
