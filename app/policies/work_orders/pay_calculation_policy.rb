# frozen_string_literal: true

module WorkOrders
  class PayCalculationPolicy < ApplicationPolicy
    # Inherits all default behavior from ApplicationPolicy

    # Allow viewing worker details (same permission as show)
    def worker_detail?
      show?
    end

    class Scope < ApplicationPolicy::Scope
      # Inherits default scope behavior
    end
  end
end
