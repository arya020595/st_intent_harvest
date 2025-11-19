# frozen_string_literal: true

require 'test_helper'

module PayCalculationServices
  class DeductionCalculatorTest < ActiveSupport::TestCase
    def setup
      # Clean up existing deduction types
      DeductionType.delete_all

      @effective_date = Date.parse('2025-01-01')

      # Create standard Malaysian deductions
      @epf = DeductionType.create!(
        code: 'EPF',
        name: 'Employees Provident Fund',
        employee_contribution: 11.0,
        employer_contribution: 12.0,
        calculation_type: 'percentage',
        applies_to_nationality: 'all',
        is_active: true,
        effective_from: @effective_date
      )

      @socso_malaysian = DeductionType.create!(
        code: 'SOCSO_MALAYSIAN',
        name: 'SOCSO Malaysian',
        employee_contribution: 0.5,
        employer_contribution: 1.75,
        calculation_type: 'percentage',
        applies_to_nationality: 'local',
        is_active: true,
        effective_from: @effective_date
      )

      @socso_foreign = DeductionType.create!(
        code: 'SOCSO_FOREIGN',
        name: 'SOCSO Foreign',
        employee_contribution: 0.0,
        employer_contribution: 1.25,
        calculation_type: 'percentage',
        applies_to_nationality: 'foreigner',
        is_active: true,
        effective_from: @effective_date
      )

      @sip = DeductionType.create!(
        code: 'SIP',
        name: 'SIP',
        employee_contribution: 0.2,
        employer_contribution: 0.2,
        calculation_type: 'percentage',
        applies_to_nationality: 'local',
        is_active: true,
        effective_from: @effective_date
      )
    end

    # ============================================================================
    # MALAYSIAN WORKER CALCULATIONS
    # ============================================================================

    test 'should calculate correct deductions for Malaysian worker with RM 3000 salary' do
      result = DeductionCalculator.calculate(
        '2025-01',
        gross_salary: 3000,
        nationality: 'Local'
      )

      # EPF: 11% = 330.00
      # SOCSO: 0.5% = 15.00
      # SIP: 0.2% = 6.00
      # Total worker: 351.00
      assert_equal 351.0, result.employee_deduction

      # EPF: 12% = 360.00
      # SOCSO: 1.75% = 52.50
      # SIP: 0.2% = 6.00
      # Total employer: 418.50
      assert_equal 418.5, result.employer_deduction

      assert_equal 3, result.deduction_breakdown.size
      assert_includes result.deduction_breakdown.keys, 'EPF'
      assert_includes result.deduction_breakdown.keys, 'SOCSO_MALAYSIAN'
      assert_includes result.deduction_breakdown.keys, 'SIP'
    end

    test 'should calculate correct deductions for Malaysian worker with RM 5000 salary' do
      result = DeductionCalculator.calculate(
        '2025-01',
        gross_salary: 5000,
        nationality: 'Local'
      )

      # EPF: 11% = 550.00
      # SOCSO: 0.5% = 25.00
      # SIP: 0.2% = 10.00
      # Total worker: 585.00
      assert_equal 585.0, result.employee_deduction

      # EPF: 12% = 600.00
      # SOCSO: 1.75% = 87.50
      # SIP: 0.2% = 10.00
      # Total employer: 697.50
      assert_equal 697.5, result.employer_deduction
    end

    test 'should calculate correct deductions for Malaysian worker with RM 2000 salary' do
      result = DeductionCalculator.calculate(
        '2025-01',
        gross_salary: 2000,
        nationality: 'Local'
      )

      # EPF: 11% = 220.00
      # SOCSO: 0.5% = 10.00
      # SIP: 0.2% = 4.00
      # Total worker: 234.00
      assert_equal 234.0, result.employee_deduction

      # EPF: 12% = 240.00
      # SOCSO: 1.75% = 35.00
      # SIP: 0.2% = 4.00
      # Total employer: 279.00
      assert_equal 279.0, result.employer_deduction
    end

    # ============================================================================
    # FOREIGN WORKER CALCULATIONS
    # ============================================================================

    test 'should calculate correct deductions for Foreign worker with RM 3000 salary' do
      result = DeductionCalculator.calculate(
        '2025-01',
        gross_salary: 3000,
        nationality: 'Foreigner'
      )

      # EPF: 11% = 330.00
      # SOCSO: 0% = 0.00
      # Total worker: 330.00
      assert_equal 330.0, result.employee_deduction

      # EPF: 12% = 360.00
      # SOCSO: 1.25% = 37.50
      # Total employer: 397.50
      assert_equal 397.5, result.employer_deduction

      assert_equal 2, result.deduction_breakdown.size
      assert_includes result.deduction_breakdown.keys, 'EPF'
      assert_includes result.deduction_breakdown.keys, 'SOCSO_FOREIGN'
      assert_not_includes result.deduction_breakdown.keys, 'SIP'
    end

    test 'should calculate correct deductions for Foreign worker with RM 5000 salary' do
      result = DeductionCalculator.calculate(
        '2025-01',
        gross_salary: 5000,
        nationality: 'Foreigner'
      )

      # EPF: 11% = 550.00
      # SOCSO: 0% = 0.00
      # Total worker: 550.00
      assert_equal 550.0, result.employee_deduction

      # EPF: 12% = 600.00
      # SOCSO: 1.25% = 62.50
      # Total employer: 662.50
      assert_equal 662.5, result.employer_deduction
    end

    # ============================================================================
    # BREAKDOWN STRUCTURE
    # ============================================================================

    test 'should include correct breakdown structure for Malaysian worker' do
      result = DeductionCalculator.calculate(
        '2025-01',
        gross_salary: 3000,
        nationality: 'Local'
      )

      epf_breakdown = result.deduction_breakdown['EPF']
      assert_equal 11.0, epf_breakdown['employee_rate']
      assert_equal 12.0, epf_breakdown['employer_rate']
      assert_equal 330.0, epf_breakdown['employee_amount']
      assert_equal 360.0, epf_breakdown['employer_amount']
      assert_equal 3000, epf_breakdown['gross_salary']
      assert_equal 'local', epf_breakdown['nationality']

      socso_breakdown = result.deduction_breakdown['SOCSO_MALAYSIAN']
      assert_equal 0.5, socso_breakdown['employee_rate']
      assert_equal 1.75, socso_breakdown['employer_rate']
      assert_equal 15.0, socso_breakdown['employee_amount']
      assert_equal 52.5, socso_breakdown['employer_amount']

      sip_breakdown = result.deduction_breakdown['SIP']
      assert_equal 0.2, sip_breakdown['employee_rate']
      assert_equal 0.2, sip_breakdown['employer_rate']
      assert_equal 6.0, sip_breakdown['employee_amount']
      assert_equal 6.0, sip_breakdown['employer_amount']
    end

    test 'should include correct breakdown structure for Foreign worker' do
      result = DeductionCalculator.calculate(
        '2025-01',
        gross_salary: 3000,
        nationality: 'Foreigner'
      )

      epf_breakdown = result.deduction_breakdown['EPF']
      assert_equal 330.0, epf_breakdown['employee_amount']
      assert_equal 360.0, epf_breakdown['employer_amount']
      assert_equal 'foreigner', epf_breakdown['nationality']

      socso_breakdown = result.deduction_breakdown['SOCSO_FOREIGN']
      assert_equal 0.0, socso_breakdown['employee_amount']
      assert_equal 37.5, socso_breakdown['employer_amount']

      assert_nil result.deduction_breakdown['SIP']
      assert_nil result.deduction_breakdown['SOCSO_MALAYSIAN']
    end

    # ============================================================================
    # EFFECTIVE DATE HANDLING
    # ============================================================================

    test 'should use deductions active for specific month' do
      # Update old EPF to have end date
      @epf.update!(effective_until: Date.parse('2025-02-28'))

      # Create new EPF rate effective from March 2025
      DeductionType.create!(
        code: 'EPF',
        name: 'EPF New Rate',
        employee_contribution: 9.0,
        employer_contribution: 12.0,
        calculation_type: 'percentage',
        applies_to_nationality: 'all',
        is_active: true,
        effective_from: Date.parse('2025-03-01')
      )

      # Calculate for January (should use old rate)
      result_jan = DeductionCalculator.calculate(
        '2025-01',
        gross_salary: 3000,
        nationality: 'Local'
      )

      epf_jan = result_jan.deduction_breakdown['EPF']
      assert_equal 11.0, epf_jan['employee_rate']

      # Calculate for March (should use new rate)
      result_mar = DeductionCalculator.calculate(
        '2025-03',
        gross_salary: 3000,
        nationality: 'Local'
      )

      epf_mar = result_mar.deduction_breakdown['EPF']
      assert_equal 9.0, epf_mar['employee_rate']
      assert_equal 270.0, epf_mar['employee_amount'] # 3000 * 9% = 270
    end

    test 'should use current month when month_year is nil' do
      travel_to Date.parse('2025-01-15') do
        result = DeductionCalculator.calculate(
          nil,
          gross_salary: 3000,
          nationality: 'Local'
        )

        assert_equal 351.0, result.employee_deduction
      end
    end

    # ============================================================================
    # EDGE CASES
    # ============================================================================

    test 'should handle zero salary' do
      result = DeductionCalculator.calculate(
        '2025-01',
        gross_salary: 0,
        nationality: 'Local'
      )

      assert_equal 0, result.employee_deduction
      assert_equal 0, result.employee_deduction
    end

    test 'should handle very large salary' do
      result = DeductionCalculator.calculate(
        '2025-01',
        gross_salary: 100_000,
        nationality: 'Local'
      )

      # EPF: 11% = 11,000.00
      # SOCSO: 0.5% = 500.00
      # SIP: 0.2% = 200.00
      # Total: 11,700.00
      assert_equal 11_700.0, result.employee_deduction
    end

    test 'should handle salary with decimals' do
      result = DeductionCalculator.calculate(
        '2025-01',
        gross_salary: 3333.33,
        nationality: 'Local'
      )

      # EPF: 11% = 366.67
      # SOCSO: 0.5% = 16.67
      # SIP: 0.2% = 6.67
      # Total: 390.01
      assert_equal 390.01, result.employee_deduction
    end

    test 'should default nationality to malaysian if not provided' do
      result = DeductionCalculator.calculate(
        '2025-01',
        gross_salary: 3000,
        nationality: 'Local'
      )

      result_default = DeductionCalculator.calculate(
        '2025-01',
        gross_salary: 3000
      )

      assert_equal result.employee_deduction, result_default.employee_deduction
      assert_equal result.employee_deduction, result_default.employee_deduction
    end

    test 'should handle inactive deductions' do
      @sip.update!(is_active: false)

      result = DeductionCalculator.calculate(
        '2025-01',
        gross_salary: 3000,
        nationality: 'Local'
      )

      # Should only have EPF and SOCSO, no SIP
      assert_equal 2, result.deduction_breakdown.size
      assert_not_includes result.deduction_breakdown.keys, 'SIP'

      # EPF: 330.00 + SOCSO: 15.00 = 345.00
      assert_equal 345.0, result.employee_deduction
    end

    test 'should return empty breakdown when no deductions available' do
      DeductionType.update_all(is_active: false)

      result = DeductionCalculator.calculate(
        '2025-01',
        gross_salary: 3000,
        nationality: 'Local'
      )

      assert_equal 0, result.employee_deduction
      assert_equal 0, result.employee_deduction
      assert_empty result.deduction_breakdown
    end

    # ============================================================================
    # PRECISION AND ROUNDING
    # ============================================================================

    test 'should round calculations to 2 decimal places' do
      result = DeductionCalculator.calculate(
        '2025-01',
        gross_salary: 3333.33,
        nationality: 'Local'
      )

      result.deduction_breakdown.each do |_code, data|
        employee_amount = data['employee_amount']
        employer_amount = data['employer_amount']

        # Check each amount has at most 2 decimal places
        assert_equal employee_amount, employee_amount.round(2)
        assert_equal employer_amount, employer_amount.round(2)
      end
    end

    test 'should use BigDecimal for precise calculations' do
      # Test that calculations don't suffer from float precision issues
      result = DeductionCalculator.calculate(
        '2025-01',
        gross_salary: 3000.01,
        nationality: 'Local'
      )

      # EPF should be exactly 3000.01 * 11 / 100 = 330.0011 rounded to 330.00
      epf = result.deduction_breakdown['EPF']
      assert_equal 330.0, epf['employee_amount']
    end

    # ============================================================================
    # FIXED CALCULATION TYPE
    # ============================================================================

    test 'should handle fixed calculation type' do
      DeductionType.create!(
        code: 'FIXED_ALLOWANCE',
        name: 'Fixed Allowance',
        employee_contribution: 100.0,
        employer_contribution: 200.0,
        calculation_type: 'fixed',
        applies_to_nationality: 'all',
        is_active: true,
        effective_from: @effective_date
      )

      result = DeductionCalculator.calculate(
        '2025-01',
        gross_salary: 3000,
        nationality: 'Local'
      )

      fixed = result.deduction_breakdown['FIXED_ALLOWANCE']
      assert_equal 100.0, fixed['employee_amount'] # Should be fixed amount
      assert_equal 200.0, fixed['employer_amount']
    end
  end
end
