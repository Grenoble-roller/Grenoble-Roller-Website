RSpec::Matchers.define :have_audit_log do |action, target_type|
  match do |block|
    expect { block.call }.to change { AuditLog.where(target_type: target_type, action: action).count }.by(1)
  end
  supports_block_expectations
end
