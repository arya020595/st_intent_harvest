# frozen_string_literal: true

require 'test_helper'

class PayCalculationDetailIntegrationTest < ActiveSupport::TestCase
  def setup
    # Clean up existing data
    PayCalculationDetail.delete_all
    PayCalculation.delete_all
    Worker.delete_all
    DeductionType.delete_all

    @effective_date = Date.parse('2025-01-01')

    # Create Malaysian statutory deductions
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

    @pay_calc = PayCalculation.create!(month_year: '2025-01')

    @malaysian_worker = Worker.create!(
      name: 'Ahmad bin Abdullah',
      nationality: 'Local',
      worker_type: 'Full - Time'
    )

    @foreign_worker = Worker.create!(
      name: 'John Smith',
      nationality: 'Foreigner',
      worker_type: 'Full - Time'
    )
  end

  # ============================================================================
  # MALAYSIAN WORKER INTEGRATION TESTS
  # ============================================================================

  test 'Malaysian worker with RM 3000 should have correct deductions and net salary' do
    detail = PayCalculationDetail.create!(
      pay_calculation: @pay_calc,
      worker: @malaysian_worker,
      gross_salary: 3000
    )

    # Worker deductions: EPF 11% + SOCSO 0.5% + SIP 0.2% = 11.7%
    assert_equal 351.0, detail.employee_deductions

    # Employer deductions: EPF 12% + SOCSO 1.75% + SIP 0.2% = 13.95%
    assert_equal 418.5, detail.employer_deductions

    # Net salary: 3000 - 351 = 2649
    assert_equal 2649.0, detail.net_salary

    # Verify breakdown
    assert_equal 3, detail.deduction_breakdown.size
    assert_includes detail.deduction_breakdown.keys, 'EPF'
    assert_includes detail.deduction_breakdown.keys, 'SOCSO_MALAYSIAN'
    assert_includes detail.deduction_breakdown.keys, 'SIP'
  end

  test 'Malaysian worker with RM 5000 should have correct deductions' do
    detail = PayCalculationDetail.create!(
      pay_calculation: @pay_calc,
      worker: @malaysian_worker,
      gross_salary: 5000
    )

    assert_equal 585.0, detail.employee_deductions
    assert_equal 697.5, detail.employer_deductions
    assert_equal 4415.0, detail.net_salary
  end

  test 'Malaysian worker with RM 2000 should have correct deductions' do
    detail = PayCalculationDetail.create!(
      pay_calculation: @pay_calc,
      worker: @malaysian_worker,
      gross_salary: 2000
    )

    assert_equal 234.0, detail.employee_deductions
    assert_equal 279.0, detail.employer_deductions
    assert_equal 1766.0, detail.net_salary
  end

  # ============================================================================
  # FOREIGN WORKER INTEGRATION TESTS
  # ============================================================================

  test 'Foreign worker with RM 3000 should have correct deductions and net salary' do
    detail = PayCalculationDetail.create!(
      pay_calculation: @pay_calc,
      worker: @foreign_worker,
      gross_salary: 3000
    )

    # Worker deductions: EPF 11% only (no SIP, SOCSO is 0%)
    assert_equal 330.0, detail.employee_deductions

    # Employer deductions: EPF 12% + SOCSO 1.25%
    assert_equal 397.5, detail.employer_deductions

    # Net salary: 3000 - 330 = 2670
    assert_equal 2670.0, detail.net_salary

    # Verify breakdown - should NOT include SIP or SOCSO_MALAYSIAN
    assert_equal 2, detail.deduction_breakdown.size
    assert_includes detail.deduction_breakdown.keys, 'EPF'
    assert_includes detail.deduction_breakdown.keys, 'SOCSO_FOREIGN'
    assert_not_includes detail.deduction_breakdown.keys, 'SIP'
    assert_not_includes detail.deduction_breakdown.keys, 'SOCSO_MALAYSIAN'
  end

  test 'Foreign worker with RM 5000 should have correct deductions' do
    detail = PayCalculationDetail.create!(
      pay_calculation: @pay_calc,
      worker: @foreign_worker,
      gross_salary: 5000
    )

    assert_equal 550.0, detail.employee_deductions
    assert_equal 662.5, detail.employer_deductions
    assert_equal 4450.0, detail.net_salary
  end

  # ============================================================================
  # DEDUCTION IMMUTABILITY TESTS
  # ============================================================================

  test 'deductions should be immutable after creation' do
    detail = PayCalculationDetail.create!(
      pay_calculation: @pay_calc,
      worker: @malaysian_worker,
      gross_salary: 3000
    )

    detail.employee_deductions
    original_employee_deductions = detail.employee_deductions
    original_net_salary = detail.net_salary

    # Change gross salary
    detail.update!(gross_salary: 5000)
    detail.reload

    # Deductions should NOT change (immutable)
    assert_equal original_employee_deductions, detail.employee_deductions
    assert_equal original_employee_deductions, detail.employee_deductions

    # But net salary SHOULD update: new gross - original deductions
    assert_equal 5000 - original_employee_deductions, detail.net_salary
    assert_not_equal original_net_salary, detail.net_salary
  end

  test 'breakdown should preserve gross_salary and nationality at time of creation' do
    detail = PayCalculationDetail.create!(
      pay_calculation: @pay_calc,
      worker: @malaysian_worker,
      gross_salary: 3000
    )

    # Verify breakdown captures the original context
    detail.deduction_breakdown.each_value do |data|
      assert_equal 3000, data['gross_salary']
      assert_equal 'local', data['nationality']
    end

    # Change gross salary
    detail.update!(gross_salary: 5000)
    detail.reload

    # Breakdown should still show original values
    detail.deduction_breakdown.each_value do |data|
      assert_equal 3000, data['gross_salary'] # Should still be 3000!
      assert_equal 'local', data['nationality']
    end
  end

  test 'deductions should not recalculate when nationality changes' do
    # Create with Malaysian nationality
    detail = PayCalculationDetail.create!(
      pay_calculation: @pay_calc,
      worker: @malaysian_worker,
      gross_salary: 3000
    )

    original_deductions = detail.employee_deductions
    original_breakdown_size = detail.deduction_breakdown.size

    # Change worker nationality (simulating data correction)
    @malaysian_worker.update!(nationality: 'Foreigner')
    detail.reload

    # Deductions should NOT change
    assert_equal original_deductions, detail.employee_deductions
    assert_equal original_breakdown_size, detail.deduction_breakdown.size
  end

  # ============================================================================
  # RATE CHANGE SCENARIO TESTS
  # ============================================================================

  test 'existing pay details should use old rate, new details should use new rate' do
    # Create detail with current EPF rate (11%)
    jan_detail = PayCalculationDetail.create!(
      pay_calculation: @pay_calc,
      worker: @malaysian_worker,
      gross_salary: 3000
    )

    jan_epf_worker = jan_detail.deduction_breakdown['EPF']['employee_amount']
    assert_equal 330.0, jan_epf_worker # 3000 * 11% = 330

    # Simulate EPF rate change on Feb 1st
    @epf.update!(effective_until: Date.parse('2025-01-31'))

    DeductionType.create!(
      code: 'EPF',
      name: 'EPF New Rate',
      employee_contribution: 9.0, # Reduced to 9%
      employer_contribution: 12.0,
      calculation_type: 'percentage',
      applies_to_nationality: 'all',
      is_active: true,
      effective_from: Date.parse('2025-02-01')
    )

    # Create detail for February
    feb_calc = PayCalculation.create!(month_year: '2025-02')
    feb_detail = PayCalculationDetail.create!(
      pay_calculation: feb_calc,
      worker: @malaysian_worker,
      gross_salary: 3000
    )

    feb_epf_worker = feb_detail.deduction_breakdown['EPF']['employee_amount']
    assert_equal 270.0, feb_epf_worker # 3000 * 9% = 270

    # January detail should still have old rate
    jan_detail.reload
    assert_equal 330.0, jan_detail.deduction_breakdown['EPF']['employee_amount']
  end

  # ============================================================================
  # EDGE CASES
  # ============================================================================

  test 'should handle zero salary gracefully' do
    detail = PayCalculationDetail.create!(
      pay_calculation: @pay_calc,
      worker: @malaysian_worker,
      gross_salary: 0
    )

    assert_equal 0, detail.employee_deductions
    assert_equal 0, detail.employer_deductions
    assert_equal 0, detail.net_salary
  end

  test 'should handle very large salary' do
    detail = PayCalculationDetail.create!(
      pay_calculation: @pay_calc,
      worker: @malaysian_worker,
      gross_salary: 100_000
    )

    # EPF: 11,000, SOCSO: 500, SIP: 200 = 11,700
    assert_equal 11_700.0, detail.employee_deductions
    assert_equal 88_300.0, detail.net_salary
  end

  test 'should handle salary with many decimal places' do
    detail = PayCalculationDetail.create!(
      pay_calculation: @pay_calc,
      worker: @malaysian_worker,
      gross_salary: 3333.33
    )

    # All amounts should be rounded to 2 decimal places
    assert_equal 390.01, detail.employee_deductions
    assert_equal 2943.32, detail.net_salary
  end

  test 'should handle worker with nil nationality defaulting to local' do
    worker_no_nationality = Worker.create!(
      name: 'Test Worker',
      nationality: nil,
      worker_type: 'Full - Time'
    )

    detail = PayCalculationDetail.create!(
      pay_calculation: @pay_calc,
      worker: worker_no_nationality,
      gross_salary: 3000
    )

    # Should default to Malaysian and get all 3 deductions
    assert_equal 3, detail.deduction_breakdown.size
    assert_equal 351.0, detail.employee_deductions
  end

  test 'should handle inactive deductions' do
    @sip.update!(is_active: false)

    detail = PayCalculationDetail.create!(
      pay_calculation: @pay_calc,
      worker: @malaysian_worker,
      gross_salary: 3000
    )

    # Should only have EPF and SOCSO, no SIP
    assert_equal 2, detail.deduction_breakdown.size
    assert_not_includes detail.deduction_breakdown.keys, 'SIP'

    # EPF 11% + SOCSO 0.5% = 11.5%
    assert_equal 345.0, detail.employee_deductions
  end

  # ============================================================================
  # BREAKDOWN STRUCTURE TESTS
  # ============================================================================

  test 'breakdown should include all required fields' do
    detail = PayCalculationDetail.create!(
      pay_calculation: @pay_calc,
      worker: @malaysian_worker,
      gross_salary: 3000
    )

    detail.deduction_breakdown.each do |code, data|
      assert data.key?('employee_rate'), "#{code} missing employee_rate"
      assert data.key?('employer_rate'), "#{code} missing employer_rate"
      assert data.key?('employee_amount'), "#{code} missing employee_amount"
      assert data.key?('employer_amount'), "#{code} missing employer_amount"
      assert data.key?('gross_salary'), "#{code} missing gross_salary"
      assert data.key?('nationality'), "#{code} missing nationality"
    end
  end

  test 'breakdown should show correct rates for Malaysian worker' do
    detail = PayCalculationDetail.create!(
      pay_calculation: @pay_calc,
      worker: @malaysian_worker,
      gross_salary: 3000
    )

    epf = detail.deduction_breakdown['EPF']
    assert_equal 11.0, epf['employee_rate'].to_f
    assert_equal 12.0, epf['employer_rate'].to_f

    socso = detail.deduction_breakdown['SOCSO_MALAYSIAN']
    assert_equal 0.5, socso['employee_rate'].to_f
    assert_equal 1.75, socso['employer_rate'].to_f

    sip = detail.deduction_breakdown['SIP']
    assert_equal 0.2, sip['employee_rate'].to_f
    assert_equal 0.2, sip['employer_rate'].to_f
  end

  test 'breakdown should show correct rates for Foreign worker' do
    detail = PayCalculationDetail.create!(
      pay_calculation: @pay_calc,
      worker: @foreign_worker,
      gross_salary: 3000
    )

    epf = detail.deduction_breakdown['EPF']
    assert_equal 11.0, epf['employee_rate'].to_f
    assert_equal 12.0, epf['employer_rate'].to_f

    socso = detail.deduction_breakdown['SOCSO_FOREIGN']
    assert_equal 0.0, socso['employee_rate'].to_f
    assert_equal 1.25, socso['employer_rate'].to_f
  end

  # ============================================================================
  # MULTIPLE WORKERS IN SAME MONTH
  # ============================================================================

  test 'should handle multiple workers with different nationalities in same month' do
    malaysian_detail = PayCalculationDetail.create!(
      pay_calculation: @pay_calc,
      worker: @malaysian_worker,
      gross_salary: 3000
    )

    foreign_detail = PayCalculationDetail.create!(
      pay_calculation: @pay_calc,
      worker: @foreign_worker,
      gross_salary: 3000
    )

    # Malaysian should have higher deductions (includes SIP and higher SOCSO)
    assert_equal 351.0, malaysian_detail.employee_deductions
    assert_equal 330.0, foreign_detail.employee_deductions
    assert malaysian_detail.employee_deductions > foreign_detail.employee_deductions

    # Malaysian should have lower net salary
    assert_equal 2649.0, malaysian_detail.net_salary
    assert_equal 2670.0, foreign_detail.net_salary
    assert malaysian_detail.net_salary < foreign_detail.net_salary
  end

  test 'should calculate different amounts for different salaries with same nationality' do
    detail_3000 = PayCalculationDetail.create!(
      pay_calculation: @pay_calc,
      worker: @malaysian_worker,
      gross_salary: 3000
    )

    second_malaysian = Worker.create!(
      name: 'Ali bin Ahmad',
      nationality: 'Local',
      worker_type: 'Full - Time'
    )
    detail_5000 = PayCalculationDetail.create!(
      pay_calculation: @pay_calc,
      worker: second_malaysian,
      gross_salary: 5000
    )

    # Deductions should be proportional to salary
    assert_equal 351.0, detail_3000.employee_deductions
    assert_equal 585.0, detail_5000.employee_deductions

    # Percentage should be same (11.7%)
    assert_in_delta 11.7, (detail_3000.employee_deductions / 3000 * 100), 0.1
    assert_in_delta 11.7, (detail_5000.employee_deductions / 5000 * 100), 0.1
  end
end
