# frozen_string_literal: true

require 'test_helper'

module DeductionCalculators
  class WageRangeCalculatorTest < ActiveSupport::TestCase
    setup do
      # Clean up any existing wage ranges to avoid conflicts
      DeductionWageRange.delete_all

      @deduction_type = deduction_types(:socso)
      @calculator = WageRangeCalculator.new(@deduction_type)

      # Create test wage ranges
      @range1 = DeductionWageRange.create!(
        deduction_type: @deduction_type,
        min_wage: 1000.00,
        max_wage: 2000.00,
        employee_amount: 10.00,
        employer_amount: 20.00,
        calculation_method: 'fixed'
      )

      @range2 = DeductionWageRange.create!(
        deduction_type: @deduction_type,
        min_wage: 2000.01,
        max_wage: 3000.00,
        employee_amount: 15.00,
        employer_amount: 30.00,
        calculation_method: 'fixed'
      )

      @range3 = DeductionWageRange.create!(
        deduction_type: @deduction_type,
        min_wage: 3000.01,
        max_wage: 4000.00,
        employee_amount: 20.00,
        employer_amount: 40.00,
        calculation_method: 'fixed'
      )

      # Open-ended range
      @range_open = DeductionWageRange.create!(
        deduction_type: @deduction_type,
        min_wage: 4000.01,
        max_wage: nil,
        employee_amount: 25.00,
        employer_amount: 50.00,
        calculation_method: 'fixed'
      )
    end

    # ============================================================================
    # INITIALIZATION TESTS
    # ============================================================================

    test 'should initialize with deduction_type' do
      assert_equal @deduction_type, @calculator.deduction_type
    end

    # ============================================================================
    # CALCULATION TESTS - FIXED AMOUNTS
    # ============================================================================

    test 'should calculate employee contribution for salary in first range' do
      result = @calculator.calculate(1500, field: :employee_contribution)
      assert_equal BigDecimal('10.00'), result
    end

    test 'should calculate employer contribution for salary in first range' do
      result = @calculator.calculate(1500, field: :employer_contribution)
      assert_equal BigDecimal('20.00'), result
    end

    test 'should calculate employee contribution for salary in second range' do
      result = @calculator.calculate(2500, field: :employee_contribution)
      assert_equal BigDecimal('15.00'), result
    end

    test 'should calculate employee contribution for salary in third range' do
      result = @calculator.calculate(3500, field: :employee_contribution)
      assert_equal BigDecimal('20.00'), result
    end

    test 'should calculate employee contribution for salary in open-ended range' do
      result = @calculator.calculate(10_000, field: :employee_contribution)
      assert_equal BigDecimal('25.00'), result
    end

    test 'should return zero when no range matches' do
      result = @calculator.calculate(500, field: :employee_contribution)
      assert_equal BigDecimal('0'), result
    end

    # ============================================================================
    # BOUNDARY TESTS
    # ============================================================================

    test 'should handle salary at exact min_wage boundary' do
      result = @calculator.calculate(1000.00, field: :employee_contribution)
      assert_equal BigDecimal('10.00'), result
    end

    test 'should handle salary at exact max_wage boundary' do
      result = @calculator.calculate(2000.00, field: :employee_contribution)
      assert_equal BigDecimal('10.00'), result
    end

    test 'should handle salary just above range boundary' do
      result = @calculator.calculate(2000.01, field: :employee_contribution)
      assert_equal BigDecimal('15.00'), result
    end

    test 'should handle salary at open-ended range start' do
      result = @calculator.calculate(4000.01, field: :employee_contribution)
      assert_equal BigDecimal('25.00'), result
    end

    # ============================================================================
    # PERCENTAGE CALCULATION TESTS
    # ============================================================================

    test 'should calculate percentage within wage range' do
      # Clear existing ranges first
      DeductionWageRange.where(deduction_type: @deduction_type).delete_all

      DeductionWageRange.create!(
        deduction_type: @deduction_type,
        min_wage: 5000.00,
        max_wage: 6000.00,
        employee_percentage: 2.5,
        employer_percentage: 5.0,
        calculation_method: 'percentage'
      )

      # 5500 * 2.5% = 137.50
      result = @calculator.calculate(5500, field: :employee_contribution)
      assert_equal BigDecimal('137.50'), result
    end

    test 'should calculate employer percentage within wage range' do
      # Clear existing ranges first
      DeductionWageRange.where(deduction_type: @deduction_type).delete_all

      DeductionWageRange.create!(
        deduction_type: @deduction_type,
        min_wage: 5000.00,
        max_wage: 6000.00,
        employee_percentage: 2.5,
        employer_percentage: 5.0,
        calculation_method: 'percentage'
      )

      # 5500 * 5.0% = 275.00
      result = @calculator.calculate(5500, field: :employer_contribution)
      assert_equal BigDecimal('275.00'), result
    end

    # ============================================================================
    # REAL-WORLD SCENARIO TESTS - SOCSO LOCAL
    # ============================================================================

    test 'SOCSO local worker - salary RM 1500' do
      # Clear existing ranges first
      DeductionWageRange.where(deduction_type: @deduction_type).delete_all

      # Create actual SOCSO range
      DeductionWageRange.create!(
        deduction_type: @deduction_type,
        min_wage: 1400.01,
        max_wage: 1500.00,
        employee_amount: 7.25,
        employer_amount: 25.35,
        calculation_method: 'fixed'
      )

      employee = @calculator.calculate(1500, field: :employee_contribution)
      employer = @calculator.calculate(1500, field: :employer_contribution)

      assert_equal BigDecimal('7.25'), employee
      assert_equal BigDecimal('25.35'), employer
    end

    test 'SOCSO local worker - salary RM 3500' do
      # Clear existing ranges first
      DeductionWageRange.where(deduction_type: @deduction_type).delete_all

      # Create actual SOCSO range
      DeductionWageRange.create!(
        deduction_type: @deduction_type,
        min_wage: 3400.01,
        max_wage: 3500.00,
        employee_amount: 17.25,
        employer_amount: 60.35,
        calculation_method: 'fixed'
      )

      employee = @calculator.calculate(3500, field: :employee_contribution)
      employer = @calculator.calculate(3500, field: :employer_contribution)

      assert_equal BigDecimal('17.25'), employee
      assert_equal BigDecimal('60.35'), employer
    end

    test 'SOCSO local worker - salary above maximum (RM 4500)' do
      # Range 4000.01 and above already created in setup
      employee = @calculator.calculate(4500, field: :employee_contribution)
      employer = @calculator.calculate(4500, field: :employer_contribution)

      assert_equal BigDecimal('25.00'), employee
      assert_equal BigDecimal('50.00'), employer
    end

    test 'SOCSO local worker - salary below minimum (RM 100)' do
      # Create minimum range
      DeductionWageRange.create!(
        deduction_type: @deduction_type,
        min_wage: 0.00,
        max_wage: 30.00,
        employee_amount: 0.10,
        employer_amount: 0.40,
        calculation_method: 'fixed'
      )

      employee = @calculator.calculate(20, field: :employee_contribution)
      employer = @calculator.calculate(20, field: :employer_contribution)

      assert_equal BigDecimal('0.10'), employee
      assert_equal BigDecimal('0.40'), employer
    end

    # ============================================================================
    # EDGE CASE TESTS
    # ============================================================================

    test 'should handle zero salary when range starts at zero' do
      DeductionWageRange.create!(
        deduction_type: @deduction_type,
        min_wage: 0.00,
        max_wage: 100.00,
        employee_amount: 0.50,
        employer_amount: 1.00,
        calculation_method: 'fixed'
      )

      result = @calculator.calculate(0, field: :employee_contribution)
      assert_equal BigDecimal('0.50'), result
    end

    test 'should handle decimal salary amounts' do
      result = @calculator.calculate(1567.89, field: :employee_contribution)
      assert_equal BigDecimal('10.00'), result
    end

    test 'should handle very large salary in open-ended range' do
      result = @calculator.calculate(1_000_000, field: :employee_contribution)
      assert_equal BigDecimal('25.00'), result
    end

    test 'should return zero when deduction_type has no wage ranges' do
      empty_deduction = DeductionType.create!(
        name: 'Empty',
        code: 'EMPTY',
        calculation_type: 'wage_range',
        is_active: true,
        effective_from: Date.new(2025, 1, 1)
      )
      empty_calculator = WageRangeCalculator.new(empty_deduction)

      result = empty_calculator.calculate(3500, field: :employee_contribution)
      assert_equal BigDecimal('0'), result
    end

    # ============================================================================
    # MULTIPLE RANGES TESTS
    # ============================================================================

    test 'should find correct range among multiple overlapping possibilities' do
      # Ensure only one range matches
      result1 = @calculator.calculate(1999.99, field: :employee_contribution)
      result2 = @calculator.calculate(2000.00, field: :employee_contribution)
      result3 = @calculator.calculate(2000.01, field: :employee_contribution)

      assert_equal BigDecimal('10.00'), result1
      assert_equal BigDecimal('10.00'), result2
      assert_equal BigDecimal('15.00'), result3
    end

    test 'should handle ranges with decimal boundaries' do
      # Clear existing ranges first
      DeductionWageRange.where(deduction_type: @deduction_type).delete_all

      DeductionWageRange.create!(
        deduction_type: @deduction_type,
        min_wage: 2567.89,
        max_wage: 2999.99,
        employee_amount: 14.50,
        employer_amount: 29.00,
        calculation_method: 'fixed'
      )

      result = @calculator.calculate(2800.50, field: :employee_contribution)
      assert_equal BigDecimal('14.50'), result
    end
  end
end
