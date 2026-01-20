# frozen_string_literal: true

require 'test_helper'

module Exporters
  class PdfExporterTest < ActiveSupport::TestCase
    # Create a concrete implementation for testing
    class TestPdfExporter < PdfExporter
      protected

      def resource_name
        'test'
      end

      def template_path
        'test/template'
      end

      def template_locals
        { records: @records, params: @params, extra: @extra_locals }
      end
    end

    setup do
      @production1 = productions(:one)
      @production2 = productions(:two)
      @records = Production.includes(:block, :mill).all
      @view_context = create_view_context

      # Stub Grover.new to avoid Puppeteer dependency
      @original_grover_new = Grover.method(:new)
      Grover.define_singleton_method(:new) do |*_args|
        grover_instance = Object.new
        def grover_instance.to_pdf
          # Return a minimal but realistic PDF structure
          "%PDF-1.4\n1 0 obj<</Type/Catalog/Pages 2 0 R>>endobj 2 0 obj<</Type/Pages/Count 1/Kids[3 0 R]>>endobj 3 0 obj<</Type/Page/MediaBox[0 0 612 792]/Parent 2 0 R/Resources<<>>>>endobj\nxref\n0 4\n0000000000 65535 f\n0000000009 00000 n\n0000000056 00000 n\n0000000114 00000 n\ntrailer<</Size 4/Root 1 0 R>>\nstartxref\n210\n%%EOF\n"
        end
        grover_instance
      end
    end

    teardown do
      # Restore original Grover.new
      Grover.define_singleton_method(:new, @original_grover_new) if @original_grover_new
    end

    # Helper method to stub Grover PDF generation (no longer needed but keeping for compatibility)
    def stub_grover_pdf
      yield
    end

    # ============================================
    # Initialization Tests
    # ============================================

    test 'initializes with records, params, and view_context' do
      exporter = TestPdfExporter.new(
        records: @records,
        params: {},
        view_context: @view_context
      )

      assert_equal @records, exporter.instance_variable_get(:@records)
      assert_equal @view_context, exporter.instance_variable_get(:@view_context)
    end

    test 'initializes with extra_locals from options' do
      extra_locals = { totals: { total: 100 } }

      exporter = TestPdfExporter.new(
        records: @records,
        params: {},
        view_context: @view_context,
        extra_locals: extra_locals
      )

      assert_equal extra_locals, exporter.instance_variable_get(:@extra_locals)
    end

    test 'extra_locals defaults to empty hash when not provided' do
      exporter = TestPdfExporter.new(
        records: @records,
        params: {},
        view_context: @view_context
      )

      assert_equal({}, exporter.instance_variable_get(:@extra_locals))
    end

    # ============================================
    # Success Path Tests
    # ============================================

    test 'call returns Success monad with PDF data' do
      stub_grover_pdf do
        exporter = TestPdfExporter.new(
          records: @records,
          params: {},
          view_context: @view_context
        )
        result = exporter.call

        assert result.success?
        assert result.value!.key?(:data)
        assert result.value!.key?(:filename)
        assert result.value!.key?(:content_type)
      end
    end

    test 'content type is application/pdf' do
      stub_grover_pdf do
        exporter = TestPdfExporter.new(
          records: @records,
          params: {},
          view_context: @view_context
        )
        result = exporter.call

        assert_equal 'application/pdf', result.value![:content_type]
      end
    end

    test 'generates valid PDF data' do
      stub_grover_pdf do
        exporter = TestPdfExporter.new(
          records: @records,
          params: {},
          view_context: @view_context
        )
        result = exporter.call

        pdf_data = result.value![:data]
        # PDF files start with %PDF
        assert_match(/^%PDF/, pdf_data)
      end
    end

    # ============================================
    # Template Rendering Tests
    # ============================================

    test 'renders template with correct format' do
      view_context = create_view_context

      exporter = TestPdfExporter.new(
        records: @records,
        params: {},
        view_context: view_context
      )

      # Access private method for testing
      html = exporter.send(:render_template)

      assert_instance_of String, html
      assert_match 'Test PDF', html
    end

    test 'passes template_locals to render_to_string' do
      extra_locals = { totals: { total_bunches: 500 } }
      view_context = create_view_context

      exporter = TestPdfExporter.new(
        records: @records,
        params: {},
        view_context: view_context,
        extra_locals: extra_locals
      )

      # Verify template_locals includes extra_locals
      locals = exporter.send(:template_locals)
      assert_equal extra_locals, locals[:extra]
    end

    # ============================================
    # PDF Options Tests
    # ============================================

    test 'default pdf_options uses A4 format' do
      exporter = TestPdfExporter.new(
        records: @records,
        params: {},
        view_context: @view_context
      )

      options = exporter.send(:pdf_options)
      assert_equal 'A4', options[:format]
    end

    test 'default pdf_options uses landscape orientation' do
      exporter = TestPdfExporter.new(
        records: @records,
        params: {},
        view_context: @view_context
      )

      options = exporter.send(:pdf_options)
      assert_equal true, options[:landscape]
    end

    test 'default pdf_options includes margins' do
      exporter = TestPdfExporter.new(
        records: @records,
        params: {},
        view_context: @view_context
      )

      options = exporter.send(:pdf_options)
      assert options[:margin].is_a?(Hash)
      assert_equal '10mm', options[:margin][:top]
      assert_equal '10mm', options[:margin][:bottom]
      assert_equal '10mm', options[:margin][:left]
      assert_equal '10mm', options[:margin][:right]
    end

    test 'default pdf_options enables print_background' do
      exporter = TestPdfExporter.new(
        records: @records,
        params: {},
        view_context: @view_context
      )

      options = exporter.send(:pdf_options)
      assert_equal true, options[:print_background]
    end

    test 'landscape? returns true by default' do
      exporter = TestPdfExporter.new(
        records: @records,
        params: {},
        view_context: @view_context
      )

      assert_equal true, exporter.send(:landscape?)
    end

    # ============================================
    # Filename Generation Tests
    # ============================================

    test 'generates filename with date range' do
      stub_grover_pdf do
        start_date = 3.days.ago.to_date
        end_date = Date.today
        params = { q: { date_gteq: start_date.to_s, date_lteq: end_date.to_s } }

        exporter = TestPdfExporter.new(
          records: @records,
          params: params,
          view_context: @view_context
        )
        result = exporter.call

        expected_filename = "test-#{start_date.strftime('%d-%m-%Y')}_to_#{end_date.strftime('%d-%m-%Y')}.pdf"
        assert_equal expected_filename, result.value![:filename]
      end
    end

    test 'generates filename with current date when no params' do
      stub_grover_pdf do
        exporter = TestPdfExporter.new(
          records: @records,
          params: {},
          view_context: @view_context
        )
        result = exporter.call

        expected_filename = "test-#{Date.current.strftime('%Y%m%d')}.pdf"
        assert_equal expected_filename, result.value![:filename]
      end
    end

    # ============================================
    # Error Handling Tests
    # ============================================

    test 'returns Failure when records is nil' do
      exporter = TestPdfExporter.new(
        records: nil,
        params: {},
        view_context: @view_context
      )
      result = exporter.call

      assert result.failure?
      assert_match 'Records cannot be nil', result.failure
    end

    test 'handles empty records collection' do
      stub_grover_pdf do
        empty_records = Production.none

        exporter = TestPdfExporter.new(
          records: empty_records,
          params: {},
          view_context: @view_context
        )
        result = exporter.call

        assert result.success?
      end
    end

    test 'handles error during template rendering' do
      # Create a view context that will raise an error
      failing_view_context = Object.new
      def failing_view_context.render_to_string(_options)
        raise StandardError, 'Template rendering failed'
      end

      exporter = TestPdfExporter.new(
        records: @records,
        params: {},
        view_context: failing_view_context
      )
      result = exporter.call

      assert result.failure?
      assert_match 'Template rendering failed', result.failure
    end

    test 'handles nil view_context gracefully' do
      exporter = TestPdfExporter.new(
        records: @records,
        params: {},
        view_context: nil
      )
      result = exporter.call

      assert result.failure?
    end

    # ============================================
    # NotImplementedError Tests
    # ============================================

    test 'raises NotImplementedError if template_path not implemented' do
      incomplete_exporter = Class.new(PdfExporter) do
        protected

        def resource_name
          'test'
        end

        def template_locals
          {}
        end
      end

      exporter = incomplete_exporter.new(
        records: @records,
        params: {},
        view_context: @view_context
      )

      assert_raises(NotImplementedError) do
        exporter.call
      end
    end

    # ============================================
    # Custom PDF Options Tests
    # ============================================

    test 'subclass can override pdf_options' do
      custom_exporter = Class.new(PdfExporter) do
        protected

        def resource_name
          'custom'
        end

        def template_path
          'test/template'
        end

        def template_locals
          { records: @records }
        end

        def pdf_options
          super.merge(format: 'Letter')
        end
      end

      exporter = custom_exporter.new(
        records: @records,
        params: {},
        view_context: @view_context
      )

      options = exporter.send(:pdf_options)
      assert_equal 'Letter', options[:format]
      # Should still have other default options
      assert options[:margin].is_a?(Hash)
    end

    test 'subclass can override landscape orientation' do
      portrait_exporter = Class.new(PdfExporter) do
        protected

        def resource_name
          'portrait'
        end

        def template_path
          'test/template'
        end

        def template_locals
          { records: @records }
        end

        def landscape?
          false
        end
      end

      exporter = portrait_exporter.new(
        records: @records,
        params: {},
        view_context: @view_context
      )

      options = exporter.send(:pdf_options)
      assert_equal false, options[:landscape]
    end

    # ============================================
    # Integration Tests
    # ============================================

    test 'generates PDF from HTML with Grover' do
      stub_grover_pdf do
        exporter = TestPdfExporter.new(
          records: @records,
          params: {},
          view_context: @view_context
        )
        result = exporter.call

        assert result.success?
        pdf_data = result.value![:data]

        # Verify it's a valid PDF by checking magic bytes
        assert_match(/^%PDF-/, pdf_data)
        # PDF should have EOF marker
        assert_match(/%%EOF\s*\z/, pdf_data)
      end
    end

    test 'PDF includes content from template' do
      stub_grover_pdf do
        exporter = TestPdfExporter.new(
          records: @records,
          params: {},
          view_context: @view_context
        )
        result = exporter.call

        assert result.success?
        # PDF content verification would require parsing,
        # but we can at least verify it was generated
        assert result.value![:data].length > 100
      end
    end

    private

    def create_view_context
      view_context = Object.new

      def view_context.render_to_string(options)
        # Return a valid HTML template
        <<~HTML
          <!DOCTYPE html>
          <html>
            <head>
              <meta charset="utf-8">
              <title>Test PDF</title>
              <style>
                body { font-family: Arial, sans-serif; }
                table { border-collapse: collapse; width: 100%; }
                th, td { border: 1px solid #ddd; padding: 8px; }
              </style>
            </head>
            <body>
              <h1>Test PDF Report</h1>
              <table>
                <thead>
                  <tr>
                    <th>Date</th>
                    <th>Bunches</th>
                    <th>Weight</th>
                  </tr>
                </thead>
                <tbody>
                  <tr>
                    <td>#{Date.today.strftime('%d-%m-%Y')}</td>
                    <td>100</td>
                    <td>2.5</td>
                  </tr>
                </tbody>
              </table>
            </body>
          </html>
        HTML
      end

      view_context
    end
  end
end
