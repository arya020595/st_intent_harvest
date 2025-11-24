# frozen_string_literal: true

module PayslipServices
  # Service responsible for generating a payslip PDF from rendered HTML.
  # Keeps PDF generation concerns (Grover interaction, optional debug persistence)
  # out of the controller so controllers remain thin.
  class GeneratePayslipPdfService
    Result = Struct.new(:pdf_bytes, :debug_path, keyword_init: true)

    def initialize(html:, worker:, year:, month:, save_debug: default_debug?)
      @html       = html
      @worker     = worker
      @year       = year
      @month      = month
      @save_debug = save_debug
    end

    def call
      grover = Grover.new(@html)
      pdf_bytes = grover.to_pdf
      debug_path = @save_debug ? persist_debug_copy(pdf_bytes) : nil

      Rails.logger.info(
        "Payslip PDF generated worker=#{@worker.id} year=#{@year} month=#{@month} bytes=#{pdf_bytes.bytesize}"
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

    def persist_debug_copy(bytes)
      path = Rails.root.join('tmp', "payslip_#{@worker.id}_#{@year}_#{@month}.pdf")
      File.binwrite(path, bytes)
      path
    rescue IOError, Errno::ENOENT, Errno::EACCES, Errno::ENOSPC => e
      Rails.logger.warn("Failed to write debug payslip PDF: #{e.class}: #{e.message}")
      nil
    end

    def default_debug?
      ENV.fetch('PAYSLIP_PDF_DEBUG', Rails.env.development?.to_s) == 'true'
    end
  end
end
