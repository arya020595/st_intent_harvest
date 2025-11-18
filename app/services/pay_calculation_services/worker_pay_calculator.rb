# frozen_string_literal: true

module PayCalculationServices
  class WorkerPayCalculator
    DEFAULT_CURRENCY = 'RM'

    attr_reader :pay_calculation, :work_order_worker, :work_order

    def initialize(pay_calculation, work_order_worker, work_order)
      @pay_calculation = pay_calculation
      @work_order_worker = work_order_worker
      @work_order = work_order
    end

    def process
      detail = find_or_initialize_detail
      accumulate_gross_salary(detail)
      detail.save!
    end

    private

    def find_or_initialize_detail
      pay_calculation.pay_calculation_details.find_or_initialize_by(
        worker_id: work_order_worker.worker_id
      ) do |detail|
        detail.currency = DEFAULT_CURRENCY
      end
    end

    def accumulate_gross_salary(detail)
      detail.gross_salary = (detail.gross_salary || 0) + calculated_gross_salary
    end

    def calculated_gross_salary
      @calculated_gross_salary ||= GrossSalaryCalculator.new(work_order_worker, work_order).calculate
    end
  end
end
