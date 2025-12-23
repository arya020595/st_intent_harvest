# frozen_string_literal: true

class Role < ApplicationRecord
  include CascadingSoftDelete

  cascade_soft_delete :roles_permissions

  has_many :users
  has_many :roles_permissions, dependent: :destroy
  has_many :permissions, through: :roles_permissions

  validates :name, presence: true, uniqueness: true

  before_destroy :check_for_users

  # Ransack configuration
  def self.ransackable_attributes(_auth_object = nil)
    %w[id name description created_at updated_at]
  end

  def self.ransackable_associations(_auth_object = nil)
    %w[users permissions roles_permissions]
  end

  private

  def check_for_users
    return unless users.exists?

    errors.add(:base, 'Cannot delete role with associated users')
    throw(:abort)
  end
end

# == Schema Information
#
# Table name: roles
#
#  id           :integer          not null, primary key
#  created_at   :datetime         not null
#  description  :text
#  name         :string
#  updated_at   :datetime         not null
#  discarded_at :datetime
#
# Indexes
#
#  index_roles_on_discarded_at  (discarded_at)
#
