# frozen_string_literal: true

module PayCalculationServices
  class DeductionCalculator
    DeductionResult = Struct.new(:deduction_breakdown, :employee_deduction, :employer_deduction, keyword_init: true)

    VALID_NATIONALITIES = %w[local foreigner foreigner_no_passport].freeze

    class << self
      # Calculate deductions for a specific month and worker
      # Uses deduction types that were active on the first day of that month
      # @param month_year [String, nil] Month in format "YYYY-MM" (e.g., "2025-11"), defaults to current month
      # @param gross_salary [BigDecimal, Float, Integer] Worker's gross salary for percentage calculations
      # @param nationality [String] Worker's nationality ('local' or 'foreigner') for nationality-specific deductions
      # @return [DeductionResult]
      # @raise [ArgumentError] if gross_salary is negative or nationality is invalid
      def calculate(month_year = nil, gross_salary: 0, nationality: 'local')
        # Validate inputs
        validate_inputs!(gross_salary, nationality)

        # Normalize nationality to lowercase
        nationality = nationality.to_s.downcase

        target_date = parse_target_date(month_year)
        gross_salary = BigDecimal(gross_salary.to_s)

        deduction_types = DeductionType.active_on(target_date)
                                       .for_nationality(nationality)

        breakdown = {}
        employee_total = BigDecimal('0')
        employer_total = BigDecimal('0')

        deduction_types.each do |deduction_type|
          employee_amt = deduction_type.calculate_amount(gross_salary, field: :employee_contribution)
          employer_amt = deduction_type.calculate_amount(gross_salary, field: :employer_contribution)

          breakdown[deduction_type.code] = build_deduction_entry(
            deduction_type,
            employee_amt,
            employer_amt,
            gross_salary,
            nationality
          )

          employee_total += employee_amt
          employer_total += employer_amt
        end

        DeductionResult.new(
          deduction_breakdown: breakdown,
          employee_deduction: employee_total.round(2),
          employer_deduction: employer_total.round(2)
        )
      end

      private

      def validate_inputs!(gross_salary, nationality)
        raise ArgumentError, 'Gross salary cannot be negative' if gross_salary.to_f.negative?

        normalized_nationality = nationality.to_s.downcase
        return if VALID_NATIONALITIES.include?(normalized_nationality)

        raise ArgumentError, "Invalid nationality: #{nationality}. Must be one of: #{VALID_NATIONALITIES.join(', ')}"
      end

      def parse_target_date(month_year)
        return Date.current unless month_year

        Date.parse("#{month_year}-01")
      rescue ArgumentError
        raise ArgumentError, "Invalid month_year format: #{month_year}. Expected format: YYYY-MM"
      end

      def build_deduction_entry(deduction_type, employee_amt, employer_amt, gross_salary, nationality)
        {
          'name' => deduction_type.name,
          'calculation_type' => deduction_type.calculation_type,
          'employee_rate' => deduction_type.employee_contribution.to_f,
          'employer_rate' => deduction_type.employer_contribution.to_f,
          'employee_amount' => employee_amt.to_f,
          'employer_amount' => employer_amt.to_f,
          'gross_salary' => gross_salary.to_f,
          'nationality' => nationality,
          'applies_to_nationality' => deduction_type.applies_to_nationality,
          'rounding_precision' => deduction_type.rounding_precision
        }
      end
    end
  end
end
