# frozen_string_literal: true

module PayCalculationServices
  class GrossSalaryCalculator
    attr_reader :work_order_worker, :work_order

    def initialize(work_order_worker, work_order)
      @work_order_worker = work_order_worker
      @work_order = work_order
    end

    def calculate
      rate * quantity
    end

    private

    def rate
      work_order_worker.rate || 0
    end

    def quantity
      work_days_based? ? work_days : work_area_size
    end

    def work_days_based?
      work_order.work_order_rate&.work_days?
    end

    def work_days
      work_order_worker.work_days || 0
    end

    def work_area_size
      work_order_worker.work_area_size || 0
    end
  end
end
