# frozen_string_literal: true

module DeductionCalculators
  # Percentage-based deduction calculator
  # Calculates deduction as percentage of gross salary
  #
  # SOLID Principles:
  # - Single Responsibility: Only calculates percentage-based deductions
  # - Open/Closed: Rounding behavior configured via deduction_type.rounding_precision
  # - Dependency Inversion: Depends on deduction_type abstraction, not hardcoded rules
  #
  # Example: EPF employee contribution = 11% of gross salary
  #   - Gross salary: RM 3,500.00
  #   - Employee rate: 11%
  #   - Calculation: 3500 × 11 ÷ 100 = RM 385 (rounded to 0 decimals for EPF)
  #
  # Example: SOCSO foreigner = 1.25% each for employee and employer
  #   - Gross salary: RM 3,500.00
  #   - Rate: 1.25%
  #   - Calculation: 3500 × 1.25 ÷ 100 = RM 43.75 (2 decimal places)
  class PercentageCalculator < Base
    # Calculate deduction as percentage of gross salary
    # @param gross_salary [BigDecimal] Worker's gross salary
    # @param field [Symbol] :employee_contribution or :employer_contribution
    # @return [BigDecimal] Calculated amount (rounded per deduction_type.rounding_precision)
    def calculate(gross_salary, field: :employee_contribution)
      rate = contribution_rate(field)

      # Return 0 if rate is nil or zero
      return BigDecimal('0') unless valid_rate?(rate)

      # Calculate: (gross_salary × rate) ÷ 100
      # Round according to deduction type's configured precision
      (gross_salary * rate / 100).round(rounding_precision)
    end

    private

    # Get rounding precision from deduction type configuration
    # Always present due to NOT NULL database constraint with default of 2
    def rounding_precision
      deduction_type.rounding_precision
    end
  end
end
