# frozen_string_literal: true

module WorkOrders
  class PayCalculationsController < ApplicationController
    include RansackMultiSort

    before_action :set_pay_calculation, only: %i[show edit update destroy]
    before_action :set_pay_calculation_with_discarded, only: %i[worker_detail]
    before_action :set_worker, only: %i[worker_detail]

    def index
      authorize PayCalculation, policy_class: WorkOrders::PayCalculationPolicy

      apply_ransack_search(policy_scope(PayCalculation,
                                        policy_scope_class: WorkOrders::PayCalculationPolicy::Scope).order(id: :desc))

      @pagy, @pay_calculations = paginate_results(@q.result)
    end

    def show
      authorize @pay_calculation, policy_class: WorkOrders::PayCalculationPolicy

      apply_ransack_search(@pay_calculation.pay_calculation_details.includes(:worker).order(id: :asc))

      @pagy, @pay_calculation_details = paginate_results(@q.result)
    end

    def new
      @pay_calculation = PayCalculation.new
      authorize @pay_calculation, policy_class: WorkOrders::PayCalculationPolicy
    end

    def create
      @pay_calculation = PayCalculation.new(pay_calculation_params)
      authorize @pay_calculation, policy_class: WorkOrders::PayCalculationPolicy

      # Logic to be implemented later
    end

    def edit
      authorize @pay_calculation, policy_class: WorkOrders::PayCalculationPolicy
    end

    def update
      authorize @pay_calculation, policy_class: WorkOrders::PayCalculationPolicy

      # Logic to be implemented later
    end

    def destroy
      authorize @pay_calculation, policy_class: WorkOrders::PayCalculationPolicy

      # Logic to be implemented later
    end

    def worker_detail
      authorize @pay_calculation, policy_class: WorkOrders::PayCalculationPolicy

      @pay_calculation_detail = @pay_calculation.pay_calculation_details.find_by(worker: @worker)

      # Parse month_year to get the month range
      # month_year format is "YYYY-MM" (e.g., "2025-11")
      month_date = Date.parse("#{@pay_calculation.month_year}-01")
      month_start = month_date.beginning_of_month
      month_end = month_date.end_of_month

      # Get all work order workers for this worker created in the pay calculation month
      # Only include non-discarded (kept) work orders and work_order_workers
      @work_order_workers = @worker.work_order_workers
                                   .where(discarded_at: nil)
                                   .joins(:work_order)
                                   .merge(WorkOrder.kept)
                                   .where(work_orders: {
                                            completion_date: month_start..month_end,
                                            work_order_status: 'completed',
                                            work_order_rate_type: %w[normal work_days]
                                          })
    end

    private

    def set_pay_calculation
      @pay_calculation = PayCalculation.find(params[:id])
    end

    def set_pay_calculation_with_discarded
      @pay_calculation = PayCalculation.with_discarded.find(params[:id])
    end

    def set_worker
      @worker = Worker.find(params[:worker_id])
    end

    def pay_calculation_params
      params.require(:pay_calculation).permit(
        :month_year,
        :overall_total
      )
    end
  end
end
