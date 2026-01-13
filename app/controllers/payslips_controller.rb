# frozen_string_literal: true

class PayslipsController < ApplicationController
  before_action :set_workers, only: %i[index]
  before_action :set_worker_and_date_params, only: %i[show]

  # GET /payslips
  def index
    respond_to do |format|
      format.html do
        @payslip_pdf_url = nil
        return unless params[:worker_ids].present? && params[:month].present? && params[:year].present?

        month = params[:month].to_i
        year  = params[:year].to_i
        worker_ids = params[:worker_ids].map(&:to_i)

        @workers = Worker.where(id: worker_ids)
        return if @workers.empty? || month <= 0 || year <= 0

        combined_html = @workers.map do |worker|
          data_result = PayslipServices::FetchPayslipDataService.new(
            worker: worker,
            month_year: format('%04d-%02d', year, month)
          ).call

          next unless data_result.success?

          data = data_result.value!
          render_to_string(
            template: 'payslips/show',
            layout: 'pdf',
            formats: :html,
            locals: {
              worker: worker,
              payslip: data[:payslip],
              payslip_detail: data[:payslip_detail],
              work_order_workers: data[:work_order_workers],
              month_year_date: data[:month_year_date]
            }
          )
        end.compact.join("<div style='page-break-after: always;'></div>")

        if combined_html.present?
          service_result = PayslipServices::GeneratePayslipPdfService.new(
            html: combined_html,
            worker: nil,
            year: year,
            month: month
          ).call

          temp_pdf_path = Rails.root.join('tmp', "combined_payslips_#{Time.now.to_i}.pdf")
          File.binwrite(temp_pdf_path, service_result.pdf_bytes)
          @payslip_pdf_url = "/tmp/#{File.basename(temp_pdf_path)}"
        end
      end

      format.pdf do
        unless params[:worker_ids].present? && params[:month].present? && params[:year].present?
          return head :bad_request
        end

        month = params[:month].to_i
        year  = params[:year].to_i
        worker_ids = params[:worker_ids].map(&:to_i)
        @workers = Worker.where(id: worker_ids)
        return head :not_found if @workers.empty?

        combined_html = @workers.map do |worker|
          data_result = PayslipServices::FetchPayslipDataService.new(
            worker: worker,
            month_year: format('%04d-%02d', year, month)
          ).call

          next unless data_result.success?

          data = data_result.value!
          render_to_string(
            template: 'payslips/show',
            layout: 'pdf',
            formats: :html,
            locals: {
              worker: worker,
              payslip: data[:payslip],
              payslip_detail: data[:payslip_detail],
              work_order_workers: data[:work_order_workers],
              month_year_date: data[:month_year_date]
            }
          )
        end.compact.join("<div style='page-break-after: always;'></div>")

        render html: '<h1>No payslips available</h1>'.html_safe, status: :not_found and return if combined_html.blank?

        service_result = PayslipServices::GeneratePayslipPdfService.new(
          html: combined_html,
          worker: nil,
          year: year,
          month: month
        ).call

        send_data service_result.pdf_bytes,
                  filename: "combined_payslips_#{month}_#{year}.pdf",
                  type: 'application/pdf',
                  disposition: 'inline' and return
      end
    end
  end

  private

  # Extract worker and date from params[:id] (format: "workerId-year-month")
  def set_worker_and_date_params
    worker_id, @year, @month = params[:id].split('-').map(&:to_i)
    @worker = Worker.find(worker_id)
    @month_year = format('%04d-%02d', @year, @month)
  end

  # Generate dynamic payslip URL
  def payslip_path_for_worker(worker, year, month, format: :pdf)
    payslip_path(id: "#{worker.id}-#{year}-#{month}", format: format)
  end

  # Load workers for dropdown
  def set_workers
    @workers = Worker.all
  end

  # Show error if no payslip data
  def render_no_payslip_error
    error_message = build_error_message

    respond_to do |format|
      format.html { render html: error_message.html_safe, status: :not_found }
      format.pdf  { render html: error_message.html_safe, status: :not_found }
    end
  end

  # Build error message HTML
  def build_error_message
    month_name = Date.parse("#{@month_year}-01").strftime('%B %Y')
    worker_name = ERB::Util.html_escape(@worker.name)

    <<~HTML
      <h1>No Payslip Available</h1>
      <p>No payslip data found for #{worker_name} in #{month_name}.
      Please ensure work orders have been completed and processed for this month.</p>
    HTML
  end

  # PDF rendering logic
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
  rescue Grover::Error, Grover::JavaScript::Error, ActionView::Template::Error => e
    Rails.logger.error "Payslip PDF service failure: #{e.class}: #{e.message}"
    render_pdf_error
  rescue StandardError => e
    Rails.logger.error "Unexpected error during PDF generation: #{e.class}: #{e.message}"
    render_pdf_error
  end

  # PDF fallback error page
  def render_pdf_error
    render html: '<h1>PDF Generation Error</h1><p>Please try again later.</p>'.html_safe,
           status: :internal_server_error
  end
end
