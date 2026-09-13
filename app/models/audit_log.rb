class AuditLog < ApplicationRecord
  belongs_to :actor_user, class_name: "User", optional: true

  validates :action, presence: true, length: { maximum: 80 }
  validates :target_type, presence: true, length: { maximum: 50 }
  validates :target_id, presence: true, numericality: { only_integer: true }

  scope :by_action, ->(action) { where(action: action) }
  scope :by_target, ->(type, id) { where(target_type: type, target_id: id) }
  scope :by_actor, ->(user_id) { where(actor_user_id: user_id) }
  scope :recent, -> { order(created_at: :desc) }

  def self.ransackable_attributes(_auth_object = nil)
    %w[id actor_user_id action target_type target_id created_at updated_at]
  end

  def self.ransackable_associations(_auth_object = nil)
    %w[actor_user]
  end
end
