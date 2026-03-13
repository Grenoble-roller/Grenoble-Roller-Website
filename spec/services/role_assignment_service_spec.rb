# frozen_string_literal: true

require 'rails_helper'

RSpec.describe RoleAssignmentService do
  let(:role_user) do
    Role.find_or_create_by!(code: 'USER') { |r| r.name = 'Utilisateur'; r.level = 10 }
  end
  let(:role_admin) do
    Role.find_or_create_by!(code: 'ADMIN') { |r| r.name = 'Administrateur'; r.level = 60 }
  end
  let(:role_superadmin) do
    Role.find_or_create_by!(code: 'SUPERADMIN') { |r| r.name = 'Super Administrateur'; r.level = 70 }
  end

  describe '.can_assign_role_to_user?' do
    context 'when assigner has lower level than new role' do
      let(:admin_user) { create(:user, :admin) }
      let(:target_user) { create(:user) }

      it 'returns false so admin cannot assign Super_Admin' do
        result = described_class.can_assign_role_to_user?(
          assigner: admin_user,
          target_user: target_user,
          new_role: role_superadmin
        )
        expect(result).to be false
      end
    end

    context 'when assigner has same or higher level than new role' do
      let(:admin_user) { create(:user, :admin) }
      let(:target_user) { create(:user) }

      it 'returns true when admin assigns User role to another user' do
        result = described_class.can_assign_role_to_user?(
          assigner: admin_user,
          target_user: target_user,
          new_role: role_user
        )
        expect(result).to be true
      end

      it 'returns true when superadmin assigns Admin role' do
        superadmin_user = create(:user, :superadmin)
        result = described_class.can_assign_role_to_user?(
          assigner: superadmin_user,
          target_user: target_user,
          new_role: role_admin
        )
        expect(result).to be true
      end
    end

    context 'when target user is the assigner (self)' do
      let(:admin_user) { create(:user, :admin) }

      it 'returns false when admin tries to assign themselves Super_Admin' do
        result = described_class.can_assign_role_to_user?(
          assigner: admin_user,
          target_user: admin_user,
          new_role: role_superadmin
        )
        expect(result).to be false
      end

      it 'returns true when admin assigns themselves a lower role (demotion)' do
        result = described_class.can_assign_role_to_user?(
          assigner: admin_user,
          target_user: admin_user,
          new_role: role_user
        )
        expect(result).to be true
      end
    end

    context 'when assigner or new_role is missing' do
      let(:target_user) { create(:user) }

      it 'returns false when assigner is nil' do
        result = described_class.can_assign_role_to_user?(
          assigner: nil,
          target_user: target_user,
          new_role: role_user
        )
        expect(result).to be false
      end

      it 'returns false when new_role is nil' do
        admin_user = create(:user, :admin)
        result = described_class.can_assign_role_to_user?(
          assigner: admin_user,
          target_user: target_user,
          new_role: nil
        )
        expect(result).to be false
      end
    end
  end

  describe '.assign_role!' do
    let(:admin_user) { create(:user, :admin) }
    let(:target_user) { create(:user) }

    it 'assigns role when authorized' do
      described_class.assign_role!(
        assigner: admin_user,
        target_user: target_user,
        new_role: role_user
      )
      target_user.reload
      expect(target_user.role_id).to eq(role_user.id)
    end

    it 'raises UnauthorizedRoleAssignment when assigner cannot assign the role' do
      expect {
        described_class.assign_role!(
          assigner: admin_user,
          target_user: target_user,
          new_role: role_superadmin
        )
      }.to raise_error(RoleAssignmentService::UnauthorizedRoleAssignment)
    end
  end
end
