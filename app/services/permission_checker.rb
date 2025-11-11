# frozen_string_literal: true

class PermissionChecker
  def initialize(user)
    @user = user
  end

  def allowed?(action, subject)
    # Superadmin bypass: allow everything
    return true if superadmin?
    return false unless user_has_role?

    permissions.include?([action.to_s, subject.to_s])
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
    @permissions ||= @user.role.permissions.pluck(:action, :subject).map { |a, s| [a.to_s, s.to_s] }.to_set
  end
end
