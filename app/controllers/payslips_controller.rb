class PayslipsController < ApplicationController
  before_action :set_workers, only: %i[index]
  before_action :set_worker_and_date_params, only: %i[show]

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
    data_result = PayslipServices::FetchPayslipDataService.new(worker: @worker, month_year: @month_year).call
    if data_result.failure?
      render_no_payslip_error and return
    end

    data = data_result.value!
    @payslip         = data[:payslip]
    @payslip_detail  = data[:payslip_detail]
    @work_order_workers = data[:work_order_workers]
    @month_year_date = data[:month_year_date]

    respond_to do |format|
      format.html
      format.pdf { render_payslip_pdf }
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

  # (Removed load_payslip_data before_action – now inlined inside show for clarity.)

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

  # Extracted PDF rendering logic to keep action thin
  def render_payslip_pdf
    html = render_to_string(template: 'payslips/show', layout: 'pdf', formats: :html)
    service_result = PayslipServices::GeneratePayslipPdfService.new(
      html: html,
      worker: @worker,
      year: @year,
      month: @month
    ).call

    send_data service_result.pdf_bytes,
              filename: "payslip_#{@worker.id}_#{@year}_#{@month}.pdf",
              type: 'application/pdf',
              disposition: 'inline'
  rescue => e
    Rails.logger.error "Payslip PDF service failure: #{e.message}"
    render html: '<h1>PDF Generation Error</h1><p>Please try again later.</p>'.html_safe, status: :internal_server_error
  end
end
