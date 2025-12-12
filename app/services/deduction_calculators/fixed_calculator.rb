# frozen_string_literal: true

module DeductionCalculators
  # Fixed amount deduction calculator
  # Returns a constant deduction amount regardless of salary
  #
  # Example: EIS (Employment Insurance System)
  #   - Employee contribution: RM 7.90 (fixed)
  #   - Employer contribution: RM 7.90 (fixed)
  #   - Applies regardless of salary level
  #
  # Note: Fixed deductions are rare in Malaysian payroll
  # Most deductions use percentage or wage ranges
  class FixedCalculator < Base
    # Calculate fixed deduction amount
    # @param gross_salary [BigDecimal] Worker's gross salary (not used)
    # @param field [Symbol] :employee_contribution or :employer_contribution
    # @return [BigDecimal] Fixed contribution amount
    def calculate(_gross_salary, field: :employee_contribution)
      rate = contribution_rate(field)

      # Return 0 if rate is nil or zero
      return BigDecimal('0') unless valid_rate?(rate)

      # Return the fixed rate as-is
      rate
    end
  end
end
