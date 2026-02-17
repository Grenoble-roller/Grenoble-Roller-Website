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

  describe '.assignable_by' do
    it 'returns no roles when user is nil' do
      expect(Role.assignable_by(nil)).to eq([])
    end

    it 'returns no roles when user has no role' do
      user = User.new(email: 'norole@example.com', password: 'password12345')
      user.role = nil
      expect(Role.assignable_by(user)).to eq([])
    end

    context 'when user is admin (level 60)' do
      let(:admin_role) { create(:role_admin) }
      let(:admin_user) { create(:user, :admin) }

      before do
        create(:role_user)
        create(:role_organizer)
        create(:role_admin)
        create(:role_superadmin)
      end

      it 'returns only roles with level <= 60' do
        assignable = Role.assignable_by(admin_user)
        levels = assignable.pluck(:level)
        expect(levels.all? { |l| l <= 60 }).to be true
      end

      it 'does not include Super_Admin (level 70)' do
        assignable = Role.assignable_by(admin_user)
        superadmin = assignable.find_by(code: 'SUPERADMIN')
        expect(superadmin).to be_nil
      end
    end

    context 'when user is superadmin (level 70)' do
      let(:superadmin_user) { create(:user, :superadmin) }

      before do
        create(:role_user)
        create(:role_admin)
        create(:role_superadmin)
      end

      it 'returns all roles including Super_Admin' do
        assignable = Role.assignable_by(superadmin_user)
        expect(assignable.find_by(code: 'SUPERADMIN')).to be_present
      end

      it 'orders roles by level ascending' do
        assignable = Role.assignable_by(superadmin_user)
        levels = assignable.pluck(:level)
        expect(levels).to eq(levels.sort)
      end
    end
  end
end
