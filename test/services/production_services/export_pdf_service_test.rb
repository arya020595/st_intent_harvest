# frozen_string_literal: true

require 'test_helper'

module ProductionServices
  class ExportPdfServiceTest < ActiveSupport::TestCase
    setup do
      @production1 = productions(:one)
      @production2 = productions(:two)
      @production3 = productions(:three)
      @records = Production.includes(:block, :mill).all
      @params = {}
      @view_context = create_view_context
      @totals = {
        total_bunches: @records.sum(:total_bunches),
        total_weight_ton: @records.sum(:total_weight_ton)
      }
      @filter_data = { mill: nil, block: nil }

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
    # Success Cases
    # ============================================

    test 'call returns Success monad with export data' do
      stub_grover_pdf do
        service = ExportPdfService.new(
          records: @records,
          params: @params,
          view_context: @view_context,
          extra_locals: { totals: @totals, filter_data: @filter_data }
        )
        result = service.call

        assert result.success?
        assert result.value!.key?(:data)
        assert result.value!.key?(:filename)
        assert result.value!.key?(:content_type)
      end
    end

    test 'content type is application/pdf' do
      stub_grover_pdf do
        service = ExportPdfService.new(
          records: @records,
          params: @params,
          view_context: @view_context,
          extra_locals: { totals: @totals, filter_data: @filter_data }
        )
        result = service.call

        assert_equal 'application/pdf', result.value![:content_type]
      end
    end

    test 'generates valid PDF data' do
      stub_grover_pdf do
        service = ExportPdfService.new(
          records: @records,
          params: @params,
          view_context: @view_context,
          extra_locals: { totals: @totals, filter_data: @filter_data }
        )
        result = service.call

        pdf_data = result.value![:data]
        # PDF files start with %PDF
        assert_match(/^%PDF/, pdf_data)
      end
    end

    # ============================================
    # Template Locals Tests
    # ============================================

    test 'passes productions to template' do
      service = ExportPdfService.new(
        records: @records,
        params: @params,
        view_context: @view_context,
        extra_locals: { totals: @totals, filter_data: @filter_data }
      )

      locals = service.send(:template_locals)
      assert_equal @records, locals[:productions]
    end

    test 'passes totals to template' do
      service = ExportPdfService.new(
        records: @records,
        params: @params,
        view_context: @view_context,
        extra_locals: { totals: @totals, filter_data: @filter_data }
      )

      locals = service.send(:template_locals)
      assert_equal @totals, locals[:totals]
      assert locals[:totals].key?(:total_bunches)
      assert locals[:totals].key?(:total_weight_ton)
    end

    test 'passes filter_data to template' do
      mill = mills(:one)
      filter_data = { mill: mill, block: nil }

      service = ExportPdfService.new(
        records: @records,
        params: @params,
        view_context: @view_context,
        extra_locals: { totals: @totals, filter_data: filter_data }
      )

      locals = service.send(:template_locals)
      assert_equal mill, locals[:filter_data][:mill]
    end

    test 'handles missing extra_locals gracefully' do
      service = ExportPdfService.new(
        records: @records,
        params: @params,
        view_context: @view_context
      )

      locals = service.send(:template_locals)
      assert_equal({}, locals[:totals])
      assert_equal({}, locals[:filter_data])
    end

    # ============================================
    # Filename Generation Tests
    # ============================================

    test 'generates filename with date range when params provided' do
      stub_grover_pdf do
        start_date = 3.days.ago.to_date
        end_date = Date.today
        params = { q: { date_gteq: start_date.to_s, date_lteq: end_date.to_s } }

        service = ExportPdfService.new(
          records: @records,
          params: params,
          view_context: @view_context,
          extra_locals: { totals: @totals, filter_data: @filter_data }
        )
        result = service.call

        expected_filename = "productions-#{start_date.strftime('%d-%m-%Y')}_to_#{end_date.strftime('%d-%m-%Y')}.pdf"
        assert_equal expected_filename, result.value![:filename]
      end
    end

    test 'generates filename with current date when no date params' do
      stub_grover_pdf do
        service = ExportPdfService.new(
          records: @records,
          params: {},
          view_context: @view_context,
          extra_locals: { totals: @totals, filter_data: @filter_data }
        )
        result = service.call

        expected_filename = "productions-#{Date.current.strftime('%Y%m%d')}.pdf"
        assert_equal expected_filename, result.value![:filename]
      end
    end

    # ============================================
    # Edge Cases and Error Handling
    # ============================================

    test 'handles empty records collection' do
      stub_grover_pdf do
        empty_records = Production.none
        empty_totals = { total_bunches: 0, total_weight_ton: 0 }

        service = ExportPdfService.new(
          records: empty_records,
          params: @params,
          view_context: @view_context,
          extra_locals: { totals: empty_totals, filter_data: @filter_data }
        )
        result = service.call

        assert result.success?
        assert_match(/^%PDF/, result.value![:data])
      end
    end

    test 'returns Failure monad when records is nil' do
      service = ExportPdfService.new(
        records: nil,
        params: @params,
        view_context: @view_context,
        extra_locals: { totals: @totals, filter_data: @filter_data }
      )
      result = service.call

      assert result.failure?
      assert_match 'Records cannot be nil', result.failure
    end

    test 'handles error during PDF generation' do
      # Create a service with invalid view context
      invalid_service = ExportPdfService.new(
        records: @records,
        params: @params,
        view_context: nil,
        extra_locals: { totals: @totals, filter_data: @filter_data }
      )

      result = invalid_service.call

      assert result.failure?
    end

    # ============================================
    # PDF Options Tests
    # ============================================

    test 'uses A4 format for PDF' do
      service = ExportPdfService.new(
        records: @records,
        params: @params,
        view_context: @view_context,
        extra_locals: { totals: @totals, filter_data: @filter_data }
      )

      pdf_options = service.send(:pdf_options)
      assert_equal 'A4', pdf_options[:format]
    end

    test 'uses landscape orientation' do
      service = ExportPdfService.new(
        records: @records,
        params: @params,
        view_context: @view_context,
        extra_locals: { totals: @totals, filter_data: @filter_data }
      )

      assert service.send(:landscape?)
    end

    test 'includes margins in PDF options' do
      service = ExportPdfService.new(
        records: @records,
        params: @params,
        view_context: @view_context,
        extra_locals: { totals: @totals, filter_data: @filter_data }
      )

      pdf_options = service.send(:pdf_options)
      assert pdf_options[:margin].key?(:top)
      assert pdf_options[:margin].key?(:bottom)
      assert pdf_options[:margin].key?(:left)
      assert pdf_options[:margin].key?(:right)
    end

    # ============================================
    # Integration with Filters
    # ============================================

    test 'handles mill filter in extra_locals' do
      stub_grover_pdf do
        mill = mills(:one)
        filter_data = { mill: mill, block: nil }

        service = ExportPdfService.new(
          records: @records,
          params: { q: { mill_id_eq: mill.id } },
          view_context: @view_context,
          extra_locals: { totals: @totals, filter_data: filter_data }
        )
        result = service.call

        assert result.success?
      end
    end

    test 'handles block filter in extra_locals' do
      stub_grover_pdf do
        block = blocks(:one)
        filter_data = { mill: nil, block: block }

        service = ExportPdfService.new(
          records: @records,
          params: { q: { block_id_eq: block.id } },
          view_context: @view_context,
          extra_locals: { totals: @totals, filter_data: filter_data }
        )
        result = service.call

        assert result.success?
      end
    end

    test 'handles both mill and block filters' do
      stub_grover_pdf do
        mill = mills(:one)
        block = blocks(:one)
        filter_data = { mill: mill, block: block }

        service = ExportPdfService.new(
          records: @records,
          params: { q: { mill_id_eq: mill.id, block_id_eq: block.id } },
          view_context: @view_context,
          extra_locals: { totals: @totals, filter_data: filter_data }
        )
        result = service.call

        assert result.success?
      end
    end

    private

    def create_view_context
      # Create a mock view context with necessary methods
      view_context = Object.new

      def view_context.render_to_string(_options)
        # Return a minimal HTML that Grover can convert to PDF
        <<~HTML
          <!DOCTYPE html>
          <html>
            <head><title>Test PDF</title></head>
            <body>
              <h1>Production Records</h1>
              <table>
                <tr><th>Date</th><th>Bunches</th><th>Weight</th></tr>
                <tr><td>01-01-2026</td><td>100</td><td>2.5</td></tr>
              </table>
            </body>
          </html>
        HTML
      end

      view_context
    end
  end
end
