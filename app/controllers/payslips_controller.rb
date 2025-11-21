class PayslipsController < ApplicationController
  before_action :set_workers, only: %i[index]

  # GET /payslips
  def index
    @payslip_pdf_url = nil

    return unless params[:worker_id].present? && params[:month].present? && params[:year].present?

    @worker = Worker.find_by(id: params[:worker_id])
    month = params[:month].to_i
    year  = params[:year].to_i

    return unless @worker && month.positive? && year.positive?

    @payslip_pdf_url = payslip_path_for_worker(@worker, year, month, format: :pdf)
  end

  # GET /payslips/:id
  def show
    # params[:id] = "workerId-year-month"
    worker_id, year, month = params[:id].split('-').map(&:to_i)
    @worker = Worker.find(worker_id)

    # Format month_year as "YYYY-MM" to match PayCalculation.month_year format
    month_year = format('%04d-%02d', year, month)

    # Find existing pay calculation for the month (created by ProcessWorkOrderService)
    @payslip = PayCalculation.find_by!(month_year: month_year)

    # Find existing pay calculation detail for this worker
    # This was already created by ProcessWorkOrderService when work orders were completed
    @payslip_detail = @payslip.pay_calculation_details.find_by!(worker: @worker)

    # Parse month_year to get the month range for work order details display
    month_date = Date.parse("#{month_year}-01")
    month_start = month_date.beginning_of_month
    month_end = month_date.end_of_month
    @month_year_date = month_date

    # Get work order workers for displaying individual work order details in the earnings table
    # Only include work orders with rate type "normal" or "work_days" and status "completed"
    @work_order_workers = @worker.work_order_workers
                                 .eager_load(work_order: :work_order_rate)
                                 .where(work_orders: { created_at: month_start..month_end,
                                                       work_order_status: 'completed' })
                                 .where(work_order_rates: { work_order_rate_type: %w[normal work_days] })
                                 .includes(work_order: :block)

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
