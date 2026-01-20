# frozen_string_literal: true

require 'csv'

module Exporters
  # CSV Exporter - Simple tabular export format
  #
  # CSV exports generate basic headers and row data. Unlike PdfExporter,
  # CSV exports do NOT support extra_locals parameter because:
  # - CSV format is plain text with no template rendering capability
  # - All data must be expressible as simple tabular rows
  # - Extra locals (template variables) are not applicable to CSV generation
  #
  # Subclasses must implement: #resource_name, #headers, #row_data
  #
  # NOTE: Unlike handle_pdf_export, handle_csv_export should NOT pass extra_locals
  # as they will be silently ignored. CSV configuration must be done via:
  # - #resource_name: For filename generation
  # - #headers: For column headers
  # - #row_data: For row data extraction
  #
  # @example
  #   class MyServices::ExportCsvService < Exporters::CsvExporter
  #     def resource_name; 'items'; end
  #     def headers; ['Name', 'Value']; end
  #     def row_data(item); [item.name, item.value]; end
  #   end
  #
  # @see Exporters::PdfExporter for template-based exports supporting extra_locals
  class CsvExporter < BaseExporter
    protected

    def generate_export
      CSV.generate(headers: true, encoding: 'UTF-8') do |csv|
        csv << headers
        # Use each instead of find_each to preserve ordering
        # find_each ignores ORDER BY clauses for batch processing efficiency
        @records.each { |record| csv << row_data(record) }
      end
    end

    def generate_filename
      build_filename(resource_name)
    end

    def content_type
      'text/csv'
    end

    def file_extension
      'csv'
    end

    def headers
      raise NotImplementedError, "#{self.class} must implement #headers"
    end

    def row_data(_record)
      raise NotImplementedError, "#{self.class} must implement #row_data"
    end
  end
end
