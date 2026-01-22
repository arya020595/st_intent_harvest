# frozen_string_literal: true

module ProductionServices
  # PDF Exporter for Productions
  class ExportPdfService < Exporters::PdfExporter
    protected

    def resource_name
      'productions'
    end

    def template_path
      'productions/index'
    end

    def template_locals
      {
        productions: @records,
        params: @params,
        totals: @extra_locals[:totals] || {},
        filter_data: @extra_locals[:filter_data] || {}
      }
    end
  end
end
