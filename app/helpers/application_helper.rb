# frozen_string_literal: true

module ApplicationHelper
  include RansackMultiSortHelper
  include Pagy::Method

  # Check if current page matches any of the given paths
  def active_nav_item?(*paths)
    paths.any? { |path| current_page?(path) }
  end

  # Check if current controller matches any of the given controller paths
  def active_controller?(*controllers)
    controllers.any? { |controller| controller_path.start_with?(controller) }
  end

  # Check if user has permission to view a menu item
  # @param permission_code [String] Full permission code (e.g., 'admin.users.index')
  def can_view_menu?(permission_code)
    return true unless current_user # Show to guests (will be caught by authentication)

    current_user.has_permission?(permission_code)
  end

  # Returns a policy instance for the given record and policy class
  # This follows the Single Responsibility Principle by centralizing policy instantiation
  # and makes it easy to reuse across the entire application
  #
  # @param record [ActiveRecord::Base] the record to authorize
  # @param policy_class [Class] the policy class to use
  # @return [ApplicationPolicy] policy instance
  #
  # Example usage in views:
  #   <% policy = record_policy(work_order, WorkOrders::DetailPolicy) %>
  #   <% if policy.edit? %>
  #     <%= link_to "Edit", edit_path(work_order) %>
  #   <% end %>
  def record_policy(record, policy_class)
    policy_class.new(current_user, record)
  end
end
