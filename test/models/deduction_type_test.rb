# frozen_string_literal: true

require 'test_helper'

class DeductionTypeTest < ActiveSupport::TestCase
  # Only load deduction_types fixtures for this test
  fixtures :deduction_types

  def setup
    @epf = deduction_types(:epf)
    @socso = deduction_types(:socso)
  end

  # Validation Tests
  test 'should be valid with valid attributes' do
    deduction = DeductionType.new(
      name: 'Test Deduction',
      code: 'TEST',
      worker_amount: 10.0,
      employee_amount: 20.0,
      is_active: true
    )
    assert deduction.valid?
  end

  test 'should require name' do
    deduction = DeductionType.new(
      code: 'TEST',
      worker_amount: 10.0,
      employee_amount: 20.0,
      is_active: true
    )
    assert_not deduction.valid?
    assert_includes deduction.errors[:name], "can't be blank"
  end

  test 'should require code' do
    deduction = DeductionType.new(
      name: 'Test',
      worker_amount: 10.0,
      employee_amount: 20.0,
      is_active: true
    )
    assert_not deduction.valid?
    assert_includes deduction.errors[:code], "can't be blank"
  end

  test 'should require unique code' do
    deduction = DeductionType.new(
      name: 'Another EPF',
      code: 'EPF', # Same as fixture
      worker_amount: 10.0,
      employee_amount: 20.0,
      is_active: true
    )
    assert_not deduction.valid?
    assert_includes deduction.errors[:code], 'has already been taken'
  end

  test 'should validate worker_amount is non-negative' do
    deduction = DeductionType.new(
      name: 'Test',
      code: 'TEST',
      worker_amount: -10.0,
      employee_amount: 20.0,
      is_active: true
    )
    assert_not deduction.valid?
    assert_includes deduction.errors[:worker_amount], 'must be greater than or equal to 0'
  end

  test 'should validate employee_amount is non-negative' do
    deduction = DeductionType.new(
      name: 'Test',
      code: 'TEST',
      worker_amount: 10.0,
      employee_amount: -20.0,
      is_active: true
    )
    assert_not deduction.valid?
    assert_includes deduction.errors[:employee_amount], 'must be greater than or equal to 0'
  end

  test 'should allow zero amounts' do
    deduction = DeductionType.new(
      name: 'Test',
      code: 'TEST',
      worker_amount: 0.0,
      employee_amount: 0.0,
      is_active: true
    )
    assert deduction.valid?
  end

  test 'should validate is_active is boolean' do
    deduction = DeductionType.new(
      name: 'Test',
      code: 'TEST',
      worker_amount: 10.0,
      employee_amount: 20.0,
      is_active: nil
    )
    assert_not deduction.valid?
    assert_includes deduction.errors[:is_active], 'is not included in the list'
  end

  # Scope Tests
  test 'active scope should return only active deductions' do
    active_deductions = DeductionType.active
    assert_includes active_deductions, @socso
    assert_not_includes active_deductions, @epf
  end

  test 'active scope should be empty when no active deductions' do
    DeductionType.update_all(is_active: false)
    assert_empty DeductionType.active
  end

  # Method Tests
  test 'worker_amount should be accessible' do
    assert_equal 21.25, @socso.worker_amount
  end

  test 'employee_amount should be accessible' do
    assert_equal 74.35, @socso.employee_amount
  end

  test 'should calculate total deduction (worker + employee)' do
    total = @socso.worker_amount + @socso.employee_amount
    assert_equal 95.60, total
  end

  # Ransack Configuration Tests
  test 'ransackable_attributes should include expected attributes' do
    expected_attrs = %w[id name code description is_active worker_amount employee_amount created_at updated_at]
    assert_equal expected_attrs, DeductionType.ransackable_attributes
  end

  test 'ransackable_associations should be empty' do
    assert_empty DeductionType.ransackable_associations
  end

  # Business Logic Tests
  test 'should calculate correct deductions for SOCSO' do
    assert_equal 21.25, @socso.worker_amount
    assert_equal 74.35, @socso.employee_amount
    total = @socso.worker_amount + @socso.employee_amount
    assert_equal 95.60, total
  end

  test 'inactive deductions should not appear in active scope' do
    assert_not @epf.is_active
    assert_not_includes DeductionType.active, @epf
  end

  test 'activating a deduction should include it in active scope' do
    @epf.update!(is_active: true)
    assert_includes DeductionType.active, @epf
  end

  test 'deactivating a deduction should remove it from active scope' do
    @socso.update!(is_active: false)
    assert_not_includes DeductionType.active, @socso
  end
end
