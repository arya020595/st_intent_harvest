# frozen_string_literal: true

# Service to determine the appropriate redirect path for users after sign in
# Follows Single Responsibility Principle by handling only redirect logic
#
# SOLID Principles Applied:
# - Single Responsibility: Only handles redirect path determination
# - Open/Closed: Easy to extend with new paths without modifying User model
# - Dependency Inversion: User model depends on abstraction (service), not concrete implementation
#
# Convention-based Automatic Path Resolution:
# - Automatically converts permission codes to route helpers
# - Example: 'workers.index' → 'workers_path'
# - Example: 'work_orders.details.index' → 'work_orders_details_path'
# - Works with new modules automatically, no manual mapping needed
#
# Usage:
#   UserRedirectService.first_accessible_path_for(current_user)
#   # => :work_orders_details_path
#
# Benefits:
# - Keeps User model focused on user data and authentication
# - Easy to test in isolation
# - Automatically works with new modules
# - Clear separation of concerns
class UserRedirectService
  # Special case mappings for non-standard routes
  # Only needed when permission code doesn't match route helper convention
  SPECIAL_CASES = {
    'dashboard.index' => :root_path,
    'admin.users.index' => :user_management_users_path,
    'admin.roles.index' => :user_management_roles_path
  }.freeze

  # Priority order for permission types (prefer index actions)
  PERMISSION_PRIORITY = %w[
    dashboard
    work_orders
    payslip
    inventory
    workers
    master_data
    admin
  ].freeze

  def initialize(user)
    @user = user
  end

  # Returns the path symbol for the first accessible resource
  # @return [Symbol] Path helper method symbol (e.g., :root_path)
  def first_accessible_path
    return :root_path if @user.superadmin?

    # Get all user's index permissions sorted by priority
    index_permissions = user_index_permissions_sorted

    # Find first valid path
    index_permissions.each do |permission_code|
      path_symbol = resolve_path_for_permission(permission_code)
      return path_symbol if path_symbol
    end

    # Fallback to root if no specific permission found
    :root_path
  end

  # Class method for convenience
  def self.first_accessible_path_for(user)
    new(user).first_accessible_path
  end

  private

  # Get user's index permissions sorted by priority
  def user_index_permissions_sorted
    return [] unless @user.role

    # Get all permissions that end with .index
    all_permissions = @user.role.permissions.pluck(:code)
    index_permissions = all_permissions.select { |code| code.end_with?('.index') }

    # Sort by priority
    index_permissions.sort_by do |code|
      namespace = code.split('.').first
      PERMISSION_PRIORITY.index(namespace) || 999
    end
  end

  # Resolve path symbol for a permission code
  # Returns nil if path cannot be resolved
  def resolve_path_for_permission(permission_code)
    # Check special cases first
    return SPECIAL_CASES[permission_code] if SPECIAL_CASES.key?(permission_code)

    # Convert permission code to path helper
    # Example: 'workers.index' → :workers_path
    # Example: 'work_orders.details.index' → :work_orders_details_path
    path_symbol = permission_to_path_symbol(permission_code)

    # Verify the path helper exists in Rails routes
    path_symbol if path_helper_exists?(path_symbol)
  end

  # Convert permission code to path helper symbol
  # 'workers.index' → :workers_path
  # 'work_orders.details.index' → :work_orders_details_path
  # 'master_data.blocks.index' → :master_data_blocks_path
  def permission_to_path_symbol(permission_code)
    # Remove .index suffix
    resource_path = permission_code.sub(/\.index$/, '')

    # Replace dots with underscores for Rails route helpers
    resource_path = resource_path.tr('.', '_')

    # Convert to path helper format
    "#{resource_path}_path".to_sym
  end

  # Check if a path helper exists in Rails routes
  def path_helper_exists?(path_symbol)
    # Get Rails application routes
    Rails.application.routes.url_helpers.respond_to?(path_symbol)
  rescue StandardError
    false
  end
end
