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
    def calculate(gross_salary, field: :employee_contribution, age: nil)
      wage_range = find_wage_range(gross_salary, age)

      return BigDecimal('0') unless wage_range

      wage_range.calculate_for(gross_salary, field: normalize_field(field))
    end

    private

    def find_wage_range(gross_salary, age)
      ranges = deduction_type.deduction_wage_ranges.for_salary(gross_salary)

      if age.present?
        age_match = ranges.for_age(age)
        return age_match.first if age_match.exists?
      end

      # Fall back to age-agnostic rows (min_age IS NULL) for deduction types without age brackets
      ranges.where(min_age: nil).first
    end

    # Normalize field name for wage range calculation
    # @param field [Symbol] :employee_contribution or :employer_contribution
    # @return [Symbol] :employee or :employer
    def normalize_field(field)
      field.to_s.include?('employee') ? :employee : :employer
    end
  end
end
