# frozen_string_literal: true

module DeductionCalculators
  # Wage range-based deduction calculator
  # Looks up deduction amount from wage range table based on salary level
  #
  # Example: SOCSO local worker with salary RM 3,500
  #   1. Find matching range: min_wage=3000, max_wage=4000
  #   2. Return fixed amounts: employee=24.50, employer=63.00
  #
  # Wage ranges can use either:
  #   - Fixed amounts (most common for SOCSO local)
  #   - Percentage calculations (for future tiered percentage systems)
  #
  # Supports open-ended ranges: max_wage=NULL means "and above"
  class WageRangeCalculator < Base
    # Calculate deduction based on wage range lookup
    # @param gross_salary [BigDecimal] Worker's gross salary
    # @param field [Symbol] :employee_contribution or :employer_contribution
    # @return [BigDecimal] Deduction amount from matching wage range
    def calculate(gross_salary, field: :employee_contribution)
      # Find wage range that contains this salary
      wage_range = find_wage_range(gross_salary)

      # Return 0 if no matching range found
      return BigDecimal('0') unless wage_range

      # Delegate calculation to the wage range
      # The wage range knows whether to use fixed amount or percentage
      wage_range.calculate_for(gross_salary, field: normalize_field(field))
    end

    private

    # Find the wage range matching the gross salary
    # @param gross_salary [BigDecimal] Salary to match
    # @return [DeductionWageRange, nil] Matching range or nil
    def find_wage_range(gross_salary)
      deduction_type.deduction_wage_ranges.for_salary(gross_salary).first
    end

    # Normalize field name for wage range calculation
    # @param field [Symbol] :employee_contribution or :employer_contribution
    # @return [Symbol] :employee or :employer
    def normalize_field(field)
      field.to_s.include?('employee') ? :employee : :employer
    end
  end
end
