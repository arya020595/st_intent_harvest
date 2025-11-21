class PayslipsController < ApplicationController
  before_action :set_workers, only: %i[index]

  # GET /payslips
  def index
    @payslip_pdf_url = nil

    if params[:worker_id].present? && params[:month].present? && params[:year].present?
      @worker = Worker.find_by(id: params[:worker_id])
      month = params[:month].to_i
      year  = params[:year].to_i

      if @worker && month.positive? && year.positive?
        start_date = Date.new(year, month, 1)
        end_date   = start_date.end_of_month

        # Include full days range for filtering
        @work_orders = @worker.work_orders.where(created_at: start_date.beginning_of_day..end_date.end_of_day)

        @payslip_pdf_url = payslip_path_for_worker(@worker, year, month, format: :pdf)
      end
    end
  end

  # GET /payslips/:id
  def show
    # params[:id] = "workerId-year-month"
    worker_id, year, month = params[:id].split('-').map(&:to_i)
    @worker = Worker.find(worker_id)

    start_date = Date.new(year, month, 1)
    end_date   = start_date.end_of_month

    # Correct date range with full days for work orders
    @work_orders = @worker.work_orders.where(created_at: start_date.beginning_of_day..end_date.end_of_day)

    # Find or create the month-level pay calculation
    @payslip = PayCalculation.find_or_create_by!(month_year: start_date)

    # Then find or create the worker-specific details
    @payslip_detail = PayCalculationDetail.find_or_create_by!(
      pay_calculation: @payslip,
      worker: @worker
    )

    @month_year_date = start_date

    respond_to do |format|
      format.html
      format.pdf do
        render pdf: "payslip_#{@worker.id}_#{year}_#{month}",
               template: 'payslips/show',
               formats: :html,
               layout: 'pdf',
               disposition: 'inline'
      end
    end
  end

  private

  # Prepare a dynamic payslip path for a worker/month/year
  def payslip_path_for_worker(worker, year, month, format: :pdf)
    payslip_path(id: "#{worker.id}-#{year}-#{month}", format: format)
  end

  # Load all workers for dropdown selection
  def set_workers
    @workers = Worker.all
  end
end
