# frozen_string_literal: true

# ExportHandling Concern
# Standardized export handling for dry-monads Result objects from Exporters
#
# Usage:
#   class MyController < ApplicationController
#     include ExportHandling
#
#     def index
#       respond_to do |format|
#         format.csv { handle_csv_export(MyServices::ExportCsvService, records, error_path: my_path) }
#         format.pdf { handle_pdf_export(MyServices::ExportPdfService, records, error_path: my_path) }
#       end
#     end
#   end
module ExportHandling
  extend ActiveSupport::Concern

  # Handle CSV export with dry-monads Result
  # @param service_class [Class] The CSV export service class
  # @param records [ActiveRecord::Relation] Records to export
  # @param error_path [String] Path to redirect on failure
  # @param params [Hash] Additional params (defaults to controller params)
  # @param extra_locals [Hash] Extra locals to pass to the view
  def handle_csv_export(service_class, records, error_path:, params: self.params, extra_locals: {})
    handle_export(
      service_class.new(records: records, params: params, extra_locals: extra_locals),
      error_path: error_path,
      disposition: 'attachment'
    )
  end

  # Handle PDF export with dry-monads Result
  # @param service_class [Class] The PDF export service class
  # @param records [ActiveRecord::Relation] Records to export
  # @param error_path [String] Path to redirect on failure
  # @param params [Hash] Additional params (defaults to controller params)
  # @param disposition [String] 'inline' to view in browser, 'attachment' to download
  # @param extra_locals [Hash] Extra locals to pass to the view
  def handle_pdf_export(service_class, records, error_path:, params: self.params, disposition: 'inline', extra_locals: {})
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
