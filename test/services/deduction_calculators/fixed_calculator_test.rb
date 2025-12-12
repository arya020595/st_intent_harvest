# frozen_string_literal: true

require 'test_helper'

module DeductionCalculators
  class FixedCalculatorTest < ActiveSupport::TestCase
    setup do
      # Create a fixed deduction type (e.g., EIS)
      @deduction_type = DeductionType.create!(
        name: 'EIS',
        code: 'EIS',
        description: 'Employment Insurance System',
        calculation_type: 'fixed',
        employee_contribution: 7.90,
        employer_contribution: 7.90,
        is_active: true,
        effective_from: Date.new(2025, 1, 1)
      )
      @calculator = FixedCalculator.new(@deduction_type)
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

    test 'should return fixed employee contribution regardless of salary' do
      result = @calculator.calculate(3500, field: :employee_contribution)
      assert_equal BigDecimal('7.90'), result
    end

    test 'should return fixed employer contribution regardless of salary' do
      result = @calculator.calculate(3500, field: :employer_contribution)
      assert_equal BigDecimal('7.90'), result
    end

    test 'should return same amount for different salaries' do
      result1 = @calculator.calculate(1000, field: :employee_contribution)
      result2 = @calculator.calculate(5000, field: :employee_contribution)
      result3 = @calculator.calculate(10_000, field: :employee_contribution)

      assert_equal result1, result2
      assert_equal result2, result3
      assert_equal BigDecimal('7.90'), result1
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
      assert_equal BigDecimal('7.90'), result
    end

    # ============================================================================
    # REAL-WORLD SCENARIO TESTS
    # ============================================================================

    test 'EIS calculation for various salaries' do
      # EIS should be fixed RM 7.90 for all salaries
      salaries = [1500, 3000, 5000, 10_000]

      salaries.each do |salary|
        employee = @calculator.calculate(salary, field: :employee_contribution)
        employer = @calculator.calculate(salary, field: :employer_contribution)

        assert_equal BigDecimal('7.90'), employee, "Employee contribution should be RM 7.90 for salary #{salary}"
        assert_equal BigDecimal('7.90'), employer, "Employer contribution should be RM 7.90 for salary #{salary}"
      end
    end

    test 'fixed deduction with different amounts for employee and employer' do
      @deduction_type.update!(
        employee_contribution: 10.00,
        employer_contribution: 15.00
      )

      employee = @calculator.calculate(3500, field: :employee_contribution)
      employer = @calculator.calculate(3500, field: :employer_contribution)

      assert_equal BigDecimal('10.00'), employee
      assert_equal BigDecimal('15.00'), employer
    end

    # ============================================================================
    # EDGE CASE TESTS
    # ============================================================================

    test 'should handle decimal fixed amounts' do
      @deduction_type.employee_contribution = 12.345
      result = @calculator.calculate(3500, field: :employee_contribution)
      # Result may be rounded due to database precision
      assert_in_delta BigDecimal('12.35'), result, 0.01
    end

    test 'should handle negative salary without affecting fixed amount' do
      # While business logic should prevent this, calculator should return fixed amount
      result = @calculator.calculate(-1000, field: :employee_contribution)
      assert_equal BigDecimal('7.90'), result
    end

    test 'should handle very large salary without affecting fixed amount' do
      result = @calculator.calculate(1_000_000, field: :employee_contribution)
      assert_equal BigDecimal('7.90'), result
    end
  end
end
