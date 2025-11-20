# frozen_string_literal: true

class DashboardPolicy < ApplicationPolicy
  # Permission codes: dashboard.index

  private

  def permission_resource
    'dashboard'
  end

  class Scope < ApplicationPolicy::Scope
    def resolve
      scope
    end
  end
end
