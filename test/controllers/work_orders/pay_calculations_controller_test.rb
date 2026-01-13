# frozen_string_literal: true

require 'test_helper'

module WorkOrders
  class PayCalculationsControllerWorkerDetailTest < ActionDispatch::IntegrationTest
    fixtures :workers, :work_order_rates, :blocks, :users

    setup do
      @work_order_rate = work_order_rates(:one)
      @block = blocks(:one)
      @worker1 = workers(:one)
      @worker2 = workers(:two)
      @user = users(:admin)

      # Set completion date
      @completion_date = Date.new(2025, 11, 18)
      @month_year = @completion_date.strftime('%Y-%m')
      @month_start = @completion_date.beginning_of_month

      # Create first completed work order with workers
      @work_order1 = WorkOrder.create!(
        work_order_rate: @work_order_rate,
        work_order_status: 'completed',
        start_date: @month_start,
        completion_date: @completion_date,
        block: @block
      )

      @work_order_worker1_wo1 = @work_order1.work_order_workers.create!(
        worker: @worker1,
        rate: 10,
        work_area_size: 100 # amount = 1000
      )

      # Create second completed work order for same worker
      @work_order2 = WorkOrder.create!(
        work_order_rate: @work_order_rate,
        work_order_status: 'completed',
        start_date: @month_start + 5.days,
        completion_date: @completion_date + 2.days,
        block: @block
      )

      @work_order_worker1_wo2 = @work_order2.work_order_workers.create!(
        worker: @worker1,
        rate: 15,
        work_area_size: 50 # amount = 750
      )

      # Process pay calculations
      PayCalculationServices::ProcessWorkOrderService.new(@work_order1).call
      PayCalculationServices::ProcessWorkOrderService.new(@work_order2).call

      @pay_calc = PayCalculation.find_by(month_year: @month_year)
      @pay_calc_detail = @pay_calc.pay_calculation_details.find_by(worker: @worker1)

      # Sign in
      sign_in_as(@user)
    end

    test 'worker_detail excludes discarded work orders from displayed work_order_workers' do
      # Initially both work orders should be shown
      get worker_detail_work_orders_pay_calculation_path(@pay_calc, worker_id: @worker1.id)
      assert_response :success

      # Both work order workers should be visible
      assert_select 'td.text-center', text: @work_order1.id.to_s
      assert_select 'td.text-center', text: @work_order2.id.to_s

      # Soft delete the first work order
      @work_order1.discard

      # Now only the second work order should be shown
      get worker_detail_work_orders_pay_calculation_path(@pay_calc, worker_id: @worker1.id)
      assert_response :success

      # Only work_order2 should be visible
      assert_select 'td.text-center', text: @work_order2.id.to_s
      # work_order1 should not be visible
      assert_select 'td.text-center', text: @work_order1.id.to_s, count: 0
    end

    test 'worker_detail excludes discarded work_order_workers' do
      # Soft delete just the work_order_worker from first work order
      @work_order_worker1_wo1.update_columns(discarded_at: Time.current)

      get worker_detail_work_orders_pay_calculation_path(@pay_calc, worker_id: @worker1.id)
      assert_response :success

      # Only work_order2's worker should be visible
      assert_select 'td.text-center', text: @work_order2.id.to_s
      # work_order1's entry should not be visible (work_order_worker is discarded)
      assert_select 'td.text-center', text: @work_order1.id.to_s, count: 0
    end

    test 'worker_detail shows correct sum from kept work orders only' do
      # Initially total should be 1750 (1000 + 750)
      get worker_detail_work_orders_pay_calculation_path(@pay_calc, worker_id: @worker1.id)
      assert_response :success

      # Check the sum is shown (1,750.00)
      assert_select 'td.text-end strong', text: /1,750\.00/

      # Soft delete the first work order
      @work_order1.discard

      get worker_detail_work_orders_pay_calculation_path(@pay_calc, worker_id: @worker1.id)
      assert_response :success

      # Sum should now only show 750 (from kept work order)
      assert_select 'td.text-end strong', text: /750\.00/
      # Should NOT show 1,750.00 anymore
      assert_select 'td.text-end strong', text: /1,750\.00/, count: 0
    end

    test 'worker_detail shows no work orders message when all are discarded' do
      # Soft delete both work orders
      @work_order1.discard
      @work_order2.discard

      get worker_detail_work_orders_pay_calculation_path(@pay_calc, worker_id: @worker1.id)
      assert_response :success

      # Should show "No work orders found" message
      assert_select 'td', text: /No work orders found for this worker/
    end

    private

    def sign_in_as(user)
      post user_session_path, params: {
        user: { email: user.email, password: 'password' }
      }
    end
  end
end
