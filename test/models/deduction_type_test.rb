# frozen_string_literal: true

require 'test_helper'

class DeductionTypeTest < ActiveSupport::TestCase
  def setup
    # Clean up existing deduction types to avoid conflicts
    DeductionType.delete_all

    @effective_date = Date.parse('2025-01-01')
    @epf = DeductionType.create!(
      code: 'EPF',
      name: 'Employees Provident Fund',
      description: 'EPF for all employees',
      employee_contribution: 11.0,
      employer_contribution: 12.0,
      calculation_type: 'percentage',
      applies_to_nationality: 'all',
      is_active: true,
      effective_from: @effective_date,
      effective_until: nil
    )

    @socso_malaysian = DeductionType.create!(
      code: 'SOCSO_MY',
      name: 'SOCSO Malaysian',
      description: 'SOCSO for Malaysian employees',
      employee_contribution: 0.5,
      employer_contribution: 1.75,
      calculation_type: 'percentage',
      applies_to_nationality: 'local',
      is_active: true,
      effective_from: @effective_date,
      effective_until: nil
    )

    @socso_foreign = DeductionType.create!(
      code: 'SOCSO_FOREIGN',
      name: 'SOCSO Foreign',
      description: 'SOCSO for Foreign employees',
      employee_contribution: 0.0,
      employer_contribution: 1.25,
      calculation_type: 'percentage',
      applies_to_nationality: 'foreigner',
      is_active: true,
      effective_from: @effective_date,
      effective_until: nil
    )

    @sip = DeductionType.create!(
      code: 'SIP',
      name: 'SIP',
      description: 'SIP for Malaysian employees only',
      employee_contribution: 0.2,
      employer_contribution: 0.2,
      calculation_type: 'percentage',
      applies_to_nationality: 'local',
      is_active: true,
      effective_from: @effective_date,
      effective_until: nil
    )
  end

  # ============================================================================
  # VALIDATIONS
  # ============================================================================

  test 'should require name' do
    deduction = DeductionType.new(code: 'TEST', effective_from: Date.current, calculation_type: 'percentage')
    assert_not deduction.valid?
    assert_includes deduction.errors[:name], "can't be blank"
  end

  test 'should require code' do
    deduction = DeductionType.new(name: 'Test Deduction', effective_from: Date.current, calculation_type: 'percentage')
    assert_not deduction.valid?
    assert_includes deduction.errors[:code], "can't be blank"
  end

  test 'should require effective_from' do
    deduction = DeductionType.new(code: 'TEST', name: 'Test', calculation_type: 'percentage')
    assert_not deduction.valid?
    assert_includes deduction.errors[:effective_from], "can't be blank"
  end

  test 'should require calculation_type' do
    deduction = DeductionType.new(code: 'TEST', name: 'Test', effective_from: Date.current, calculation_type: nil)
    assert_not deduction.valid?
    assert_includes deduction.errors[:calculation_type], "can't be blank"
  end

  test 'should validate calculation_type is percentage or fixed' do
    deduction = DeductionType.new(
      code: 'TEST',
      name: 'Test',
      calculation_type: 'invalid',
      effective_from: Date.current
    )
    assert_not deduction.valid?
    assert_includes deduction.errors[:calculation_type], 'is not included in the list'
  end

  test 'should validate applies_to_nationality' do
    deduction = DeductionType.new(
      code: 'TEST',
      name: 'Test',
      calculation_type: 'percentage',
      applies_to_nationality: 'invalid',
      effective_from: Date.current
    )
    assert_not deduction.valid?
    assert_includes deduction.errors[:applies_to_nationality], 'is not included in the list'
  end

  test 'should validate employee_contribution is non-negative' do
    deduction = DeductionType.new(
      code: 'TEST',
      name: 'Test',
      employee_contribution: -1,
      calculation_type: 'percentage',
      effective_from: Date.current
    )
    assert_not deduction.valid?
    assert_includes deduction.errors[:employee_contribution], 'must be greater than or equal to 0'
  end

  test 'should validate employee_amount is non-negative' do
    deduction = DeductionType.new(
      code: 'TEST',
      name: 'Test',
      employer_contribution: -1,
      calculation_type: 'percentage',
      effective_from: Date.current
    )
    assert_not deduction.valid?
    assert_includes deduction.errors[:employer_contribution], 'must be greater than or equal to 0'
  end

  test 'should allow multiple deductions with same code but different effective dates' do
    # End the current EPF first
    @epf.update!(effective_until: Date.parse('2025-12-31'))

    DeductionType.create!(
      code: 'EPF',
      name: 'EPF Old Rate',
      employee_contribution: 11.0,
      employer_contribution: 12.0,
      calculation_type: 'percentage',
      applies_to_nationality: 'all',
      is_active: true,
      effective_from: Date.parse('2024-01-01'),
      effective_until: Date.parse('2024-12-31')
    )

    new_epf = DeductionType.new(
      code: 'EPF',
      name: 'EPF New Rate',
      employee_contribution: 9.0,
      employer_contribution: 12.0,
      calculation_type: 'percentage',
      applies_to_nationality: 'all',
      is_active: true,
      effective_from: Date.parse('2026-01-01'),
      effective_until: nil
    )

    assert new_epf.valid?
    assert new_epf.save
  end

  test 'should not allow multiple deductions with same code and no end date' do
    duplicate_epf = DeductionType.new(
      code: 'EPF',
      name: 'EPF Duplicate',
      employee_contribution: 9.0,
      employer_contribution: 12.0,
      calculation_type: 'percentage',
      applies_to_nationality: 'all',
      is_active: true,
      effective_from: Date.current,
      effective_until: nil
    )

    assert_not duplicate_epf.valid?
    assert_includes duplicate_epf.errors[:code],
                    'already has an active record with no end date. End the current record first.'
  end

  # ============================================================================
  # SCOPES
  # ============================================================================

  test 'active scope should return only active deductions' do
    inactive_deduction = DeductionType.create!(
      code: 'INACTIVE',
      name: 'Inactive Deduction',
      employee_contribution: 10.0,
      employer_contribution: 10.0,
      calculation_type: 'percentage',
      is_active: false,
      effective_from: @effective_date
    )

    active_deductions = DeductionType.active
    assert_includes active_deductions, @epf
    assert_not_includes active_deductions, inactive_deduction
  end

  test 'active_on scope should return deductions active on specific date' do
    old_deduction = DeductionType.create!(
      code: 'OLD',
      name: 'Old Deduction',
      employee_contribution: 5.0,
      employer_contribution: 5.0,
      calculation_type: 'percentage',
      is_active: true,
      effective_from: Date.parse('2024-01-01'),
      effective_until: Date.parse('2024-12-31')
    )

    deductions_2024 = DeductionType.active_on(Date.parse('2024-06-15'))
    assert_includes deductions_2024, old_deduction
    assert_not_includes deductions_2024, @epf

    deductions_2025 = DeductionType.active_on(Date.parse('2025-06-15'))
    assert_includes deductions_2025, @epf
    assert_not_includes deductions_2025, old_deduction
  end

  test 'active_on scope should handle nil effective_until as ongoing' do
    future_deductions = DeductionType.active_on(Date.parse('2030-01-01'))
    assert_includes future_deductions, @epf
  end

  test 'for_nationality scope should filter by nationality' do
    local_deductions = DeductionType.for_nationality('local')
    assert_includes local_deductions, @epf # applies_to: all
    assert_includes local_deductions, @socso_malaysian
    assert_includes local_deductions, @sip
    assert_not_includes local_deductions, @socso_foreign

    foreign_deductions = DeductionType.for_nationality('foreigner')
    assert_includes foreign_deductions, @epf # applies_to: all
    assert_includes foreign_deductions, @socso_foreign
    assert_not_includes foreign_deductions, @socso_malaysian
    assert_not_includes foreign_deductions, @sip
  end

  # ============================================================================
  # CALCULATION METHODS
  # ============================================================================

  test 'calculate_amount should calculate percentage correctly for worker' do
    gross_salary = 3000
    expected_amount = (3000 * 11.0 / 100).round(2) # 330.00

    amount = @epf.calculate_amount(gross_salary, field: :employee_contribution)
    assert_equal expected_amount, amount
  end

  test 'calculate_amount should calculate percentage correctly for employee' do
    gross_salary = 3000
    expected_amount = (3000 * 12.0 / 100).round(2) # 360.00

    amount = @epf.calculate_amount(gross_salary, field: :employer_contribution)
    assert_equal expected_amount, amount
  end

  test 'calculate_amount should handle fixed calculation type' do
    fixed_deduction = DeductionType.create!(
      code: 'FIXED',
      name: 'Fixed Deduction',
      employee_contribution: 50.0,
      employer_contribution: 50.0,
      calculation_type: 'fixed',
      is_active: true,
      effective_from: @effective_date
    )

    amount = fixed_deduction.calculate_amount(3000, field: :employee_contribution)
    assert_equal 50.0, amount
  end

  test 'calculate_amount should return 0 if rate is zero' do
    amount = @socso_foreign.calculate_amount(3000, field: :employee_contribution)
    assert_equal 0, amount
  end

  test 'calculate_amount should round to 2 decimal places' do
    gross_salary = 3333.33
    amount = @epf.calculate_amount(gross_salary, field: :employee_contribution)

    assert_equal 366.67, amount
    assert_equal 2, amount.to_s.split('.').last.length if amount.to_s.include?('.')
  end

  test 'should handle zero gross_salary' do
    amount = @epf.calculate_amount(0, field: :employee_contribution)
    assert_equal 0, amount
  end

  test 'should handle very large gross_salary' do
    large_salary = 1_000_000
    expected_amount = (large_salary * 11.0 / 100).round(2)

    amount = @epf.calculate_amount(large_salary, field: :employee_contribution)
    assert_equal expected_amount, amount
  end

  test 'should handle very small percentage rates' do
    amount = @sip.calculate_amount(3000, field: :employee_contribution)
    assert_equal 6.0, amount # 3000 * 0.2 / 100 = 6.00
  end

  test 'should handle effective date boundaries' do
    bounded_deduction = DeductionType.create!(
      code: 'BOUNDED',
      name: 'Bounded Deduction',
      employee_contribution: 5.0,
      employer_contribution: 5.0,
      calculation_type: 'percentage',
      is_active: true,
      effective_from: Date.parse('2025-01-01'),
      effective_until: Date.parse('2025-06-30')
    )

    assert_includes DeductionType.active_on(Date.parse('2025-01-01')), bounded_deduction
    assert_includes DeductionType.active_on(Date.parse('2025-06-30')), bounded_deduction
    assert_not_includes DeductionType.active_on(Date.parse('2025-07-01')), bounded_deduction
    assert_not_includes DeductionType.active_on(Date.parse('2024-12-31')), bounded_deduction
  end
end
