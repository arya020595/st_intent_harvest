# frozen_string_literal: true

module PayCalculationServices
  # ReverseWorkOrderService - Reverses pay calculations when a work order is deleted
  #
  # This service is triggered when a completed work order is soft-deleted (discarded).
  # It recalculates the affected workers' pay by:
  # 1. Finding the PayCalculation for the work order's completion month
  # 2. Recalculating each affected worker's earnings from remaining active work orders
  # 3. Updating or removing PayCalculationDetail records
  # 4. Recalculating the overall totals
  #
  # Usage:
  #   PayCalculationServices::ReverseWorkOrderService.new(work_order).call
  #
  class ReverseWorkOrderService
    include Dry::Monads[:result]

    MONTH_YEAR_FORMAT = '%Y-%m'

    attr_reader :work_order

    def initialize(work_order)
      @work_order = work_order
    end

    def call
      return Success('Not completed') unless work_order.completed?
      return Success('No completion date') unless work_order.completion_date.present?
      return Success('Resource-only work order, no pay calculation impact') if resource_only?

      pay_calc = find_pay_calculation
      return Success('No pay calculation found') unless pay_calc

      ActiveRecord::Base.transaction do
        recalculate_affected_workers(pay_calc)
        update_or_destroy_pay_calculation(pay_calc)
      end

      Success("Reversed pay calculation for #{month_year}")
    rescue StandardError => e
      Failure("Failed to reverse: #{e.message}")
    end

    private

    def resource_only?
      work_order.work_order_rate_type == 'resources'
    end

    def month_year
      @month_year ||= work_order.completion_date.strftime(MONTH_YEAR_FORMAT)
    end

    def month_range
      @month_range ||= begin
        month_start = Date.parse("#{month_year}-01")
        month_start..month_start.end_of_month
      end
    end

    def find_pay_calculation
      PayCalculation.find_by(month_year: month_year)
    end

    def affected_worker_ids
      @affected_worker_ids ||= work_order.work_order_workers.pluck(:worker_id)
    end

    def recalculate_affected_workers(pay_calc)
      # Batch load all affected workers' pay calculation details to avoid N+1
      details_by_worker = pay_calc.pay_calculation_details
                                  .where(worker_id: affected_worker_ids)
                                  .index_by(&:worker_id)

      # Calculate active earnings for all affected workers in a single query
      active_earnings_by_worker = calculate_active_earnings_batch

      # Process each affected worker
      affected_worker_ids.each do |worker_id|
        detail = details_by_worker[worker_id]
        next unless detail

        active_earnings = active_earnings_by_worker[worker_id] || 0

        if active_earnings.zero?
          # Worker has no remaining earnings for this month - remove the detail
          AppLogger.info("ReverseWorkOrderService: Removing PayCalculationDetail for Worker ##{worker_id}")
          detail.destroy!
        else
          # Update with recalculated earnings
          old_gross = detail.gross_salary
          detail.update!(gross_salary: active_earnings)
          detail.recalculate_deductions!
          AppLogger.info("ReverseWorkOrderService: Updated Worker ##{worker_id}: #{old_gross} -> #{active_earnings}")
        end
      end
    end

    # Calculate active earnings for all affected workers in a single query
    # Returns a hash of { worker_id => total_amount }
    def calculate_active_earnings_batch
      WorkOrderWorker
        .joins(:work_order)
        .where(worker_id: affected_worker_ids)
        .where.not(work_order_id: work_order.id)
        .merge(WorkOrder.kept) # Only non-discarded work orders
        .where(work_orders: {
                 work_order_status: 'completed',
                 completion_date: month_range
               })
        .group(:worker_id)
        .sum(:amount)
    end

    def update_or_destroy_pay_calculation(pay_calc)
      pay_calc.reload

      if pay_calc.pay_calculation_details.exists?
        # Recalculate totals
        pay_calc.recalculate_overall_total!
        AppLogger.info("ReverseWorkOrderService: Updated PayCalculation ##{pay_calc.id} for #{month_year}")
      else
        # No more details - remove the empty pay calculation
        AppLogger.info("ReverseWorkOrderService: Removing empty PayCalculation ##{pay_calc.id}")
        pay_calc.destroy!
      end
    end
  end
end
