# frozen_string_literal: true

class PayslipPolicy < ApplicationPolicy
  # Permission codes:
  # - payslip.index
  # - payslip.show
  # - payslip.export

  def export?
    user.has_permission?(build_permission_code('export'))
  end

  private

  def permission_resource
    'payslip'
  end

  class Scope < ApplicationPolicy::Scope
    private

    def permission_resource
      'payslip'
    end
  end
end
