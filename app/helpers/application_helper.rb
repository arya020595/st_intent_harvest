module ApplicationHelper
  include Pagy::Frontend

  # Check if current page matches any of the given paths
  def active_nav_item?(*paths)
    paths.any? { |path| current_page?(path) }
  end

  # Check if current controller matches any of the given controller paths
  def active_controller?(*controllers)
    controllers.any? { |controller| controller_path.start_with?(controller) }
  end

  # Check if user has permission to view a menu item
  def can_view_menu?(subject, action = 'index')
    return true unless current_user # Show to guests (will be caught by authentication)
    return true if current_user.role&.name&.downcase == 'superadmin' # Superadmin sees all

    permission_checker = PermissionChecker.new(current_user)
    permission_checker.allowed?(action, subject)
  end
end
