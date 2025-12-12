# frozen_string_literal: true

require 'test_helper'

module DeductionCalculators
  class PercentageCalculatorTest < ActiveSupport::TestCase
    setup do
      @deduction_type = deduction_types(:epf_foreign)
      @calculator = PercentageCalculator.new(@deduction_type)
    end

    # ============================================================================
    # INITIALIZATION TESTS
    # ============================================================================

    test 'should initialize with deduction_type' do
      assert_equal @deduction_type, @calculator.deduction_type
    end

    # ============================================================================
    # CALCULATION TESTS
    # ============================================================================

    test 'should calculate employee contribution correctly' do
      # EPF employee: 11%
      # 3500 * 11 / 100 = 385.00
      result = @calculator.calculate(3500, field: :employee_contribution)
      assert_equal BigDecimal('385.00'), result
    end

    test 'should calculate employer contribution correctly' do
      # EPF employer: 12%
      # 3500 * 12 / 100 = 420.00
      result = @calculator.calculate(3500, field: :employer_contribution)
      assert_equal BigDecimal('420.00'), result
    end

    test 'should round to 2 decimal places' do
      # 3333.33 * 11 / 100 = 366.6663 → 366.67
      result = @calculator.calculate(3333.33, field: :employee_contribution)
      assert_equal BigDecimal('366.67'), result
    end

    test 'should return zero when rate is nil' do
      @deduction_type.employee_contribution = nil
      result = @calculator.calculate(3500, field: :employee_contribution)
      assert_equal BigDecimal('0'), result
    end

    test 'should return zero when rate is zero' do
      @deduction_type.employee_contribution = 0
      result = @calculator.calculate(3500, field: :employee_contribution)
      assert_equal BigDecimal('0'), result
    end

    test 'should handle zero salary' do
      result = @calculator.calculate(0, field: :employee_contribution)
      assert_equal BigDecimal('0.0'), result
    end

    test 'should handle negative salary gracefully' do
      # While business logic should prevent this, calculator should handle it
      result = @calculator.calculate(-1000, field: :employee_contribution)
      assert_equal BigDecimal('-110.0'), result
    end

    # ============================================================================
    # REAL-WORLD SCENARIO TESTS
    # ============================================================================

    test 'EPF calculation for typical Malaysian salary RM 5000' do
      # Employee: 5000 * 11% = 550.00
      # Employer: 5000 * 12% = 600.00
      employee = @calculator.calculate(5000, field: :employee_contribution)
      employer = @calculator.calculate(5000, field: :employer_contribution)

      assert_equal BigDecimal('550.00'), employee
      assert_equal BigDecimal('600.00'), employer
    end

    test 'EPF calculation for minimum wage RM 1500' do
      # Employee: 1500 * 11% = 165.00
      # Employer: 1500 * 12% = 180.00
      employee = @calculator.calculate(1500, field: :employee_contribution)
      employer = @calculator.calculate(1500, field: :employer_contribution)

      assert_equal BigDecimal('165.00'), employee
      assert_equal BigDecimal('180.00'), employer
    end

    test 'SOCSO foreign worker calculation' do
      socso_foreign = DeductionType.create!(
        name: 'SOCSO Foreign Test',
        code: 'SOCSO_FOREIGN_TEST',
        calculation_type: 'percentage',
        employee_contribution: 1.25,
        employer_contribution: 1.25,
        is_active: true,
        applies_to_nationality: 'foreigner',
        effective_from: Date.new(2025, 1, 1)
      )
      calculator = PercentageCalculator.new(socso_foreign)

      # 3500 * 1.25% = 43.75
      employee = calculator.calculate(3500, field: :employee_contribution)
      employer = calculator.calculate(3500, field: :employer_contribution)

      assert_equal BigDecimal('43.75'), employee
      assert_equal BigDecimal('43.75'), employer
    end

    # ============================================================================
    # EDGE CASE TESTS
    # ============================================================================

    test 'should handle very large salary' do
      # 1,000,000 * 11% = 110,000.00
      result = @calculator.calculate(1_000_000, field: :employee_contribution)
      assert_equal BigDecimal('110000.00'), result
    end

    test 'should handle very small percentage' do
      @deduction_type.employee_contribution = 0.01
      # 3500 * 0.01% = 0.35
      result = @calculator.calculate(3500, field: :employee_contribution)
      assert_equal BigDecimal('0.35'), result
    end

    test 'should handle decimal salary amounts' do
      # 2567.89 * 11% = 282.47 (rounded)
      result = @calculator.calculate(2567.89, field: :employee_contribution)
      assert_equal BigDecimal('282.47'), result
    end
  end
end
