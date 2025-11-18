# frozen_string_literal: true

module PayCalculationServices
  class ProcessWorkOrderService
    include Dry::Monads[:result]

    MONTH_YEAR_FORMAT = '%Y-%m'

    attr_reader :work_order

    def initialize(work_order)
      @work_order = work_order
    end

    def call
      return Success('Resource-only work order, no pay calculation needed') if resource_only?
      return Success('No workers to process') if no_workers_to_process?

      ActiveRecord::Base.transaction do
        pay_calculation = find_or_create_pay_calculation
        process_all_workers(pay_calculation)
        pay_calculation.recalculate_overall_total!

        Success("Pay calculation processed successfully for #{month_year}")
      end
    rescue StandardError => e
      Failure("Failed to process pay calculation: #{e.message}")
    end

    private

    def resource_only?
      work_order.work_order_rate&.resources?
    end

    def no_workers_to_process?
      work_order.work_order_workers.empty?
    end

    def month_year
      @month_year ||= work_order.created_at.strftime(MONTH_YEAR_FORMAT)
    end

    def find_or_create_pay_calculation
      PayCalculation.find_or_create_for_month(month_year)
    end

    def process_all_workers(pay_calculation)
      work_order.work_order_workers.includes(:worker).find_each do |work_order_worker|
        WorkerPayCalculator.new(pay_calculation, work_order_worker, work_order).process
      end
    end
  end
end
