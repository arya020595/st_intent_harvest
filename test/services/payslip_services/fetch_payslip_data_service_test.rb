# frozen_string_literal: true

require 'test_helper'

class FetchPayslipDataServiceTest < ActiveSupport::TestCase
  def setup
    @worker = workers(:one)
  end

  test 'success returns payslip data for existing month and worker detail' do
    result = PayslipServices::FetchPayslipDataService.new(worker: @worker, month_year: '2025-01').call
    assert result.success?, 'Expected Success result'
    data = result.value!
    assert_equal '2025-01', data[:payslip].month_year
    assert_equal @worker.id, data[:payslip_detail].worker_id
    assert data[:work_order_workers].respond_to?(:to_a), 'Expected work_order_workers to be a relation'
    assert_kind_of Date, data[:month_year_date]
  end

  test 'failure when pay calculation does not exist' do
    result = PayslipServices::FetchPayslipDataService.new(worker: @worker, month_year: '2025-03').call
    assert result.failure?, 'Expected Failure result'
    assert_equal :no_pay_calculation, result.failure
  end

  test 'failure when worker detail missing for existing pay calculation' do
    # pay calculation exists for 2024-11, but no detail for worker one in fixtures
    result = PayslipServices::FetchPayslipDataService.new(worker: @worker, month_year: '2024-11').call
    assert result.failure?, 'Expected Failure result'
    assert_equal :no_worker_detail, result.failure
  end
end
