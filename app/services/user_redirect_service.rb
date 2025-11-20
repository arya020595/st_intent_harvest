# frozen_string_literal: true

# Service to determine the appropriate redirect path for users after sign in
# Follows Single Responsibility Principle by handling only redirect logic
#
# SOLID Principles Applied:
# - Single Responsibility: Only handles redirect path determination
# - Open/Closed: Easy to extend with new paths without modifying User model
# - Dependency Inversion: User model depends on abstraction (service), not concrete implementation
#
# Usage:
#   UserRedirectService.first_accessible_path_for(current_user)
#   # => :work_orders_details_path
#
# Benefits:
# - Keeps User model focused on user data and authentication
# - Easy to test in isolation
# - Easy to modify path priority without touching User model
# - Clear separation of concerns
class UserRedirectService
  # Path mappings in order of preference
  # Format: [permission_code, path_symbol]
  PATH_MAPPINGS = [
    ['dashboard.index', :root_path],
    ['work_orders.details.index', :work_orders_details_path],
    ['work_orders.approvals.index', :work_orders_approvals_path],
    ['work_orders.pay_calculations.index', :work_orders_pay_calculations_path],
    ['payslip.index', :payslips_path],
    ['inventory.index', :inventories_path],
    ['workers.index', :workers_path],
    ['master_data.blocks.index', :master_data_blocks_path],
    ['master_data.categories.index', :master_data_categories_path],
    ['master_data.units.index', :master_data_units_path],
    ['master_data.vehicles.index', :master_data_vehicles_path],
    ['master_data.work_order_rates.index', :master_data_work_order_rates_path],
    ['admin.users.index', :user_management_users_path],
    ['admin.roles.index', :user_management_roles_path]
  ].freeze

  def initialize(user)
    @user = user
  end

  # Returns the path symbol for the first accessible resource
  # @return [Symbol] Path helper method symbol (e.g., :root_path)
  def first_accessible_path
    return :root_path if @user.superadmin?

    # Find first path user has access to
    PATH_MAPPINGS.each do |permission_code, path_symbol|
      return path_symbol if @user.has_permission?(permission_code)
    end

    # Fallback to root if no specific permission found
    :root_path
  end

  # Class method for convenience
  def self.first_accessible_path_for(user)
    new(user).first_accessible_path
  end
end
