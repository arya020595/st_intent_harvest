# frozen_string_literal: true

class PayslipPolicy < ApplicationPolicy
  # Inherits all default behavior from ApplicationPolicy

  def export?
    has_permission?(:export)
  end

  class Scope < ApplicationPolicy::Scope
    # Inherits default scope behavior
  end
end
