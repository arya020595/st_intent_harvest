# frozen_string_literal: true

module DeductionCalculators
  # Percentage-based deduction calculator
  # Calculates deduction as percentage of gross salary
  #
  # SOLID Principles:
  # - Single Responsibility: Only calculates percentage-based deductions
  # - Open/Closed: Rounding behavior configured via deduction_type.rounding_precision and rounding_method
  # - Dependency Inversion: Depends on deduction_type abstraction, not hardcoded rules
  #
  # Example: EPF employee contribution = 11% of gross salary
  #   - Gross salary: RM 3,500.00
  #   - Employee rate: 11%
  #   - Calculation: 3500 × 11 ÷ 100 = RM 385 (rounded up to whole number for EPF)
  #
  # Example: SOCSO foreigner = 1.25% each for employee and employer
  #   - Gross salary: RM 3,500.00
  #   - Rate: 1.25%
  #   - Calculation: 3500 × 1.25 ÷ 100 = RM 43.75 (2 decimal places)
  class PercentageCalculator < Base
    # Calculate deduction as percentage of gross salary
    # @param gross_salary [BigDecimal] Worker's gross salary
    # @param field [Symbol] :employee_contribution or :employer_contribution
    # @return [BigDecimal] Calculated amount (rounded per deduction_type settings)
    def calculate(gross_salary, field: :employee_contribution)
      rate = contribution_rate(field)

      # Return 0 if rate is nil or zero
      return BigDecimal('0') unless valid_rate?(rate)

      # Calculate: (gross_salary × rate) ÷ 100
      raw_amount = gross_salary * rate / 100

      # Apply rounding based on deduction type configuration
      apply_rounding(raw_amount)
    end

    private

    # Apply rounding based on deduction type's configured method and precision
    # @param amount [BigDecimal] Raw calculated amount
    # @return [BigDecimal] Rounded amount
    def apply_rounding(amount)
      case rounding_method
      when 'ceil'
        # Round up: 50.20 → 51, 48.90 → 49
        (amount * (10**rounding_precision)).ceil.to_d / (10**rounding_precision)
      when 'floor'
        # Round down: 50.80 → 50
        (amount * (10**rounding_precision)).floor.to_d / (10**rounding_precision)
      else
        # Standard rounding: 50.50 → 51, 50.49 → 50
        amount.round(rounding_precision)
      end
    end

    # Get rounding precision from deduction type configuration
    # Always present due to NOT NULL database constraint with default of 2
    def rounding_precision
      deduction_type.rounding_precision
    end

    # Get rounding method from deduction type configuration
    # Options: 'round' (standard), 'ceil' (always up), 'floor' (always down)
    def rounding_method
      deduction_type.rounding_method
    end
  end
end
