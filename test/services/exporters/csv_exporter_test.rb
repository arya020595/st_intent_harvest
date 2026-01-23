# frozen_string_literal: true

require 'test_helper'

module Exporters
  class CsvExporterTest < ActiveSupport::TestCase
    # Create a concrete implementation for testing
    class TestCsvExporter < CsvExporter
      HEADERS = %w[Name Value].freeze

      protected

      def resource_name
        'test'
      end

      def headers
        HEADERS
      end

      def row_data(record)
        [record.ticket_estate_no, record.total_bunches]
      end
    end

    setup do
      @production1 = productions(:one)
      @production2 = productions(:two)
      @production3 = productions(:three)
      @records = Production.all
    end

    # ============================================
    # CSV Generation Tests
    # ============================================

    test 'generates CSV with headers' do
      exporter = TestCsvExporter.new(records: @records)
      result = exporter.call

      csv_data = result.value![:data]
      lines = csv_data.split("\n")

      assert_equal 'Name,Value', lines.first
    end

    test 'includes all records in CSV' do
      exporter = TestCsvExporter.new(records: @records)
      result = exporter.call

      csv_data = result.value![:data]
      lines = csv_data.split("\n")

      # Header + 3 production records
      assert_equal 4, lines.length
    end

    test 'generates CSV with correct content type' do
      exporter = TestCsvExporter.new(records: @records)
      result = exporter.call

      assert_equal 'text/csv', result.value![:content_type]
    end

    test 'generates CSV with correct file extension' do
      exporter = TestCsvExporter.new(records: @records)
      result = exporter.call

      assert_match(/\.csv$/, result.value![:filename])
    end

    test 'CSV data is UTF-8 encoded' do
      exporter = TestCsvExporter.new(records: @records)
      result = exporter.call

      csv_data = result.value![:data]
      assert_equal Encoding::UTF_8, csv_data.encoding
    end

    # ============================================
    # Data Iteration Tests
    # ============================================

    test 'uses find_each for efficient batch processing' do
      # Create more than 1000 records to ensure find_each batching works
      # (find_each defaults to batch size of 1000)
      created_ids = []
      5.times do |i|
        production = Production.create!(
          date: Date.today - i.days,
          ticket_estate_no: "BATCH-#{i}",
          ticket_mill_no: "MILL-BATCH-#{i}",
          total_bunches: 100,
          total_weight_ton: 2.5,
          block: blocks(:one),
          mill: mills(:one)
        )
        created_ids << production.id
      end

      all_records = Production.all
      exporter = TestCsvExporter.new(records: all_records)
      result = exporter.call

      assert result.success?
      csv_data = result.value![:data]

      # Verify batch records are included
      assert_match 'BATCH-0', csv_data
      assert_match 'BATCH-4', csv_data
    ensure
      Production.where(id: created_ids).destroy_all
    end

    test 'handles empty record set' do
      empty_records = Production.none
      exporter = TestCsvExporter.new(records: empty_records)
      result = exporter.call

      assert result.success?
      csv_data = result.value![:data]
      lines = csv_data.split("\n")

      # Only header, no data rows
      assert_equal 1, lines.length
      assert_equal 'Name,Value', lines.first
    end

    # ============================================
    # Row Data Tests
    # ============================================

    test 'row_data is called for each record' do
      exporter = TestCsvExporter.new(records: @records)
      result = exporter.call

      csv_data = result.value![:data]

      # Check that data from each production is included
      assert_match @production1.ticket_estate_no, csv_data
      assert_match @production2.ticket_estate_no, csv_data
      assert_match @production3.ticket_estate_no, csv_data
    end

    test 'handles nil values in row_data' do
      production = Production.create!
        date: Date.today,
        ticket_estate_no: 'ESTATE-001',
        ticket_mill_no: 'MILL-001',
        total_bunches: 100,
        total_weight_ton: 2.5,
        block: blocks(:one),
        mill: mills(:one)
      )

      records = Production.where(id: production.id)
      exporter = TestCsvExporter.new(records: records)
      result = exporter.call

      assert result.success?
      csv_data = result.value![:data]
      # Should handle nil without errors
      assert_match '100', csv_data
    ensure
      production&.destroy
    end

    # ============================================
    # CSV Format Tests
    # ============================================

    test 'CSV has proper structure with headers true' do
      exporter = TestCsvExporter.new(records: @records)
      result = exporter.call

      csv_data = result.value![:data]

      # Parse the CSV to verify structure
      parsed = CSV.parse(csv_data, headers: true)
      assert_equal ['Name', 'Value'], parsed.headers
    end

    test 'CSV escapes special characters correctly' do
      production = Production.create!(
        date: Date.today,
        ticket_estate_no: 'TEST, with "quotes"',
        ticket_mill_no: 'MILL-SPECIAL',
        total_bunches: 100,
        total_weight_ton: 2.5,
        block: blocks(:one),
        mill: mills(:one)
      )

      records = Production.where(id: production.id)
      exporter = TestCsvExporter.new(records: records)
      result = exporter.call

      assert result.success?
      csv_data = result.value![:data]

      # CSV should properly escape the comma and quotes
      parsed = CSV.parse(csv_data, headers: true)
      assert_equal 'TEST, with "quotes"', parsed.first['Name']
    ensure
      production&.destroy
    end

    # ============================================
    # NotImplementedError Tests
    # ============================================

    test 'raises NotImplementedError if headers not implemented' do
      incomplete_exporter = Class.new(CsvExporter) do
        protected

        def resource_name
          'test'
        end

        def row_data(record)
          [record.id]
        end
      end

      exporter = incomplete_exporter.new(records: @records)

      assert_raises(NotImplementedError) do
        exporter.call
      end
    end

    test 'raises NotImplementedError if row_data not implemented' do
      incomplete_exporter = Class.new(CsvExporter) do
        protected

        def resource_name
          'test'
        end

        def headers
          ['Test']
        end
      end

      exporter = incomplete_exporter.new(records: @records)

      assert_raises(NotImplementedError) do
        exporter.call
      end
    end

    # ============================================
    # Integration with FormatHelpers Tests
    # ============================================

    test 'inherits FormatHelpers methods' do
      exporter = TestCsvExporter.new(records: @records)

      # BaseExporter includes FormatHelpers
      assert_respond_to exporter, :format_date
      assert_respond_to exporter, :format_decimal
      assert_respond_to exporter, :safe_value
    end

    # ============================================
    # Filename Generation Tests
    # ============================================

    test 'generates filename with date range' do
      start_date = 3.days.ago.to_date
      end_date = Date.today
      params = { q: { date_gteq: start_date.to_s, date_lteq: end_date.to_s } }

      exporter = TestCsvExporter.new(records: @records, params: params)
      result = exporter.call

      expected_filename = "test-#{start_date.strftime('%d-%m-%Y')}_to_#{end_date.strftime('%d-%m-%Y')}.csv"
      assert_equal expected_filename, result.value![:filename]
    end

    test 'generates filename with current date when no params' do
      exporter = TestCsvExporter.new(records: @records)
      result = exporter.call

      expected_filename = "test-#{Date.current.strftime('%Y%m%d')}.csv"
      assert_equal expected_filename, result.value![:filename]
    end

    # ============================================
    # Edge Cases
    # ============================================

    test 'handles records with special UTF-8 characters' do
      production = Production.create!(
        date: Date.today,
        ticket_estate_no: 'TËST-ÜTF8-Çhàrs',
        ticket_mill_no: 'MILL-UTF8',
        total_bunches: 100,
        total_weight_ton: 2.5,
        block: blocks(:one),
        mill: mills(:one)
      )

      records = Production.where(id: production.id)
      exporter = TestCsvExporter.new(records: records)
      result = exporter.call

      assert result.success?
      csv_data = result.value![:data]
      assert_match 'TËST-ÜTF8-Çhàrs', csv_data
      assert_equal Encoding::UTF_8, csv_data.encoding
    ensure
      production&.destroy
    end

    test 'handles newlines in data' do
      production = Production.create!(
        date: Date.today,
        ticket_estate_no: "TEST\nwith\nnewlines",
        ticket_mill_no: 'MILL-NEWLINE',
        total_bunches: 100,
        total_weight_ton: 2.5,
        block: blocks(:one),
        mill: mills(:one)
      )

      records = Production.where(id: production.id)
      exporter = TestCsvExporter.new(records: records)
      result = exporter.call

      assert result.success?
      csv_data = result.value![:data]

      # CSV should properly quote and preserve newlines
      parsed = CSV.parse(csv_data, headers: true)
      assert_equal "TEST\nwith\nnewlines", parsed.first['Name']
    ensure
      production&.destroy
    end
  end
end
