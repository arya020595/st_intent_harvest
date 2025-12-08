# frozen_string_literal: true

class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable, :trackable

  belongs_to :role, optional: true

  validates :name, presence: true

  # Check if user has a specific permission code
  # Superadmin role bypasses all permission checks
  # Example: user.has_permission?("admin.users.index")
  def has_permission?(code)
    return false unless role
    return true if superadmin?

    @permission_codes ||= role.permissions.pluck(:code)
    @permission_codes.include?(code)
  end

  # Check if user has any permission for a resource
  # Example: user.has_resource_permission?("admin.users")
  def has_resource_permission?(resource)
    return false unless role
    return true if superadmin?

    @permission_codes ||= role.permissions.pluck(:code)
    @permission_codes.any? { |code| code.start_with?("#{resource}.") }
  end

  # Check if user is superadmin (bypasses all permission checks)
  def superadmin?
    role&.name&.casecmp('superadmin')&.zero?
  end

  # Check if user is a field conductor
  # Field conductor only has work_orders.details.* permissions and nothing else
  def field_conductor?
    return false unless role&.permissions&.any?

    # Get all permission codes for the user's role
    permission_codes = role.permissions.pluck(:code)

    # Field conductor only has work_orders.details permissions
    # If there's any permission that doesn't start with 'work_orders.details', user is NOT a field conductor
    permission_codes.none? { |code| !code.start_with?('work_orders.details') }
  end

  # Clear cached permissions (call after role change)
  def clear_permission_cache!
    @permission_codes = nil
  end

  # Get the first accessible path for the user
  # Delegates to UserRedirectService to keep model lean
  def first_accessible_path
    UserRedirectService.first_accessible_path_for(self)
  end

  # Ransack configuration - excluding sensitive fields
  def self.ransackable_attributes(_auth_object = nil)
    %w[id name email is_active created_at updated_at role_id]
  end

  def self.ransackable_associations(_auth_object = nil)
    %w[role]
  end
end

# == Schema Information
#
# Table name: users
#
#  id                     :bigint           not null, primary key
#  email                  :string           default(""), not null
#  encrypted_password     :string           default(""), not null
#  is_active              :boolean          default(TRUE)
#  name                   :string
#  remember_created_at    :datetime
#  reset_password_sent_at :datetime
#  reset_password_token   :string
#  created_at             :datetime         not null
#  updated_at             :datetime         not null
#  role_id                :bigint
#
# Indexes
#
#  index_users_on_email                 (email) UNIQUE
#  index_users_on_reset_password_token  (reset_password_token) UNIQUE
#  index_users_on_role_id               (role_id)
#
# Foreign Keys
#
#  fk_rails_...  (role_id => roles.id)
#
