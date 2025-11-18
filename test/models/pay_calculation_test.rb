# == Schema Information
#
# Table name: pay_calculations
#
#  id                  :integer          not null, primary key
#  month_year          :string           not null
#  total_gross_salary  :decimal(10, 2)   default(0), not null
#  total_deductions    :decimal(10, 2)   default(0), not null
#  total_net_salary    :decimal(10, 2)   default(0), not null
#  created_at          :datetime         not null
#  updated_at          :datetime         not null
#

require 'test_helper'

class PayCalculationTest < ActiveSupport::TestCase
  # Test Associations
  test 'should have many pay_calculation_details' do
    pay_calculation = pay_calculations(:pay_calc_nov_2024)
    assert_respond_to pay_calculation, :pay_calculation_details
  end

  test 'should have many workers through pay_calculation_details' do
    pay_calculation = pay_calculations(:pay_calc_nov_2024)
    assert_respond_to pay_calculation, :workers
  end

  # Test Validations
  test 'should require month_year' do
    pay_calculation = PayCalculation.new(month_year: nil)
    assert_not pay_calculation.valid?
    assert_includes pay_calculation.errors[:month_year], "can't be blank"
  end

  test 'should be valid with month_year' do
    pay_calculation = PayCalculation.new(month_year: '2024-12')
    assert pay_calculation.valid?
  end

  # Test find_or_create_for_month
  test 'should find existing pay calculation by month_year' do
    existing = pay_calculations(:pay_calc_nov_2024)
    found = PayCalculation.find_or_create_for_month(existing.month_year)

    assert_equal existing.id, found.id
  end

  test 'should create new pay calculation with zero defaults' do
    month = '2024-12'
    assert_difference 'PayCalculation.count', 1 do
      PayCalculation.find_or_create_for_month(month)
    end

    pay_calc = PayCalculation.find_by(month_year: month)
    assert_equal 0, pay_calc.total_gross_salary
    assert_equal 0, pay_calc.total_deductions
    assert_equal 0, pay_calc.total_net_salary
  end
  test 'should recalculate all totals from pay_calculation_details' do
    pay_calculation = pay_calculations(:pay_calc_nov_2024)

    # Create test details - deductions will be auto-calculated
    worker1 = workers(:one)
    worker2 = workers(:two)

    detail1 = pay_calculation.pay_calculation_details.create!(
      worker: worker1,
      gross_salary: 3000
    )

    detail2 = pay_calculation.pay_calculation_details.create!(
      worker: worker2,
      gross_salary: 2500
    )

    pay_calculation.recalculate_overall_total!
    pay_calculation.reload

    # Total gross salary
    assert_equal 5500, pay_calculation.total_gross_salary

    # Total deductions (calculated from active deduction types)
    expected_deductions = detail1.deductions + detail2.deductions
    assert_equal expected_deductions, pay_calculation.total_deductions

    # Total net salary
    expected_net = detail1.net_salary + detail2.net_salary
    assert_equal expected_net, pay_calculation.total_net_salary
  end

  test 'should handle zero totals when no details exist' do
    pay_calculation = PayCalculation.create!(month_year: '2025-01')
    pay_calculation.recalculate_overall_total!
    pay_calculation.reload

    assert_equal 0, pay_calculation.total_gross_salary
    assert_equal 0, pay_calculation.total_deductions
    assert_equal 0, pay_calculation.total_net_salary
  end

  test 'should update all totals when recalculated multiple times' do
    pay_calculation = pay_calculations(:pay_calc_nov_2024)
    worker = workers(:one)

    # First calculation - deductions auto-calculated
    detail = pay_calculation.pay_calculation_details.create!(
      worker: worker,
      gross_salary: 1000
    )

    pay_calculation.recalculate_overall_total!
    pay_calculation.reload

    first_deductions = detail.deductions
    first_net = detail.net_salary

    assert_equal 1000, pay_calculation.total_gross_salary
    assert_equal first_deductions, pay_calculation.total_deductions
    assert_equal first_net, pay_calculation.total_net_salary

    # Update detail and recalculate
    detail.update!(gross_salary: 2000)

    pay_calculation.recalculate_overall_total!
    pay_calculation.reload

    detail.reload
    assert_equal 2000, pay_calculation.total_gross_salary
    assert_equal detail.deductions, pay_calculation.total_deductions
    assert_equal detail.net_salary, pay_calculation.total_net_salary
  end

  # Test ransackable attributes
  test 'should include new totals in ransackable_attributes' do
    attrs = PayCalculation.ransackable_attributes

    assert_includes attrs, 'total_gross_salary'
    assert_includes attrs, 'total_deductions'
    assert_includes attrs, 'total_net_salary'
  end
end
