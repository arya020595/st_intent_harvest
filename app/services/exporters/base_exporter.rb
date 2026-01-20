# frozen_string_literal: true

module Exporters
  # Abstract Base Exporter - Template Method Pattern with Dry::Monads
  #
  # Returns Success/Failure monads for consistent error handling.
  # Subclasses implement: #generate_export, #generate_filename, #content_type, #file_extension
  #
  # @example
  #   result = MyExporter.new(records: records).call
  #   result.success? # => true
  #   result.value!   # => { data: "...", filename: "...", content_type: "..." }
  class BaseExporter
    include Dry::Monads[:result]
    include FormatHelpers

    def initialize(records:, params: {}, **options)
      @records = records
      @params = params
      @options = options
    end

    def call
      validate_records!
      Success(
        data: generate_export,
        filename: generate_filename,
        content_type: content_type
      )
    rescue StandardError => e
      handle_error(e)
    end

    protected

    def generate_export
      raise NotImplementedError, "#{self.class} must implement #generate_export"
    end

    def generate_filename
      raise NotImplementedError, "#{self.class} must implement #generate_filename"
    end

    def content_type
      raise NotImplementedError, "#{self.class} must implement #content_type"
    end

    def file_extension
      raise NotImplementedError, "#{self.class} must implement #file_extension"
    end

    def resource_name
      raise NotImplementedError, "#{self.class} must implement #resource_name"
    end

    def build_filename(prefix)
      suffix = date_range_suffix || Date.current.strftime('%Y%m%d')
      "#{prefix}-#{suffix}.#{file_extension}"
    end

    private

    def validate_records!
      raise ArgumentError, 'Records cannot be nil' if @records.nil?
    end

    def handle_error(error)
      Rails.logger.error("[#{self.class}] #{error.message}")
      Failure(error.message)
    end

    def date_range_suffix
      start_date = @params.dig(:q, :date_gteq)
      end_date = @params.dig(:q, :date_lteq)

      return nil unless start_date.present? || end_date.present?

      start_text = start_date.present? ? Date.parse(start_date).strftime('%d-%m-%Y') : 'All'
      end_text = end_date.present? ? Date.parse(end_date).strftime('%d-%m-%Y') : 'All'

      "#{start_text}_to_#{end_text}"
    end
  end
end
