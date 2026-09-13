# frozen_string_literal: true

module AdminPanel
  # Read-only consultation of the audit trail (AuditLog).
  #
  # Entries are written by the Auditable concern — this controller never creates,
  # updates or destroys anything. Access is restricted to super-admins (level 70),
  # same gate as the mail logs.
  class AuditLogsController < BaseController
    before_action :ensure_superadmin

    # NOTE: `params[:action]` is reserved by Rails (it holds the controller action
    # name), hence the `audit_action` query parameter for the log's own action.
    def index
      @logs = AuditLog.includes(:actor_user).recent

      @logs = @logs.by_action(params[:audit_action]) if params[:audit_action].present?
      @logs = @logs.where(target_type: params[:target_type]) if params[:target_type].present?
      @logs = @logs.by_actor(params[:actor_user_id]) if numeric?(params[:actor_user_id])

      since_date = parse_date(params[:since])
      @logs = @logs.where("created_at >= ?", since_date.beginning_of_day) if since_date

      until_date = parse_date(params[:until])
      @logs = @logs.where("created_at <= ?", until_date.end_of_day) if until_date

      @pagy, @logs = pagy(@logs, items: 50)

      @stats = {
        total: AuditLog.count,
        actions: AuditLog.distinct.count(:action),
        targets: AuditLog.distinct.count(:target_type),
        actors: AuditLog.where.not(actor_user_id: nil).distinct.count(:actor_user_id)
      }

      @available_actions = AuditLog.where.not(action: [ nil, "" ])
                                  .distinct
                                  .order(:action)
                                  .pluck(:action)
      @available_targets = AuditLog.where.not(target_type: [ nil, "" ])
                                   .distinct
                                   .order(:target_type)
                                   .pluck(:target_type)
      @available_actors = User.where(id: AuditLog.where.not(actor_user_id: nil).select(:actor_user_id))
                              .order(:last_name, :first_name)
    end

    def show
      @log = AuditLog.includes(:actor_user).find(params[:id])
      @history = AuditLog.where(target_type: @log.target_type, target_id: @log.target_id)
                         .where.not(id: @log.id)
                         .recent
                         .limit(20)
    end

    private

    def ensure_superadmin
      unless current_user&.role&.level.to_i >= 70
        redirect_to admin_panel_initiations_path, alert: "Accès réservé aux super-administrateurs"
      end
    end

    def numeric?(value)
      value.to_s.match?(/\A\d+\z/)
    end

    def parse_date(value)
      return nil if value.blank?

      Date.parse(value.to_s)
    rescue ArgumentError, TypeError
      nil
    end
  end
end
