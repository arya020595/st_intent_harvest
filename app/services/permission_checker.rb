# frozen_string_literal: true

class PermissionChecker
  def initialize(user)
    @user = user
  end

  def allowed?(action, subject)
    return false unless user_has_role?
    
    permissions.exists?(action: action.to_s, subject: subject)
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
