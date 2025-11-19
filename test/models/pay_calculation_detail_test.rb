# frozen_string_literal: true

# == Schema Information
#
# Table name: pay_calculation_details
#
#  id                 :bigint           not null, primary key
#  currency           :string           default("RM")
#  deductions         :decimal(10, 2)
#  gross_salary       :decimal(10, 2)
#  net_salary         :decimal(10, 2)
#  created_at         :datetime         not null
#  updated_at         :datetime         not null
#  pay_calculation_id :bigint           not null
#  worker_id          :bigint           not null
#
# Indexes
#
#  index_pay_calculation_details_on_pay_calculation_id  (pay_calculation_id)
#  index_pay_calculation_details_on_worker_id           (worker_id)
#
# Foreign Keys
#
#  fk_rails_...  (pay_calculation_id => pay_calculations.id)
#  fk_rails_...  (worker_id => workers.id)
#
require 'test_helper'

class PayCalculationDetailTest < ActiveSupport::TestCase
  # Only load specific fixtures
  fixtures :deduction_types, :workers, :pay_calculations, :pay_calculation_details

  def setup
    @pay_calc = pay_calculations(:january_2025)
    @worker = workers(:one)
    @other_worker = workers(:two)
    @detail = pay_calculation_details(:john_january)
    @socso = deduction_types(:socso)
  end

  # Association Tests
  test 'should belong to pay_calculation' do
    assert_equal @pay_calc, @detail.pay_calculation
  end

  test 'should belong to worker' do
    assert_equal @worker, @detail.worker
  end

  # Validation Tests
  test 'should be valid with valid attributes' do
    detail = PayCalculationDetail.new(
      pay_calculation: @pay_calc,
      worker: @worker,
      gross_salary: 1000.00,
      worker_deductions: 0.00,
      employee_deductions: 0.00,
      net_salary: 1000.00
    )
    assert detail.valid?
  end

  test 'should require pay_calculation' do
    detail = PayCalculationDetail.new(
      worker: @worker,
      gross_salary: 1000.00
    )
    assert_not detail.valid?
  end

  test 'should require worker' do
    detail = PayCalculationDetail.new(
      pay_calculation: @pay_calc,
      gross_salary: 1000.00
    )
    assert_not detail.valid?
  end

  # Deduction Calculation Tests
  test 'should calculate deductions on save when active deductions exist' do
    february_calc = PayCalculation.create!(month_year: '2025-02')
    detail = PayCalculationDetail.create!(
      pay_calculation: february_calc,
      worker: @worker,
      gross_salary: 5000.00
    )

    # Should have SOCSO deduction from fixtures (active)
    assert_equal 21.25, detail.worker_deductions
    assert_equal 74.35, detail.employee_deductions
  end

  test 'should have zero deductions when no active deductions' do
    DeductionType.update_all(is_active: false)
    march_calc = PayCalculation.create!(month_year: '2025-03')

    detail = PayCalculationDetail.create!(
      pay_calculation: march_calc,
      worker: @worker,
      gross_salary: 5000.00
    )

    assert_equal 0, detail.worker_deductions
    assert_equal 0, detail.employee_deductions

    # Reset for other tests
    DeductionType.find_by(code: 'SOCSO').update!(is_active: true)
  end

  test 'should populate deduction_breakdown with active deductions' do
    april_calc = PayCalculation.create!(month_year: '2025-04')
    detail = PayCalculationDetail.create!(
      pay_calculation: april_calc,
      worker: @worker,
      gross_salary: 5000.00
    )

    assert_not_nil detail.deduction_breakdown
    assert_includes detail.deduction_breakdown.keys, 'SOCSO'

    socso_breakdown = detail.deduction_breakdown['SOCSO']
    assert_equal 'SOCSO', socso_breakdown['name']
    assert_equal 21.25, socso_breakdown['worker']
    assert_equal 74.35, socso_breakdown['employee']
  end

  test 'should recalculate deductions when updated' do
    @detail.update!(gross_salary: 6000.00)

    # Deductions should be recalculated
    assert_equal 21.25, @detail.worker_deductions
    assert_equal 74.35, @detail.employee_deductions
  end

  test 'should handle multiple active deductions' do
    # Activate EPF
    epf = deduction_types(:epf)
    epf.update!(is_active: true)

    may_calc = PayCalculation.create!(month_year: '2025-05')
    detail = PayCalculationDetail.create!(
      pay_calculation: may_calc,
      worker: @worker,
      gross_salary: 5000.00
    )

    # Should have both SOCSO and EPF
    expected_worker = 21.25 + 50.00 # SOCSO + EPF
    expected_employee = 74.35 + 150.00 # SOCSO + EPF

    assert_equal expected_worker, detail.worker_deductions
    assert_equal expected_employee, detail.employee_deductions
    assert_includes detail.deduction_breakdown.keys, 'SOCSO'
    assert_includes detail.deduction_breakdown.keys, 'EPF'

    # Reset
    epf.update!(is_active: false)
  end

  # Net Salary Calculation Tests
  test 'net_salary should equal gross minus worker_deductions' do
    assert_equal 4478.75, @detail.net_salary
    assert_equal @detail.gross_salary - @detail.worker_deductions, @detail.net_salary
  end

  test 'should calculate correct net_salary with zero deductions' do
    DeductionType.update_all(is_active: false)

    june_calc = PayCalculation.create!(month_year: '2025-06')
    detail = PayCalculationDetail.create!(
      pay_calculation: june_calc,
      worker: @worker,
      gross_salary: 5000.00
    )

    assert_equal 5000.00, detail.net_salary

    # Reset
    DeductionType.find_by(code: 'SOCSO').update!(is_active: true)
  end

  test 'should calculate correct net_salary with multiple deductions' do
    # Activate all deductions
    DeductionType.update_all(is_active: true)

    july_calc = PayCalculation.create!(month_year: '2025-07')
    detail = PayCalculationDetail.create!(
      pay_calculation: july_calc,
      worker: @worker,
      gross_salary: 5000.00
    )

    # EPF: 50, SOCSO: 21.25, SIP: 10 = 81.25 total worker deductions
    expected_worker_deductions = 50.00 + 21.25 + 10.00
    expected_net = 5000.00 - expected_worker_deductions

    assert_equal expected_worker_deductions, detail.worker_deductions
    assert_equal expected_net, detail.net_salary

    # Reset
    DeductionType.update_all(is_active: false)
    DeductionType.find_by(code: 'SOCSO').update!(is_active: true)
  end

  # JSONB Deduction Breakdown Tests
  test 'deduction_breakdown should be a hash' do
    august_calc = PayCalculation.create!(month_year: '2025-08')
    detail = PayCalculationDetail.create!(
      pay_calculation: august_calc,
      worker: @worker,
      gross_salary: 1000.00
    )
    assert_instance_of Hash, detail.deduction_breakdown
  end

  test 'deduction_breakdown should contain correct structure' do
    september_calc = PayCalculation.create!(month_year: '2025-09')
    detail = PayCalculationDetail.create!(
      pay_calculation: september_calc,
      worker: @worker,
      gross_salary: 1000.00
    )
    breakdown = detail.deduction_breakdown

    breakdown.each_value do |data|
      assert_instance_of Hash, data
      assert_includes data.keys, 'name'
      assert_includes data.keys, 'worker'
      assert_includes data.keys, 'employee'
    end
  end

  test 'should handle empty deduction_breakdown' do
    DeductionType.update_all(is_active: false)

    october_calc = PayCalculation.create!(month_year: '2025-10')
    detail = PayCalculationDetail.create!(
      pay_calculation: october_calc,
      worker: @worker,
      gross_salary: 5000.00
    )

    assert_empty detail.deduction_breakdown

    # Reset
    DeductionType.find_by(code: 'SOCSO').update!(is_active: true)
  end

  # Currency Tests
  test 'should default currency to RM' do
    detail = PayCalculationDetail.new
    assert_equal 'RM', detail.currency
  end

  # Edge Cases
  test 'should handle zero gross_salary' do
    november_calc = PayCalculation.create!(month_year: '2025-11')
    detail = PayCalculationDetail.create!(
      pay_calculation: november_calc,
      worker: @worker,
      gross_salary: 0.00
    )

    # Should still apply fixed deductions
    assert_equal 21.25, detail.worker_deductions
    assert_equal 74.35, detail.employee_deductions
    assert_equal(-21.25, detail.net_salary) # Negative because deductions exceed gross
  end

  test 'should update net_salary when gross_salary changes' do
    original_net = @detail.net_salary

    # Change gross salary
    @detail.update!(gross_salary: 5000.00)

    # Net salary should be recalculated
    assert_not_equal original_net, @detail.net_salary
    assert_equal 5000.00 - @detail.worker_deductions, @detail.net_salary
  end
end
