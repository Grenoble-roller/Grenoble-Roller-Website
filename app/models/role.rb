class Role < ApplicationRecord
  has_many :users
  validates :name, presence: true, uniqueness: true
  validates :code, presence: true, uniqueness: true
  validates :level, presence: true, numericality: { only_integer: true, greater_than: 0 }

  # Rôles qu'un utilisateur peut assigner (level <= au sien). Un admin ne peut pas voir/choisir Super_Admin.
  def self.assignable_by(user)
    return none unless user&.role&.level
    where("level <= ?", user.role.level.to_i).order(:level)
  end

  def self.ransackable_attributes(_auth_object = nil)
    %w[id name code description level created_at updated_at]
  end

  def self.ransackable_associations(_auth_object = nil)
    %w[users]
  end
end
