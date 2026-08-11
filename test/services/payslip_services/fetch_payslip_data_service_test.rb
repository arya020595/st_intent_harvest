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

  test 'work_order_workers eager loads work_order to avoid N+1' do
    rate = WorkOrderRate.create!(work_order_name: 'Test Rate', rate: 10, work_order_rate_type: 'normal',
                                 unit: units(:hectare))
    3.times do |i|
      order = WorkOrder.create!(
        block: blocks(:one),
        work_order_rate: rate,
        field_conductor: users(:admin),
        start_date: Date.new(2025, 1, 1),
        completion_date: Date.new(2025, 1, 15 + i),
        work_order_status: 'completed'
      )
      WorkOrderWorker.create!(work_order: order, worker: @worker, work_area_size: 1, rate: 10)
    end

    result = PayslipServices::FetchPayslipDataService.new(worker: @worker, month_year: '2025-01').call
    work_order_workers = result.value![:work_order_workers].to_a
    assert_equal 3, work_order_workers.size

    query_count = count_queries_on(%w[work_orders work_order_rates units]) do
      work_order_workers.each(&:work_order)
    end
    assert_equal 0, query_count, 'work_order association should be preloaded, not queried per row'
  end

  private

  def count_queries_on(table_names, &)
    count = 0
    pattern = /FROM "(#{table_names.join('|')})"/
    callback = ->(*, payload) { count += 1 if payload[:sql].match?(pattern) }
    ActiveSupport::Notifications.subscribed(callback, 'sql.active_record', &)
    count
  end
end
