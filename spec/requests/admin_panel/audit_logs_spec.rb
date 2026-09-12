require 'rails_helper'

RSpec.describe 'AdminPanel::AuditLogs', type: :request do
  include RequestAuthenticationHelper

  # The filter selects also render option lists containing every action/target,
  # so assertions must be scoped to the results table, not the whole body.
  def table_rows
    Nokogiri::HTML(response.body).css('table tbody tr')
  end

  let(:superadmin_user) { create(:user, :superadmin) }
  let(:admin_user) { create(:user, :admin) }

  describe 'GET /admin-panel/audit-logs' do
    context 'when user is superadmin (level 70)' do
      before do
        login_user(superadmin_user)
        # Creating users/roles writes audit entries (User includes Auditable) —
        # clear them so assertions only see the entries each example builds.
        AuditLog.delete_all
      end

      it 'returns success' do
        get admin_panel_audit_logs_path
        expect(response).to have_http_status(:success)
      end

      it 'renders the journal heading' do
        get admin_panel_audit_logs_path
        expect(response.body).to include("Journal d'Audit")
      end

      it 'handles an empty journal' do
        expect(AuditLog.count).to eq(0)
        get admin_panel_audit_logs_path
        expect(response).to have_http_status(:success)
        expect(table_rows).to be_empty
      end

      it 'lists the most recent entries first' do
        create(:audit_log, action: 'old.entry', created_at: 3.days.ago)
        create(:audit_log, action: 'recent.entry', created_at: 1.hour.ago)

        get admin_panel_audit_logs_path

        rows = table_rows
        expect(rows.size).to eq(2)
        expect(rows.first.text).to include('recent.entry')
        expect(rows.last.text).to include('old.entry')
      end

      it 'shows the actor, target and action of an entry' do
        actor = create(:user, first_name: 'Alice', last_name: 'Martin')
        create(:audit_log, actor_user: actor, action: 'event.publish',
                           target_type: 'Event', target_id: 42)

        get admin_panel_audit_logs_path

        row = table_rows.first.text
        expect(row).to include('event.publish')
        expect(row).to include('Event#42')
        expect(row).to include('Alice M.')
      end

      it 'labels a nil actor as system' do
        create(:audit_log, actor_user: nil, action: 'created')

        get admin_panel_audit_logs_path

        expect(table_rows.first.text).to include('Système')
      end
    end

    context 'filtering' do
      before do
        login_user(superadmin_user)
        AuditLog.delete_all
      end

      it 'filters by action' do
        create(:audit_log, action: 'event.publish')
        create(:audit_log, action: 'product.create')

        get admin_panel_audit_logs_path, params: { audit_action: 'event.publish' }

        expect(response).to have_http_status(:success)
        expect(table_rows.size).to eq(1)
        expect(table_rows.first.text).to include('event.publish')
      end

      it 'filters by target type' do
        create(:audit_log, target_type: 'Event', action: 'kept')
        create(:audit_log, target_type: 'Product', action: 'dropped')

        get admin_panel_audit_logs_path, params: { target_type: 'Event' }

        expect(table_rows.size).to eq(1)
        expect(table_rows.first.text).to include('kept')
      end

      it 'filters by actor' do
        actor = create(:user)
        other = create(:user)
        # Creating a user writes its own audit entry (User includes Auditable).
        AuditLog.delete_all
        create(:audit_log, actor_user: actor, action: 'by.actor')
        create(:audit_log, actor_user: other, action: 'by.other')

        get admin_panel_audit_logs_path, params: { actor_user_id: actor.id }

        expect(table_rows.size).to eq(1)
        expect(table_rows.first.text).to include('by.actor')
      end

      it 'filters by lower date bound' do
        create(:audit_log, action: 'old.entry', created_at: 10.days.ago)
        create(:audit_log, action: 'recent.entry', created_at: 1.hour.ago)

        get admin_panel_audit_logs_path, params: { since: 2.days.ago.to_date.to_s }

        expect(table_rows.size).to eq(1)
        expect(table_rows.first.text).to include('recent.entry')
      end

      it 'filters by upper date bound' do
        create(:audit_log, action: 'old.entry', created_at: 10.days.ago)
        create(:audit_log, action: 'recent.entry', created_at: 1.hour.ago)

        get admin_panel_audit_logs_path, params: { until: 2.days.ago.to_date.to_s }

        expect(table_rows.size).to eq(1)
        expect(table_rows.first.text).to include('old.entry')
      end

      it 'combines filters' do
        create(:audit_log, action: 'event.publish', target_type: 'Event', created_at: 1.hour.ago)
        create(:audit_log, action: 'event.publish', target_type: 'Event', created_at: 30.days.ago)
        create(:audit_log, action: 'product.create', target_type: 'Product', created_at: 1.hour.ago)

        get admin_panel_audit_logs_path,
            params: { audit_action: 'event.publish', target_type: 'Event', since: 2.days.ago.to_date.to_s }

        expect(table_rows.size).to eq(1)
      end

      it 'ignores invalid filter values without raising' do
        create(:audit_log, action: 'kept')

        get admin_panel_audit_logs_path, params: { actor_user_id: 'abc', since: 'not-a-date' }

        expect(response).to have_http_status(:success)
        expect(table_rows.size).to eq(1)
      end
    end

    context 'when user is admin (level 60)' do
      before { login_user(admin_user) }

      it 'redirects with an alert reserved to superadmins' do
        get admin_panel_audit_logs_path
        expect(response).to redirect_to(admin_panel_initiations_path)
        expect(flash[:alert]).to include('super-administrateurs')
      end
    end

    context 'when user is not signed in' do
      it 'redirects to login' do
        get admin_panel_audit_logs_path
        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end

  describe 'GET /admin-panel/audit-logs/:id' do
    context 'when user is superadmin (level 70)' do
      before do
        login_user(superadmin_user)
        AuditLog.delete_all
      end

      it 'returns success' do
        log = create(:audit_log, :with_actor, action: 'event.cancel', target_type: 'Event', target_id: 7,
                                              metadata: { "reason" => "météo" })

        get admin_panel_audit_log_path(log)

        expect(response).to have_http_status(:success)
      end

      it 'renders the entry details' do
        log = create(:audit_log, :with_actor, action: 'user.promote', target_type: 'User', target_id: 12,
                                              metadata: { "to" => "ADMIN" })

        get admin_panel_audit_log_path(log)

        expect(response.body).to include('user.promote')
        expect(response.body).to include('User#12')
        expect(response.body).to include('ADMIN')
      end

      it 'lists the other entries for the same target' do
        create(:audit_log, action: 'created', target_type: 'Event', target_id: 7)
        current = create(:audit_log, action: 'updated', target_type: 'Event', target_id: 7)
        create(:audit_log, action: 'product.create', target_type: 'Product', target_id: 99)

        get admin_panel_audit_log_path(current)

        rows = table_rows
        expect(rows.size).to eq(1)
        expect(rows.first.text).to include('created')
      end

      it 'never writes to the journal (read-only UI)' do
        log = create(:audit_log)

        expect {
          get admin_panel_audit_logs_path
          get admin_panel_audit_log_path(log)
        }.not_to change(AuditLog, :count)
      end
    end

    context 'when user is admin (level 60)' do
      before { login_user(admin_user) }

      it 'redirects with an alert reserved to superadmins' do
        log = create(:audit_log)

        get admin_panel_audit_log_path(log)

        expect(response).to redirect_to(admin_panel_initiations_path)
        expect(flash[:alert]).to include('super-administrateurs')
      end
    end

    context 'when user is not signed in' do
      it 'redirects to login' do
        log = create(:audit_log)

        get admin_panel_audit_log_path(log)

        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end

  describe 'routing' do
    it 'is read-only (no write routes exposed)' do
      paths = Rails.application.routes.routes.filter_map do |route|
        route.path.spec.to_s if route.path.spec.to_s.start_with?('/admin-panel/audit-logs')
      end

      expect(paths).to be_present
      expect(paths.all? { |path| path.include?('audit-logs') }).to be(true)

      verbs = Rails.application.routes.routes.filter_map do |route|
        route.verb.to_s if route.path.spec.to_s.start_with?('/admin-panel/audit-logs')
      end
      expect(verbs.uniq).to all(eq('GET'))
    end
  end
end
