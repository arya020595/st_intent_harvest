# frozen_string_literal: true

module Exporters
  # Shared formatting helpers for all exporters
  # Follows Interface Segregation - only formatting concerns
  module FormatHelpers
    def format_date(date, format = '%d-%m-%Y')
      date&.strftime(format)
    end

    def format_decimal(value, precision = 2)
      return nil if value.nil?

      format("%.#{precision}f", value)
    end

    def format_currency(value)
      format_decimal(value, 2)
    end

    def safe_value(value, default = '-')
      value.presence || default
    end

    def number_with_delimiter(number)
      return '0' if number.nil?

      number.to_s.reverse.gsub(/(\d{3})(?=\d)/, '\\1,').reverse
    end
  end
end
