# frozen_string_literal: true

class PermissionChecker
  def initialize(user)
    @user = user
  end

  def allowed?(action, subject)
    # Superadmin bypass: allow everything
    return true if superadmin?
    return false unless user_has_role?
    
    permissions.exists?(action: action.to_s, subject: subject)
  end

  # Public method - can be used in policies for scope filtering
  def superadmin?
    # Case-insensitive match on role name 'Superadmin'
    @user&.role&.name&.downcase == 'superadmin'
  end

  private

  attr_reader :user

  def user_has_role?
    @user&.role.present?
  end

  def permissions
    @permissions ||= @user.role.permissions
  end
end
