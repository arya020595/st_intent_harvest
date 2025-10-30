# frozen_string_literal: true

module UserManagement
  class RolePolicy < ApplicationPolicy
    # Inherits all default behavior from ApplicationPolicy

    class Scope < ApplicationPolicy::Scope
      # Inherits default scope behavior
    end
  end
end
