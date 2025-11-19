# frozen_string_literal: true

require 'test_helper'

module PayCalculationServices
  class ProcessWorkOrderServiceTest < ActiveSupport::TestCase
    # Only load necessary fixtures
    fixtures :workers, :work_order_rates, :blocks, :users

    setup do
      # Create a fresh work order for testing (not using fixtures to avoid conflicts)
      @work_order_rate = work_order_rates(:one)
      @block = blocks(:one)

      @work_order = WorkOrder.create!(
        work_order_rate: @work_order_rate,
        work_order_status: 'completed',
        start_date: Date.today,
        block: @block,
        created_at: Time.zone.local(2025, 11, 18) # November 2025 to avoid fixture conflicts
      )

      @worker1 = workers(:one)
      @worker2 = workers(:two)
      @service = ProcessWorkOrderService.new(@work_order)
    end

    test 'creates pay calculation for the work order month' do
      @work_order.work_order_workers.create!(
        worker: @worker1,
        rate: 10,
        work_area_size: 100
      )

      assert_difference 'PayCalculation.count', 1 do
        @service.call
      end

      month_year = @work_order.created_at.strftime('%Y-%m')
      pay_calc = PayCalculation.find_by(month_year: month_year)
      assert_not_nil pay_calc
    end

    test 'creates pay calculation details for each worker' do
      @work_order.work_order_workers.create!(
        worker: @worker1,
        rate: 10,
        work_area_size: 100
      )
      @work_order.work_order_workers.create!(
        worker: @worker2,
        rate: 15,
        work_area_size: 50
      )

      assert_difference 'PayCalculationDetail.count', 2 do
        @service.call
      end
    end

    test 'calculates gross salary correctly for normal rate type' do
      @work_order.work_order_workers.create!(
        worker: @worker1,
        rate: 10,
        work_area_size: 100
      )

      @service.call

      month_year = @work_order.created_at.strftime('%Y-%m')
      pay_calc = PayCalculation.find_by(month_year: month_year)
      detail = pay_calc.pay_calculation_details.find_by(worker: @worker1)

      assert_equal 1000.0, detail.gross_salary.to_f # 10 * 100
    end

    test 'calculates gross salary correctly for work_days rate type' do
      work_days_rate = work_order_rates(:work_days)
      work_order = WorkOrder.create!(
        work_order_rate: work_days_rate,
        work_order_status: 'completed',
        work_month: Date.new(2025, 12, 1), # Required for work_days type (Date object)
        created_at: Time.zone.local(2025, 12, 1) # December 2025
      )

      work_order.work_order_workers.create!(
        worker: @worker1,
        rate: 50,
        work_days: 20
      )

      service = ProcessWorkOrderService.new(work_order)
      service.call

      # Find detail from December 2025 pay calculation
      pay_calc = PayCalculation.find_by(month_year: '2025-12')
      detail = pay_calc.pay_calculation_details.find_by(worker: @worker1)

      assert_equal 1000.0, detail.gross_salary.to_f # 50 * 20
    end

    test 'calculates net salary from gross salary minus deductions' do
      @work_order.work_order_workers.create!(
        worker: @worker1,
        rate: 10,
        work_area_size: 100
      )

      @service.call

      detail = PayCalculationDetail.find_by(worker: @worker1)

      # Net salary is calculated automatically via callbacks
      # gross_salary (1000) - worker_deductions (21.25) = 978.75
      expected_net = detail.gross_salary - detail.employee_deductions
      assert_equal expected_net.to_f, detail.net_salary.to_f
    end

    test 'accumulates gross salary for same worker across multiple work orders in same month' do
      # First work order
      @work_order.work_order_workers.create!(
        worker: @worker1,
        rate: 10,
        work_area_size: 100
      )
      @service.call

      # Second work order in same month
      block2 = blocks(:two)
      work_order2 = WorkOrder.create!(
        work_order_rate: @work_order.work_order_rate,
        work_order_status: 'completed',
        created_at: @work_order.created_at,
        start_date: @work_order.start_date,
        block: block2 # Different block to avoid uniqueness constraint
      )
      work_order2.work_order_workers.create!(
        worker: @worker1,
        rate: 10,
        work_area_size: 50
      )

      service2 = ProcessWorkOrderService.new(work_order2)
      service2.call

      month_year = @work_order.created_at.strftime('%Y-%m')
      pay_calc = PayCalculation.find_by(month_year: month_year)
      detail = pay_calc.pay_calculation_details.find_by(worker: @worker1)

      assert_equal 1500.0, detail.gross_salary.to_f # 1000 + 500
    end

    test 'recalculates overall total after processing' do
      @work_order.work_order_workers.create!(
        worker: @worker1,
        rate: 10,
        work_area_size: 100
      )
      @work_order.work_order_workers.create!(
        worker: @worker2,
        rate: 15,
        work_area_size: 50
      )

      @service.call

      month_year = @work_order.created_at.strftime('%Y-%m')
      pay_calc = PayCalculation.find_by(month_year: month_year)

      # Reload to get fresh data from database
      pay_calc.reload

      # total_net_salary should be sum of all net salaries
      expected_total = pay_calc.pay_calculation_details.sum(:net_salary)
      assert_equal expected_total.to_f, pay_calc.total_net_salary.to_f
    end

    test 'returns success result with message' do
      @work_order.work_order_workers.create!(
        worker: @worker1,
        rate: 10,
        work_area_size: 100
      )

      result = @service.call
      assert result.success?
      assert_includes result.value_or(''), @work_order.created_at.strftime('%Y-%m')
    end

    test 'returns success when no workers to process' do
      # No workers added
      result = @service.call
      assert result.success?
      assert_equal 'No workers to process', result.value!
    end

    test 'returns failure on error' do
      @work_order.work_order_workers.create!(
        worker: @worker1,
        rate: 10,
        work_area_size: 100
      )

      # Simulate an error by passing invalid work_order
      invalid_service = ProcessWorkOrderService.new(nil)
      result = invalid_service.call

      assert result.failure?
      assert_includes result.failure, 'Failed to process'
    end
  end
end
