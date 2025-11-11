# frozen_string_literal: true

class DashboardPolicy < ApplicationPolicy
  # Example: authorize :dashboard, :index?
  # Seeds expected (subject: "Dashboard"):
  #   Permission.create!(action: "index", subject: "Dashboard")
  #   Permission.create!(action: "show", subject: "Dashboard")

  def index?
    has_permission?(:index)
  end

  def show?
    has_permission?(:show)
  end

  # Add more dashboard-specific actions as needed, for example:
  # def export?
  #   has_permission?(:export)
  # end

  class Scope < ApplicationPolicy::Scope
    # For headless resources, scope is usually not used.
    # You can return a PORO collection or leave as-is.
    def resolve
      scope
    end
  end
end
