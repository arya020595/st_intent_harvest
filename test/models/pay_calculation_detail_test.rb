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
      employee_deductions: 0.00,
      employer_deductions: 0.00,
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

    # Should have EPF (11% = 550) + SOCSO (0.5% = 25) + SIP (0.2% = 10) = 585
    assert_equal 585.0, detail.employee_deductions
    # Should have EPF (12% = 600) + SOCSO (1.75% = 87.5) + SIP (0.2% = 10) = 697.5
    assert_equal 697.5, detail.employer_deductions
  end

  test 'should have zero deductions when no active deductions' do
    DeductionType.update_all(is_active: false)
    march_calc = PayCalculation.create!(month_year: '2025-03')

    detail = PayCalculationDetail.create!(
      pay_calculation: march_calc,
      worker: @worker,
      gross_salary: 5000.00
    )

    assert_equal 0, detail.employee_deductions
    assert_equal 0, detail.employer_deductions

    # Reset for other tests
    DeductionType.update_all(is_active: true)
  end

  test 'should populate deduction_breakdown with active deductions' do
    april_calc = PayCalculation.create!(month_year: '2025-04')
    detail = PayCalculationDetail.create!(
      pay_calculation: april_calc,
      worker: @worker,
      gross_salary: 5000.00
    )

    assert_not_nil detail.deduction_breakdown
    # We have EPF, SOCSO_MALAYSIAN, and SIP active by default
    assert_includes detail.deduction_breakdown.keys, 'EPF'
    assert_includes detail.deduction_breakdown.keys, 'SOCSO_MALAYSIAN'
    assert_includes detail.deduction_breakdown.keys, 'SIP'
  end

  test 'should recalculate deductions when updated' do
    @detail.update!(gross_salary: 6000.00)

    # Manually recalculate deductions (using frozen snapshot rates)
    @detail.recalculate_deductions!

    # Deductions should be recalculated based on snapshot rates
    # EPF: 11% = 660, SOCSO: 0.5% = 30, SIP: 0.2% = 12 = 702 total
    assert_equal 702.0, @detail.employee_deductions
    # EPF: 12% = 720, SOCSO: 1.75% = 105, SIP: 0.2% = 12 = 837 total
    assert_equal 837.0, @detail.employer_deductions
  end

  test 'should handle multiple active deductions' do
    may_calc = PayCalculation.create!(month_year: '2025-05')
    detail = PayCalculationDetail.create!(
      pay_calculation: may_calc,
      worker: @worker,
      gross_salary: 5000.00
    )

    # Should have EPF (11% = 550) + SOCSO (0.5% = 25) + SIP (0.2% = 10) = 585
    assert_equal 585.0, detail.employee_deductions
    # Should have EPF (12% = 600) + SOCSO (1.75% = 87.5) + SIP (0.2% = 10) = 697.5
    assert_equal 697.5, detail.employer_deductions
    assert_includes detail.deduction_breakdown.keys, 'SOCSO_MALAYSIAN'
    assert_includes detail.deduction_breakdown.keys, 'EPF'
    assert_includes detail.deduction_breakdown.keys, 'SIP'
  end

  # Net Salary Calculation Tests
  test 'net_salary should equal gross minus employee_deductions' do
    assert_equal 4478.75, @detail.net_salary
    assert_equal @detail.gross_salary - @detail.employee_deductions, @detail.net_salary
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
    DeductionType.update_all(is_active: true)
  end

  test 'should calculate correct net_salary with multiple deductions' do
    july_calc = PayCalculation.create!(month_year: '2025-07')
    detail = PayCalculationDetail.create!(
      pay_calculation: july_calc,
      worker: @worker,
      gross_salary: 5000.00
    )

    # EPF: 11% = 550, SOCSO: 0.5% = 25, SIP: 0.2% = 10 = 585 total employee deductions
    expected_employee_deductions = 585.0
    expected_net = 5000.00 - expected_employee_deductions

    assert_equal expected_employee_deductions, detail.employee_deductions
    assert_equal expected_net, detail.net_salary
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
      assert_includes data.keys, 'employee_rate'
      assert_includes data.keys, 'employer_rate'
      assert_includes data.keys, 'employee_amount'
      assert_includes data.keys, 'employer_amount'
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
    DeductionType.update_all(is_active: true)
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

    # With 0 gross salary, all percentage-based deductions should be 0
    assert_equal 0.0, detail.employee_deductions
    assert_equal 0.0, detail.employer_deductions
    assert_equal 0.0, detail.net_salary
  end

  test 'should update net_salary when gross_salary changes' do
    original_net = @detail.net_salary

    # Change gross salary
    @detail.update!(gross_salary: 5000.00)

    # Net salary should be recalculated
    assert_not_equal original_net, @detail.net_salary
    assert_equal 5000.00 - @detail.employee_deductions, @detail.net_salary
  end
end
