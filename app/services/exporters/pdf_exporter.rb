# frozen_string_literal: true

module Exporters
  # Generic PDF Exporter using Grover
  #
  # Subclasses must implement: #resource_name, #template_path, #template_locals
  #
  # @example
  #   class MyServices::ExportPdfService < Exporters::PdfExporter
  #     def resource_name; 'items'; end
  #     def template_path; 'items/index'; end
  #     def template_locals; { items: @records, params: @params }; end
  #   end
  class PdfExporter < BaseExporter
    def initialize(records:, params: {}, view_context:, **options)
      super(records: records, params: params, **options)
      @view_context = view_context
    end

    protected

    def generate_export
      html = render_template
      Grover.new(html, **pdf_options).to_pdf
    end

    def generate_filename
      build_filename(resource_name)
    end

    def content_type
      'application/pdf'
    end

    def file_extension
      'pdf'
    end

    def template_path
      raise NotImplementedError, "#{self.class} must implement #template_path"
    end

    def template_locals
      { records: @records, params: @params }
    end

    # Override in subclass to customize PDF options
    def pdf_options
      {
        format: 'A4',
        landscape: landscape?,
        margin: { top: '10mm', bottom: '10mm', left: '10mm', right: '10mm' },
        print_background: true
      }
    end

    # Override in subclass: true for landscape, false for portrait
    def landscape?
      true
    end

    private

    def render_template
      @view_context.render_to_string(
        template: template_path,
        formats: [:pdf],
        layout: false,
        locals: template_locals
      )
    end
  end
end
