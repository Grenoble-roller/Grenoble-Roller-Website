require 'rails_helper'

RSpec.describe User, type: :model do
  let!(:role) { ensure_role(code: 'USER', name: 'Utilisateur', level: 10) }

  def build_user(attrs = {})
    defaults = {
      email: 'john.doe@example.com',
      password: 'password12345', # Minimum 12 caractères requis
      first_name: 'John',
      skill_level: 'intermediate'
    }
    User.new(defaults.merge(attrs))
  end

  it 'is valid with valid attributes' do
    user = build_user(role: role)
    expect(user).to be_valid
  end

  it 'requires first_name' do
    user = build_user(role: role, first_name: nil)
    expect(user).to be_invalid
    expect(user.errors[:first_name]).to be_present
  end

  it 'validates phone format and allows blank' do
    expect(build_user(role: role, phone: '')).to be_valid
    expect(build_user(role: role, phone: '0612345678')).to be_valid
    invalid = build_user(role: role, phone: 'abc-123')
    expect(invalid).to be_invalid
    expect(invalid.errors[:phone]).to be_present
  end

  it 'belongs to a role' do
    user = build_user(role: role)
    expect(user.role).to eq(role)
  end

  it 'has many orders' do
    user = build_user(email: 'orders@example.com', role: role)
    allow(user).to receive(:send_confirmation_instructions).and_return(true)
    user.save!
    order1 = Order.create!(user: user, status: 'pending', total_cents: 1000, currency: 'EUR')
    order2 = Order.create!(user: user, status: 'pending', total_cents: 2000, currency: 'EUR')
    expect(user.orders).to match_array([ order1, order2 ])
  end

  it 'sets default role on create when not provided' do
    user = build_user(email: 'default-role@example.com')
    expect(user.role).to be_nil
    allow(user).to receive(:send_confirmation_instructions).and_return(true)
    user.save!
    expect(user.role).to eq(role)
  end

  it 'requires skill_level' do
    user = build_user(role: role, skill_level: nil)
    expect(user).to be_invalid
    expect(user.errors[:skill_level]).to be_present
  end

  it 'validates skill_level inclusion' do
    expect(build_user(role: role, skill_level: 'beginner')).to be_valid
    expect(build_user(role: role, skill_level: 'intermediate')).to be_valid
    expect(build_user(role: role, skill_level: 'advanced')).to be_valid

    invalid = build_user(role: role, skill_level: 'invalid')
    expect(invalid).to be_invalid
    expect(invalid.errors[:skill_level]).to be_present
  end

  it 'allows unconfirmed access (period of grace)' do
    user = build_user(role: role, confirmed_at: nil)
    allow(user).to receive(:send_confirmation_instructions).and_return(true)
    user.save!
    expect(user.active_for_authentication?).to be true
  end

  it 'sends welcome email and confirmation after creation' do
    user = build_user(role: role, email: 'welcome@example.com')

    # Adapter de test requis pour les matchers ActiveJob
    previous_adapter = ActiveJob::Base.queue_adapter
    ActiveJob::Base.queue_adapter = :test

    expect {
      allow(user).to receive(:send_confirmation_instructions).and_return(true)
      user.save!
    }.to have_enqueued_job(ActionMailer::MailDeliveryJob)
      .at_least(:once) # Au moins un email (bienvenue)
  ensure
    ActiveJob::Base.queue_adapter = previous_adapter
  end

  describe '#inactive_message' do
    it 'returns :unconfirmed_email for unconfirmed user' do
      user = build_user(role: role, confirmed_at: nil)
      expect(user.inactive_message).to eq(:unconfirmed_email)
    end

    it 'returns default message for confirmed user' do
      user = build_user(role: role, confirmed_at: Time.current)
      expect(user.inactive_message).not_to eq(:unconfirmed_email)
    end
  end

  describe '#confirmation_token_expired?' do
    let(:user) { build_user(role: role, confirmed_at: nil) }

    before do
      allow(user).to receive(:send_confirmation_instructions).and_return(true)
      user.save!
    end

    it 'returns false if user is already confirmed' do
      user.update!(confirmed_at: Time.current)
      expect(user.confirmation_token_expired?).to be false
    end

    it 'returns false if confirmation_sent_at is not set' do
      user.update!(confirmation_sent_at: nil)
      expect(user.confirmation_token_expired?).to be false
    end

    it 'returns false if token is within confirm_within period' do
      user.update!(confirmation_sent_at: 1.day.ago)
      expect(user.confirmation_token_expired?).to be false
    end

    it 'returns true if token is expired (beyond confirm_within)' do
      user.update!(confirmation_sent_at: 4.days.ago)
      expect(user.confirmation_token_expired?).to be true
    end
  end
end
describe 'audit trail' do
  let(:role) { ensure_role(code: 'USER', name: 'Utilisateur', level: 10) }

  it 'creates an audit log on creation' do
    expect {
      build_user(role: role, email: 'test@example.com', password: 'password12345', password_confirmation: 'password12345', first_name: 'Test', skill_level: 'beginner').save!
    }.to change { AuditLog.count }.by(1)

    log = AuditLog.last
    expect(log.actor_user).to be_a(User)
    expect(log.action).to eq('created')
    expect(log.target_type).to eq('User')
    expect(log.metadata['email']).to eq('test@example.com')
    expect(log.metadata['first_name']).to eq('Test')
  end

  it 'updates audit log on update' do
    user = build_user(role: role, email: 'test@example.com', password: 'password12345', password_confirmation: 'password12345', first_name: 'Test', skill_level: 'beginner')
    user.save!
    expect {
      user.update!(first_name: 'Updated')
    }.to change { AuditLog.count }.by(1)

    log = AuditLog.last
    expect(log.action).to eq('updated')
    expect(log.metadata).to have_key('changes')
    changes = log.metadata['changes']
    expect(changes).to be_a(Hash)
    expect(changes['first_name']).to eq([ 'Test', 'Updated' ])
  end

  it 'creates an audit log on destruction' do
    user = build_user(role: role, email: 'test@example.com', password: 'password12345', password_confirmation: 'password12345', first_name: 'Test', skill_level: 'beginner')
    user.save!
    expect {
      user.destroy
    }.to change { AuditLog.count }.by(1)

    log = AuditLog.last
    expect(log.action).to eq('destroyed')
    expect(log.metadata['email']).to eq('test@example.com')
  end
end
