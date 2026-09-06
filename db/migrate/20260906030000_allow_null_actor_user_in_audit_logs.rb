class AllowNullActorUserInAuditLogs < ActiveRecord::Migration[8.1]
  def change
    change_column_null :audit_logs, :actor_user_id, true
  end
end
