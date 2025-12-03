# frozen_string_literal: true

module PayslipServices
  class FetchPayslipDataService
    include Dry::Monads[:result]

    attr_reader :worker, :month_year

    def initialize(worker:, month_year:)
      @worker = worker
      @month_year = month_year
    end

    def call
      month_year_date = parse_month_year_date

      pay_calculation = PayCalculation.find_by(month_year: month_year)
      return Failure(:no_pay_calculation) unless pay_calculation

      pay_calculation_detail = pay_calculation.pay_calculation_details.find_by(worker: worker)
      return Failure(:no_worker_detail) unless pay_calculation_detail

      Success(
        payslip: pay_calculation,
        payslip_detail: pay_calculation_detail,
        work_order_workers: fetch_work_order_workers(month_year_date),
        month_year_date: month_year_date
      )
    end

    private

    def fetch_work_order_workers(month_date)
      month_start = month_date.beginning_of_month
      month_end = month_date.end_of_month

      worker.work_order_workers
            .joins(:work_order)
            .where(work_orders: {
                     completion_date: month_start..month_end,
                     work_order_status: 'completed',
                     work_order_rate_type: %w[normal work_days]
                   })
    end

    def parse_month_year_date
      Date.parse("#{month_year}-01")
    end
  end
end
