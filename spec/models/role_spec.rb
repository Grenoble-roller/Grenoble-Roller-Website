require 'rails_helper'

RSpec.describe Role, type: :model do
  include TestDataHelper

  let(:valid_attributes) { { name: "Utilisateur-#{SecureRandom.hex(3)}", code: "ROLE_SPEC-#{SecureRandom.hex(3)}", level: 1 } }

  it 'is valid with valid attributes' do
    role = Role.new(valid_attributes)
    expect(role).to be_valid
  end

  it 'requires name, code and level' do
    role = Role.new
    expect(role).to be_invalid
    expect(role.errors[:name]).to be_present
    expect(role.errors[:code]).to be_present
    expect(role.errors[:level]).to be_present
  end

  it 'enforces uniqueness on code and name' do
    attrs = valid_attributes
    Role.create!(attrs)
    dup_code = Role.new(attrs.merge(name: "Autre-#{SecureRandom.hex(3)}"))
    dup_name = Role.new(attrs.merge(code: "OTHER-#{SecureRandom.hex(3)}", level: 2))
    expect(dup_code).to be_invalid
    expect(dup_name).to be_invalid
  end

  it 'requires level to be a positive integer' do
    role = Role.new(name: "Test-#{SecureRandom.hex(3)}", code: "ROLE_NEG-#{SecureRandom.hex(3)}", level: 0)
    expect(role).to be_invalid
    expect(role.errors[:level]).to be_present
  end

  it 'has many users' do
    role = Role.create!(valid_attributes)
    create_user(role: role, email: 'a@example.com', first_name: 'A')
    create_user(role: role, email: 'b@example.com', first_name: 'B')
    expect(role.users.count).to eq(2)
  end
end
