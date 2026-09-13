require 'rails_helper'

RSpec.describe Payment, type: :model do
  let!(:role) { ensure_role(code: 'USER_PAYMENT', name: 'Utilisateur Payment', level: 40) }
  let!(:user) { create_user(role: role, email: 'pay@example.com', first_name: 'Pay') }

  it 'nullifies payment_id on associated orders when destroyed' do
    payment = Payment.create!(provider: 'test', provider_payment_id: 'abc123', amount_cents: 1000, currency: 'EUR', status: 'succeeded')
    order1 = Order.create!(user: user, payment: payment, status: 'pending', total_cents: 1000, currency: 'EUR')
    order2 = Order.create!(user: user, payment: payment, status: 'pending', total_cents: 2000, currency: 'EUR')
    payment.destroy
    expect(order1.reload.payment_id).to be_nil
    expect(order2.reload.payment_id).to be_nil
  end

  describe 'audit trail' do
    it 'creates an audit log on creation' do
      expect do
        create(:payment)
      end.to change { AuditLog.where(target_type: 'Payment').count }.by(1)

      log = AuditLog.where(target_type: 'Payment').last
      expect(log.action).to eq('created')
      expect(log.target_type).to eq('Payment')
      expect(log.target_id).to be_present
      expect(log.actor_user_id).to be_nil
      expect(log.metadata).to include('provider' => 'helloasso', 'status' => 'completed')
    end

    it 'creates an audit log on update' do
      payment = create(:payment)
      expect do
        payment.update!(status: 'refunded')
      end.to change { AuditLog.where(target_type: 'Payment').count }.by(1)

      log = AuditLog.where(target_type: 'Payment').last
      expect(log.action).to eq('updated')
      expect(log.metadata).to have_key('changes')
      expect(log.metadata['changes']).to include('status')
    end

    it 'creates an audit log on destruction' do
      payment = create(:payment)
      expect do
        payment.destroy!
      end.to change { AuditLog.where(target_type: 'Payment').count }.by(1)

      log = AuditLog.where(target_type: 'Payment').last
      expect(log.action).to eq('destroyed')
    end
  end
end
