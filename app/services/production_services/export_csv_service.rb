# frozen_string_literal: true

module ProductionServices
  # CSV Exporter for Productions
  class ExportCsvService < Exporters::CsvExporter
    HEADERS = [
      'Date', 'Ticket Estate No.', 'Ticket Mill No.',
      'Mill', 'Block No.', 'Total Bunches', 'Total Weight (Ton)'
    ].freeze

    protected

    def resource_name
      'productions'
    end

    def headers
      HEADERS
    end

    def row_data(production)
      [
        format_date(production.date),
        safe_value(production.ticket_estate_no),
        safe_value(production.ticket_mill_no),
        production.mill.name,
        production.block.block_number,
        production.total_bunches,
        format_decimal(production.total_weight_ton)
      ]
    end
  end
end
