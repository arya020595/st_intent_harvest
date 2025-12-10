# frozen_string_literal: true

class PayslipPolicy < ApplicationPolicy
  # Permission codes:
  # - payslip.index
  # - payslip.show
  # - payslip.export

  def show?
    index?
  end

  private

  def permission_resource
    'payslip'
  end

  class Scope < ApplicationPolicy::Scope
    # Inherits default scope behavior

    private

    def permission_resource
      'payslip'
    end
  end
end
