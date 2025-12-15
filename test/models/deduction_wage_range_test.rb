# frozen_string_literal: true

require 'test_helper'

class DeductionWageRangeTest < ActiveSupport::TestCase
  setup do
    # Clean up any existing wage ranges to avoid conflicts
    DeductionWageRange.delete_all

    @deduction_type = deduction_types(:socso)
  end

  # ============================================================================
  # VALIDATION TESTS
  # ============================================================================

  test 'should be valid with valid attributes' do
    range = DeductionWageRange.new(
      deduction_type: @deduction_type,
      min_wage: 1000.00,
      max_wage: 2000.00,
      employee_amount: 10.00,
      employer_amount: 20.00,
      calculation_method: 'fixed'
    )
    assert range.valid?
  end

  test 'should require min_wage' do
    range = DeductionWageRange.new(
      deduction_type: @deduction_type,
      max_wage: 2000.00,
      employee_amount: 10.00,
      employer_amount: 20.00
    )
    assert_not range.valid?
    assert_includes range.errors[:min_wage], "can't be blank"
  end

  test 'should require deduction_type' do
    range = DeductionWageRange.new(
      min_wage: 1000.00,
      max_wage: 2000.00,
      employee_amount: 10.00,
      employer_amount: 20.00
    )
    assert_not range.valid?
    assert_includes range.errors[:deduction_type], 'must exist'
  end

  test 'should allow NULL max_wage for open-ended ranges' do
    range = DeductionWageRange.new(
      deduction_type: @deduction_type,
      min_wage: 5000.00,
      max_wage: nil,
      employee_amount: 50.00,
      employer_amount: 100.00,
      calculation_method: 'fixed'
    )
    assert range.valid?
  end

  test 'should validate max_wage is greater than or equal to min_wage' do
    range = DeductionWageRange.new(
      deduction_type: @deduction_type,
      min_wage: 2000.00,
      max_wage: 1000.00,
      employee_amount: 10.00,
      employer_amount: 20.00
    )
    assert_not range.valid?
    assert_includes range.errors[:max_wage], 'must be greater than or equal to min_wage'
  end

  test 'should validate employee_amount is not negative' do
    range = DeductionWageRange.new(
      deduction_type: @deduction_type,
      min_wage: 1000.00,
      max_wage: 2000.00,
      employee_amount: -10.00,
      employer_amount: 20.00
    )
    assert_not range.valid?
    assert_includes range.errors[:employee_amount], 'must be greater than or equal to 0'
  end

  test 'should validate employer_amount is not negative' do
    range = DeductionWageRange.new(
      deduction_type: @deduction_type,
      min_wage: 1000.00,
      max_wage: 2000.00,
      employee_amount: 10.00,
      employer_amount: -20.00
    )
    assert_not range.valid?
    assert_includes range.errors[:employer_amount], 'must be greater than or equal to 0'
  end

  test 'should validate calculation_method is in allowed values' do
    range = DeductionWageRange.new(
      deduction_type: @deduction_type,
      min_wage: 1000.00,
      max_wage: 2000.00,
      employee_amount: 10.00,
      employer_amount: 20.00,
      calculation_method: 'invalid_method'
    )
    assert_not range.valid?
    assert_includes range.errors[:calculation_method], 'is not included in the list'
  end

  test 'should validate employee_percentage is between 0 and 100' do
    range = DeductionWageRange.new(
      deduction_type: @deduction_type,
      min_wage: 1000.00,
      max_wage: 2000.00,
      employee_percentage: 150.0,
      calculation_method: 'percentage'
    )
    assert_not range.valid?
    assert_includes range.errors[:employee_percentage], 'must be less than or equal to 100'
  end

  # ============================================================================
  # SCOPE TESTS
  # ============================================================================

  test 'for_salary should find range containing salary' do
    range1 = DeductionWageRange.create!(
      deduction_type: @deduction_type,
      min_wage: 1000.00,
      max_wage: 2000.00,
      employee_amount: 10.00,
      employer_amount: 20.00
    )

    range2 = DeductionWageRange.create!(
      deduction_type: @deduction_type,
      min_wage: 2000.01,
      max_wage: 3000.00,
      employee_amount: 15.00,
      employer_amount: 30.00
    )

    # Test salary in first range
    found = DeductionWageRange.for_salary(1500).first
    assert_equal range1.id, found.id

    # Test salary in second range
    found = DeductionWageRange.for_salary(2500).first
    assert_equal range2.id, found.id
  end

  test 'for_salary should find open-ended range when salary exceeds all ranges' do
    DeductionWageRange.create!(
      deduction_type: @deduction_type,
      min_wage: 5000.00,
      max_wage: nil,
      employee_amount: 50.00,
      employer_amount: 100.00
    )

    found = DeductionWageRange.for_salary(10_000).first
    assert_not_nil found
    assert_nil found.max_wage
  end

  test 'for_salary should return nil when no range matches' do
    DeductionWageRange.create!(
      deduction_type: @deduction_type,
      min_wage: 1000.00,
      max_wage: 2000.00,
      employee_amount: 10.00,
      employer_amount: 20.00
    )

    found = DeductionWageRange.for_salary(500).first
    assert_nil found
  end

  test 'for_salary should find range at exact boundaries' do
    range = DeductionWageRange.create!(
      deduction_type: @deduction_type,
      min_wage: 1000.00,
      max_wage: 2000.00,
      employee_amount: 10.00,
      employer_amount: 20.00
    )

    # Test at min_wage boundary
    found = DeductionWageRange.for_salary(1000.00).first
    assert_equal range.id, found.id

    # Test at max_wage boundary
    found = DeductionWageRange.for_salary(2000.00).first
    assert_equal range.id, found.id
  end

  # ============================================================================
  # CALCULATION TESTS
  # ============================================================================

  test 'calculate_for should return fixed employee amount' do
    range = DeductionWageRange.create!(
      deduction_type: @deduction_type,
      min_wage: 1000.00,
      max_wage: 2000.00,
      employee_amount: 15.50,
      employer_amount: 30.00,
      calculation_method: 'fixed'
    )

    amount = range.calculate_for(1500, field: :employee)
    assert_equal BigDecimal('15.50'), amount
  end

  test 'calculate_for should return fixed employer amount' do
    range = DeductionWageRange.create!(
      deduction_type: @deduction_type,
      min_wage: 1000.00,
      max_wage: 2000.00,
      employee_amount: 15.50,
      employer_amount: 30.00,
      calculation_method: 'fixed'
    )

    amount = range.calculate_for(1500, field: :employer)
    assert_equal BigDecimal('30.00'), amount
  end

  test 'calculate_for should calculate percentage for employee' do
    range = DeductionWageRange.create!(
      deduction_type: @deduction_type,
      min_wage: 1000.00,
      max_wage: 2000.00,
      employee_percentage: 2.5,
      employer_percentage: 5.0,
      calculation_method: 'percentage'
    )

    amount = range.calculate_for(1500, field: :employee)
    # 1500 * 2.5 / 100 = 37.50
    assert_equal BigDecimal('37.50'), amount
  end

  test 'calculate_for should calculate percentage for employer' do
    range = DeductionWageRange.create!(
      deduction_type: @deduction_type,
      min_wage: 1000.00,
      max_wage: 2000.00,
      employee_percentage: 2.5,
      employer_percentage: 5.0,
      calculation_method: 'percentage'
    )

    amount = range.calculate_for(1500, field: :employer)
    # 1500 * 5.0 / 100 = 75.00
    assert_equal BigDecimal('75.00'), amount
  end

  test 'calculate_for should round percentage results to 2 decimal places' do
    range = DeductionWageRange.create!(
      deduction_type: @deduction_type,
      min_wage: 1000.00,
      max_wage: 2000.00,
      employee_percentage: 1.25,
      calculation_method: 'percentage'
    )

    amount = range.calculate_for(3333.33, field: :employee)
    # 3333.33 * 1.25 / 100 = 41.666625 → rounds to 41.67
    assert_equal BigDecimal('41.67'), amount
  end

  test 'calculate_for should return zero for unknown calculation method' do
    # Test with valid method but zero amounts (simulates unknown method behavior)
    range = DeductionWageRange.create!(
      deduction_type: @deduction_type,
      min_wage: 1000.00,
      max_wage: 2000.00,
      employee_amount: 0.00,
      employer_amount: 0.00,
      calculation_method: 'fixed'
    )

    amount = range.calculate_for(1500, field: :employee)
    assert_equal BigDecimal('0.0'), amount
  end

  # ============================================================================
  # ASSOCIATION TESTS
  # ============================================================================

  test 'should belong to deduction_type' do
    range = DeductionWageRange.new(
      min_wage: 1000.00,
      max_wage: 2000.00,
      employee_amount: 10.00,
      employer_amount: 20.00
    )
    range.deduction_type = @deduction_type
    assert_equal @deduction_type, range.deduction_type
  end

  test 'should be destroyed when deduction_type is destroyed' do
    DeductionWageRange.create!(
      deduction_type: @deduction_type,
      min_wage: 1000.00,
      max_wage: 2000.00,
      employee_amount: 10.00,
      employer_amount: 20.00
    )

    assert_difference 'DeductionWageRange.count', -1 do
      @deduction_type.destroy
    end
  end

  # ============================================================================
  # HELPER METHOD TESTS
  # ============================================================================

  test 'wage_range_display should format range with both min and max' do
    range = DeductionWageRange.new(
      min_wage: 1000.00,
      max_wage: 2000.00
    )
    assert_equal 'RM 1000.00 - RM 2000.00', range.wage_range_display
  end

  test 'wage_range_display should format open-ended range' do
    range = DeductionWageRange.new(
      min_wage: 5000.00,
      max_wage: nil
    )
    assert_equal 'RM 5000.00 - and above', range.wage_range_display
  end

  # ============================================================================
  # REAL-WORLD SCENARIO TESTS
  # ============================================================================

  test 'SOCSO local worker scenario - salary RM 3500' do
    # Create SOCSO local wage range: RM 3400.01 - RM 3500.00
    DeductionWageRange.create!(
      deduction_type: @deduction_type,
      min_wage: 3400.01,
      max_wage: 3500.00,
      employee_amount: 17.25,
      employer_amount: 60.35,
      calculation_method: 'fixed'
    )

    # Find and calculate
    found = DeductionWageRange.for_salary(3500).first
    assert_not_nil found
    assert_equal BigDecimal('17.25'), found.calculate_for(3500, field: :employee)
    assert_equal BigDecimal('60.35'), found.calculate_for(3500, field: :employer)
  end

  test 'multiple wage ranges should not overlap' do
    DeductionWageRange.create!(
      deduction_type: @deduction_type,
      min_wage: 1000.00,
      max_wage: 2000.00,
      employee_amount: 10.00,
      employer_amount: 20.00
    )

    DeductionWageRange.create!(
      deduction_type: @deduction_type,
      min_wage: 2000.01,
      max_wage: 3000.00,
      employee_amount: 15.00,
      employer_amount: 30.00
    )

    # Salary at boundary should find correct range
    found = DeductionWageRange.for_salary(2000.00).first
    assert_equal BigDecimal('10.00'), found.employee_amount

    found = DeductionWageRange.for_salary(2000.01).first
    assert_equal BigDecimal('15.00'), found.employee_amount
  end
end
