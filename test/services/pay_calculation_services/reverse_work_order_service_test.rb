# frozen_string_literal: true

require 'test_helper'

module PayCalculationServices
  class ReverseWorkOrderServiceTest < ActiveSupport::TestCase
    fixtures :workers, :work_order_rates, :blocks, :users

    setup do
      @work_order_rate = work_order_rates(:one)
      @block = blocks(:one)
      @worker1 = workers(:one)
      @worker2 = workers(:two)

      # Create and complete a work order with workers
      completion_date = Date.current.prev_month.change(day: 18)
      start_date = completion_date.change(day: 1)

      @work_order = WorkOrder.create!(
        work_order_rate: @work_order_rate,
        work_order_status: 'completed',
        start_date: start_date,
        completion_date: completion_date,
        block: @block
      )

      @work_order.work_order_workers.create!(
        worker: @worker1,
        rate: 10,
        work_area_size: 100  # Will result in 1000 gross salary
      )

      @work_order.work_order_workers.create!(
        worker: @worker2,
        rate: 15,
        work_area_size: 50  # Will result in 750 gross salary
      )

      # Process the pay calculation (simulating what happens on completion)
      ProcessWorkOrderService.new(@work_order).call

      @month_year = @work_order.completion_date.strftime('%Y-%m')
      @pay_calc = PayCalculation.find_by(month_year: @month_year)
    end

    test 'returns success when work order is not completed' do
      @work_order.update_column(:work_order_status, 'ongoing')

      result = ReverseWorkOrderService.new(@work_order).call

      assert result.success?
      assert_equal 'Not completed', result.value!
    end

    test 'returns success when work order has no completion date' do
      @work_order.update_column(:completion_date, nil)

      result = ReverseWorkOrderService.new(@work_order).call

      assert result.success?
      assert_equal 'No completion date', result.value!
    end

    test 'returns success when no pay calculation exists for the month' do
      @pay_calc.destroy!

      result = ReverseWorkOrderService.new(@work_order).call

      assert result.success?
      assert_equal 'No pay calculation found', result.value!
    end

    test 'removes pay calculation details when work order is the only source of earnings' do
      initial_details_count = @pay_calc.pay_calculation_details.count
      assert_equal 2, initial_details_count

      result = ReverseWorkOrderService.new(@work_order).call

      assert result.success?

      # Both workers should have their details removed (no other work orders)
      assert_equal 0, @pay_calc.reload.pay_calculation_details.count
    end

    test 'destroys empty pay calculation after removing all details' do
      result = ReverseWorkOrderService.new(@work_order).call

      assert result.success?
      assert_nil PayCalculation.find_by(id: @pay_calc.id)
    end

    test 'recalculates worker earnings when they have other active work orders' do
      # Create a second work order in the same month for worker1
      second_work_order = WorkOrder.create!(
        work_order_rate: @work_order_rate,
        work_order_status: 'completed',
        start_date: Date.new(2025, 11, 5),
        completion_date: Date.new(2025, 11, 20),
        block: @block
      )

      second_work_order.work_order_workers.create!(
        worker: @worker1,
        rate: 10,
        work_area_size: 50  # 500 additional gross salary
      )

      # Process the second work order
      ProcessWorkOrderService.new(second_work_order).call

      # Worker1 now has 1500 gross salary (1000 + 500)
      detail_before = @pay_calc.pay_calculation_details.find_by(worker: @worker1)
      assert_equal 1500.0, detail_before.gross_salary.to_f

      # Reverse the first work order
      result = ReverseWorkOrderService.new(@work_order).call

      assert result.success?

      # Worker1 should now have only 500 gross salary
      @pay_calc.reload
      detail_after = @pay_calc.pay_calculation_details.find_by(worker: @worker1)
      assert_not_nil detail_after
      assert_equal 500.0, detail_after.gross_salary.to_f

      # Worker2 should be removed (no other work orders)
      assert_nil @pay_calc.pay_calculation_details.find_by(worker: @worker2)
    end

    test 'updates pay calculation totals correctly after reversal' do
      # Create a second work order for worker1
      second_work_order = WorkOrder.create!(
        work_order_rate: @work_order_rate,
        work_order_status: 'completed',
        start_date: Date.new(2025, 11, 5),
        completion_date: Date.new(2025, 11, 20),
        block: @block
      )

      second_work_order.work_order_workers.create!(
        worker: @worker1,
        rate: 10,
        work_area_size: 50
      )

      ProcessWorkOrderService.new(second_work_order).call

      total_gross_before = @pay_calc.reload.total_gross_salary

      # Reverse the first work order
      ReverseWorkOrderService.new(@work_order).call

      @pay_calc.reload
      # Only worker1 remains with 500 gross salary
      assert_equal 500.0, @pay_calc.total_gross_salary.to_f
    end

    test 'returns success for resource-only work order' do
      resource_rate = work_order_rates(:resources)
      resource_work_order = WorkOrder.create!(
        work_order_rate: resource_rate,
        work_order_status: 'completed',
        start_date: Date.new(2025, 11, 1),
        completion_date: Date.new(2025, 11, 18),
        block: @block
      )

      # Force the denormalized type
      resource_work_order.update_column(:work_order_rate_type, 'resources')

      result = ReverseWorkOrderService.new(resource_work_order).call

      assert result.success?
      assert_equal 'Resource-only work order, no pay calculation impact', result.value!
    end

    test 'soft delete of work order triggers automatic reversal via callback' do
      # This tests the integration with SoftDeletable concern
      initial_total = @pay_calc.total_gross_salary

      # Soft delete the work order - should trigger after_discard callback
      @work_order.discard

      # PayCalculation should be destroyed (no more details)
      assert_nil PayCalculation.find_by(id: @pay_calc.id)
    end

    test 'recalculates deductions after updating gross salary' do
      # Create a second work order for worker1
      second_work_order = WorkOrder.create!(
        work_order_rate: @work_order_rate,
        work_order_status: 'completed',
        start_date: Date.new(2025, 11, 5),
        completion_date: Date.new(2025, 11, 20),
        block: @block
      )

      second_work_order.work_order_workers.create!(
        worker: @worker1,
        rate: 10,
        work_area_size: 50
      )

      ProcessWorkOrderService.new(second_work_order).call

      # Get deductions before
      detail_before = @pay_calc.pay_calculation_details.find_by(worker: @worker1)
      deductions_before = detail_before.employee_deductions

      # Reverse the first work order
      ReverseWorkOrderService.new(@work_order).call

      @pay_calc.reload
      detail_after = @pay_calc.pay_calculation_details.find_by(worker: @worker1)

      # Deductions should be recalculated based on new gross salary
      # (New gross is lower, so deductions should also be lower or same depending on brackets)
      assert_not_nil detail_after.employee_deductions
    end
  end
end
