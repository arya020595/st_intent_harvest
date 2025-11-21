class PayslipsController < ApplicationController
  before_action :set_workers, only: %i[index]
  before_action :set_worker_and_date_params, only: %i[show]
  before_action :load_payslip_data, only: %i[show]

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
    respond_to do |format|
      format.html
      format.pdf do
        render pdf: "payslip_#{@worker.id}_#{@year}_#{@month}",
               template: 'payslips/show',
               formats: :html,
               layout: 'pdf',
               disposition: 'inline'
      end
    end
  end

  private

  # Extract worker and date parameters from route
  def set_worker_and_date_params
    # params[:id] = "workerId-year-month"
    worker_id, @year, @month = params[:id].split('-').map(&:to_i)
    @worker = Worker.find(worker_id)
    @month_year = format('%04d-%02d', @year, @month)
  end

  # Load payslip data using service
  def load_payslip_data
    result = PayslipServices::FetchPayslipDataService.new(
      worker: @worker,
      month_year: @month_year
    ).call

    if result.success?
      data = result.value!
      @payslip = data[:payslip]
      @payslip_detail = data[:payslip_detail]
      @work_order_workers = data[:work_order_workers]
      @month_year_date = data[:month_year_date]
    else
      render_no_payslip_error
    end
  end

  # Prepare a dynamic payslip path for a worker/month/year
  def payslip_path_for_worker(worker, year, month, format: :pdf)
    payslip_path(id: "#{worker.id}-#{year}-#{month}", format: format)
  end

  # Load all workers for dropdown selection
  def set_workers
    @workers = Worker.all
  end

  # Render error message when no payslip data exists
  def render_no_payslip_error
    error_message = build_error_message

    respond_to do |format|
      format.html { render html: error_message.html_safe, status: :not_found }
      format.pdf { render html: error_message.html_safe, status: :not_found }
    end
  end

  # Build error message HTML
  def build_error_message
    month_name = Date.parse("#{@month_year}-01").strftime('%B %Y')
    worker_name = ERB::Util.html_escape(@worker.name)

    <<~HTML
      <h1>No Payslip Available</h1>
      <p>No payslip data found for #{worker_name} in #{month_name}.#{' '}
      Please ensure work orders have been completed and processed for this month.</p>
    HTML
  end
end
