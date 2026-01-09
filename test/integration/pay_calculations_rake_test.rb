# frozen_string_literal: true

require 'test_helper'
require 'rake'

class PayCalculationsRakeTest < ActiveSupport::TestCase
  fixtures :workers, :work_order_rates, :blocks

  setup do
    # Load Rake tasks
    Rails.application.load_tasks unless Rake::Task.task_defined?('pay_calculations:recalculate_all')

    @work_order_rate = work_order_rates(:one)
    @block = blocks(:one)
    @worker1 = workers(:one)
    @worker2 = workers(:two)

    # Set completion date in the past to avoid any date-related issues
    @completion_date = Date.new(2025, 11, 18)
    @month_year = @completion_date.strftime('%Y-%m')
    @month_start = @completion_date.beginning_of_month
    @month_end = @completion_date.end_of_month

    # Create a completed work order with workers
    @work_order = WorkOrder.create!(
      work_order_rate: @work_order_rate,
      work_order_status: 'completed',
      start_date: @month_start,
      completion_date: @completion_date,
      block: @block
    )

    @work_order_worker1 = @work_order.work_order_workers.create!(
      worker: @worker1,
      rate: 10,
      work_area_size: 100  # amount = 1000
    )

    @work_order_worker2 = @work_order.work_order_workers.create!(
      worker: @worker2,
      rate: 15,
      work_area_size: 50  # amount = 750
    )

    # Process the pay calculation
    PayCalculationServices::ProcessWorkOrderService.new(@work_order).call

    @pay_calc = PayCalculation.find_by(month_year: @month_year)
  end

  teardown do
    # Re-enable all rake tasks for other tests
    Rake::Task['pay_calculations:recalculate_all'].reenable if Rake::Task.task_defined?('pay_calculations:recalculate_all')
    Rake::Task['pay_calculations:recalculate_month'].reenable if Rake::Task.task_defined?('pay_calculations:recalculate_month')
  end

  test 'recalculate_all excludes discarded work orders from gross salary' do
    # Create a second work order for worker1
    second_work_order = WorkOrder.create!(
      work_order_rate: @work_order_rate,
      work_order_status: 'completed',
      start_date: @month_start + 5.days,
      completion_date: @completion_date + 2.days,
      block: @block
    )

    second_work_order.work_order_workers.create!(
      worker: @worker1,
      rate: 10,
      work_area_size: 50  # amount = 500
    )

    # Process the second work order
    PayCalculationServices::ProcessWorkOrderService.new(second_work_order).call

    # Worker1 now has 1500 gross salary (1000 + 500)
    @pay_calc.reload
    detail = @pay_calc.pay_calculation_details.find_by(worker: @worker1)
    assert_equal 1500.0, detail.gross_salary.to_f

    # Soft delete the first work order WITHOUT using the callback (to simulate a bug)
    # This simulates a scenario where ReverseWorkOrderService didn't run properly
    @work_order.update_columns(discarded_at: Time.current)
    @work_order.work_order_workers.update_all(discarded_at: Time.current)

    # Gross salary is still 1500 (stale data)
    detail.reload
    assert_equal 1500.0, detail.gross_salary.to_f

    # Run the rake task to fix it
    Rake::Task['pay_calculations:recalculate_all'].invoke

    # Now gross salary should be 500 (only from kept work order)
    detail.reload
    assert_equal 500.0, detail.gross_salary.to_f
  end

  test 'recalculate_all excludes discarded work_order_workers from gross salary' do
    # Verify initial state
    detail = @pay_calc.pay_calculation_details.find_by(worker: @worker1)
    assert_equal 1000.0, detail.gross_salary.to_f

    # Soft delete just the work_order_worker (not the work order)
    @work_order_worker1.update_columns(discarded_at: Time.current)

    # Run the rake task
    Rake::Task['pay_calculations:recalculate_all'].invoke

    # Worker1 should now have 0 gross salary (no kept work_order_workers)
    detail.reload
    assert_equal 0.0, detail.gross_salary.to_f
  end

  test 'recalculate_month excludes discarded work orders from gross salary' do
    # Create a second work order for worker1
    second_work_order = WorkOrder.create!(
      work_order_rate: @work_order_rate,
      work_order_status: 'completed',
      start_date: @month_start + 5.days,
      completion_date: @completion_date + 2.days,
      block: @block
    )

    second_work_order.work_order_workers.create!(
      worker: @worker1,
      rate: 20,
      work_area_size: 25  # amount = 500
    )

    PayCalculationServices::ProcessWorkOrderService.new(second_work_order).call

    @pay_calc.reload
    detail = @pay_calc.pay_calculation_details.find_by(worker: @worker1)
    assert_equal 1500.0, detail.gross_salary.to_f

    # Soft delete the first work order without callback
    @work_order.update_columns(discarded_at: Time.current)
    @work_order.work_order_workers.update_all(discarded_at: Time.current)

    # Run recalculate_month
    Rake::Task['pay_calculations:recalculate_month'].invoke(@month_year)
    Rake::Task['pay_calculations:recalculate_month'].reenable

    detail.reload
    assert_equal 500.0, detail.gross_salary.to_f
  end

  test 'recalculate_all updates pay calculation totals correctly' do
    # Soft delete first work order without callback
    @work_order.update_columns(discarded_at: Time.current)
    @work_order.work_order_workers.update_all(discarded_at: Time.current)

    original_total = @pay_calc.total_gross_salary.to_f

    Rake::Task['pay_calculations:recalculate_all'].invoke

    @pay_calc.reload

    # Both workers had their work orders discarded, so total should be 0
    assert_equal 0.0, @pay_calc.total_gross_salary.to_f
    assert original_total > @pay_calc.total_gross_salary.to_f
  end

  test 'recalculate_all recalculates deductions after updating gross salary' do
    detail = @pay_calc.pay_calculation_details.find_by(worker: @worker1)
    original_deductions = detail.employee_deductions

    # Soft delete the work order
    @work_order.update_columns(discarded_at: Time.current)
    @work_order.work_order_workers.update_all(discarded_at: Time.current)

    Rake::Task['pay_calculations:recalculate_all'].invoke

    detail.reload

    # Deductions should be 0 since gross is 0
    assert_equal 0.0, detail.gross_salary.to_f
    # Deductions should be recalculated (may be 0 or different based on new gross)
    assert_not_equal original_deductions, detail.employee_deductions if original_deductions.to_f > 0
  end
end
