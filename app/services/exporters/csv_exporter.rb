# frozen_string_literal: true

require 'csv'

module Exporters
  # Generic CSV Exporter
  #
  # Subclasses must implement: #resource_name, #headers, #row_data
  #
  # @example
  #   class MyServices::ExportCsvService < Exporters::CsvExporter
  #     def resource_name; 'items'; end
  #     def headers; ['Name', 'Value']; end
  #     def row_data(item); [item.name, item.value]; end
  #   end
  class CsvExporter < BaseExporter
    protected

    def generate_export
      CSV.generate(headers: true, encoding: 'UTF-8') do |csv|
        csv << headers
        @records.find_each { |record| csv << row_data(record) }
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
