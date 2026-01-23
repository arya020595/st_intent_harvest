# frozen_string_literal: true

# ExportHandling Concern
# Standardized export handling for dry-monads Result objects from Exporters
#
# Supports two export formats:
# - CSV: Simple tabular export with headers and rows. Does NOT support extra_locals.
# - PDF: HTML-based export with templates. Supports extra_locals for additional template variables.
#
# Usage:
#   class MyController < ApplicationController
#     include ExportHandling
#
#     def index
#       respond_to do |format|
#         # CSV exports only use records and params
#         format.csv { handle_csv_export(MyServices::ExportCsvService, records, error_path: my_path) }
#
#         # PDF exports can use extra_locals for template variables
#         format.pdf do
#           handle_pdf_export(
#             MyServices::ExportPdfService,
#             records,
#             error_path: my_path,
#             extra_locals: { totals: 123, filters: {...} }
#           )
#         end
#       end
#     end
#   end
module ExportHandling
  extend ActiveSupport::Concern

  # Handle CSV export with dry-monads Result
  #
  # CSV exports generate simple tabular data (headers + rows) and do NOT support extra_locals.
  # All CSV configuration should be in the service class methods: #headers and #row_data
  #
  # @param service_class [Class] The CSV export service class (must inherit from Exporters::CsvExporter)
  # @param records [ActiveRecord::Relation] Records to export
  # @param error_path [String] Path to redirect on export failure
  # @param params [Hash] Additional params (defaults to controller params)
  #
  # @return [void] Sends export file or redirects on error
  #
  # @example
  #   def export_csv
  #     records = @q.result.includes(:block, :mill).ordered
  #     handle_csv_export(
  #       ProductionServices::ExportCsvService,
  #       records,
  #       error_path: productions_path
  #     )
  #   end
  def handle_csv_export(service_class, records, error_path:, params: self.params)
    handle_export(
      service_class.new(records: records, params: params),
      error_path: error_path,
      disposition: 'attachment'
    )
  end

  # Handle PDF export with dry-monads Result
  #
  # PDF exports render HTML templates and support extra_locals for passing additional
  # variables to the template (e.g., totals, filter info, summary data).
  #
  # @param service_class [Class] The PDF export service class (must inherit from Exporters::PdfExporter)
  # @param records [ActiveRecord::Relation] Records to export
  # @param error_path [String] Path to redirect on export failure
  # @param params [Hash] Additional params (defaults to controller params)
  # @param disposition [String] 'inline' to view in browser, 'attachment' to download (default: 'inline')
  # @param extra_locals [Hash] Extra variables to pass to the PDF template (optional, default: {})
  #
  # @return [void] Sends PDF file or redirects on error
  #
  # @example
  #   def export_pdf
  #     records = @q.result.includes(:block, :mill).ordered
  #     totals = { bunches: records.sum(:total_bunches), weight: records.sum(:total_weight_ton) }
  #     handle_pdf_export(
  #       ProductionServices::ExportPdfService,
  #       records,
  #       error_path: productions_path,
  #       extra_locals: { totals: totals, filter_data: {...} }
  #     )
  #   end
  def handle_pdf_export(service_class, records, error_path:, params: self.params, disposition: 'inline',
                        extra_locals: {})
    handle_export(
      service_class.new(records: records, params: params, view_context: self, extra_locals: extra_locals),
      error_path: error_path,
      disposition: disposition
    )
  end

  private

  def handle_export(service, error_path:, disposition: 'attachment')
    result = service.call

    if result.success?
      export_data = result.value!
      send_data(
        export_data[:data],
        filename: export_data[:filename],
        type: export_data[:content_type],
        disposition: disposition
      )
    else
      redirect_to error_path, alert: "Export failed: #{result.failure}"
    end
  end
end
