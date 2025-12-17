# frozen_string_literal: true

module PayslipServices
  # Service responsible for generating a payslip PDF from rendered HTML.
  # Keeps PDF generation concerns (Grover interaction, optional debug persistence)
  # out of the controller so controllers remain thin.
  class GeneratePayslipPdfService
    Result = Struct.new(:pdf_bytes, :debug_path, keyword_init: true)

    # @param html [String] the HTML to convert to PDF
    # @param worker [Worker, nil] the worker object (nil for multi-worker PDF)
    # @param year [Integer] the year of the payslip
    # @param month [Integer] the month of the payslip
    # @param save_debug [Boolean] whether to persist a debug copy of the PDF
    def initialize(html:, worker:, year:, month:, save_debug: default_debug?)
      @html       = html
      @worker     = worker
      @year       = year
      @month      = month
      @save_debug = save_debug
    end

    # Generate the PDF bytes, optionally saving a debug copy
    # @return [Result] PDF bytes and debug path
    def call
      grover = Grover.new(@html)
      pdf_bytes = grover.to_pdf
      debug_path = @save_debug ? persist_debug_copy(pdf_bytes) : nil

      # Use 'multiple' if no single worker is specified
      worker_id = @worker&.id || 'multiple'

      Rails.logger.info(
        "Payslip PDF generated worker=#{worker_id} year=#{@year} month=#{@month} bytes=#{pdf_bytes.bytesize}"
      )

      Result.new(pdf_bytes: pdf_bytes, debug_path: debug_path)
    rescue Grover::Error, Grover::JavaScript::Error => e
      Rails.logger.error(
        "Payslip PDF generation failed: #{e.class}: #{e.message}\n" \
        "  #{Array(e.backtrace).first(5).join("\n  ")}"
      )
      raise e # Let caller decide fallback behaviour
    end

    private

    # Persist a debug copy of the PDF to tmp directory
    # @param bytes [String] the PDF bytes
    # @return [Pathname, nil] path to saved debug PDF
    def persist_debug_copy(bytes)
      # Handle nil worker for multi-worker PDFs
      worker_id = @worker&.id || 'multiple'
      path = Rails.root.join('tmp', "payslip_#{worker_id}_#{@year}_#{@month}.pdf")
      File.binwrite(path, bytes)
      path
    rescue IOError, Errno::ENOENT, Errno::EACCES, Errno::ENOSPC => e
      Rails.logger.warn("Failed to write debug payslip PDF: #{e.class}: #{e.message}")
      nil
    end

    # Determine whether debug persistence should be enabled
    # Defaults to development environment unless overridden by ENV
    def default_debug?
      ENV.fetch('PAYSLIP_PDF_DEBUG', Rails.env.development?.to_s) == 'true'
    end
  end
end
