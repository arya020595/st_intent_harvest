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
end
