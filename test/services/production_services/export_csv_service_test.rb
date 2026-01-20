# frozen_string_literal: true

require 'test_helper'

module ProductionServices
  class ExportCsvServiceTest < ActiveSupport::TestCase
    setup do
      @production1 = productions(:one)
      @production2 = productions(:two)
      @production3 = productions(:three)
      @records = Production.all
      @params = {}
    end

    # ============================================
    # Success Cases
    # ============================================

    test 'call returns Success monad with export data' do
      service = ExportCsvService.new(records: @records, params: @params)
      result = service.call

      assert result.success?
      assert result.value!.key?(:data)
      assert result.value!.key?(:filename)
      assert result.value!.key?(:content_type)
    end

    test 'generates CSV with correct headers' do
      service = ExportCsvService.new(records: @records, params: @params)
      result = service.call

      csv_data = result.value![:data]
      lines = csv_data.split("\n")

      assert_equal 'Date,Ticket Estate No.,Ticket Mill No.,Mill,Block No.,Total Bunches,Total Weight (Ton)', lines.first
    end

    test 'includes all production records in CSV' do
      service = ExportCsvService.new(records: @records, params: @params)
      result = service.call

      csv_data = result.value![:data]

      assert_match @production1.ticket_estate_no, csv_data
      assert_match @production2.ticket_estate_no, csv_data
      assert_match @production3.ticket_estate_no, csv_data
    end

    test 'formats dates correctly in DD-MM-YYYY format' do
      service = ExportCsvService.new(records: @records, params: @params)
      result = service.call

      csv_data = result.value![:data]
      expected_date = @production1.date.strftime('%d-%m-%Y')

      assert_match expected_date, csv_data
    end

    test 'formats decimal numbers with 2 decimal places' do
      service = ExportCsvService.new(records: @records, params: @params)
      result = service.call

      csv_data = result.value![:data]
      # Should have decimal precision
      assert_match(/\d+\.\d{2}/, csv_data)
    end

    test 'includes mill and block associations' do
      service = ExportCsvService.new(records: @records, params: @params)
      result = service.call

      csv_data = result.value![:data]

      assert_match @production1.mill.name, csv_data
      assert_match @production1.block.block_number, csv_data
    end

    test 'content type is text/csv' do
      service = ExportCsvService.new(records: @records, params: @params)
      result = service.call

      assert_equal 'text/csv', result.value![:content_type]
    end

    # ============================================
    # Filename Generation Tests
    # ============================================

    test 'generates filename with date range when params provided' do
      start_date = 3.days.ago.to_date
      end_date = Date.today
      params = { q: { date_gteq: start_date.to_s, date_lteq: end_date.to_s } }

      service = ExportCsvService.new(records: @records, params: params)
      result = service.call

      expected_filename = "productions-#{start_date.strftime('%d-%m-%Y')}_to_#{end_date.strftime('%d-%m-%Y')}.csv"
      assert_equal expected_filename, result.value![:filename]
    end

    test 'generates filename with current date when no date params' do
      service = ExportCsvService.new(records: @records, params: {})
      result = service.call

      expected_filename = "productions-#{Date.current.strftime('%Y%m%d')}.csv"
      assert_equal expected_filename, result.value![:filename]
    end

    test 'handles partial date range in filename' do
      params = { q: { date_gteq: 3.days.ago.to_date.to_s } }

      service = ExportCsvService.new(records: @records, params: params)
      result = service.call

      assert_match 'All', result.value![:filename]
    end

    # ============================================
    # Edge Cases and Error Handling
    # ============================================

    test 'handles empty records collection' do
      empty_records = Production.none

      service = ExportCsvService.new(records: empty_records, params: @params)
      result = service.call

      assert result.success?
      csv_data = result.value![:data]
      lines = csv_data.split("\n")

      # Should have header but no data rows
      assert_equal 1, lines.length
    end

    test 'handles nil values in ticket fields gracefully' do
      production = Production.create!(
        date: Date.today,
        ticket_estate_no: nil,
        ticket_mill_no: nil,
        total_bunches: 100,
        total_weight_ton: 2.5,
        block: blocks(:one),
        mill: mills(:one)
      )

      records = Production.where(id: production.id)
      service = ExportCsvService.new(records: records, params: @params)
      result = service.call

      assert result.success?
      # Should handle nil values without errors
      assert_match 'Mill A', result.value![:data]
    ensure
      production&.destroy
    end

    test 'returns Failure monad when records is nil' do
      service = ExportCsvService.new(records: nil, params: @params)
      result = service.call

      assert result.failure?
      assert_match 'Records cannot be nil', result.failure
    end

    test 'handles large dataset efficiently using find_each' do
      # Create multiple records to test batch processing
      15.times do |i|
        Production.create!(
          date: Date.today - i.days,
          ticket_estate_no: "TEST-#{i}",
          ticket_mill_no: "MILL-TEST-#{i}",
          total_bunches: 100 + i,
          total_weight_ton: 2.5 + i,
          block: blocks(:one),
          mill: mills(:one)
        )
      end

      all_records = Production.all
      service = ExportCsvService.new(records: all_records, params: @params)
      result = service.call

      assert result.success?
      csv_data = result.value![:data]
      lines = csv_data.split("\n")

      # Should have header + data rows
      assert lines.length > 15
    ensure
      # Cleanup
      Production.where('ticket_estate_no LIKE ?', 'TEST-%').destroy_all
    end

    # ============================================
    # UTF-8 Encoding Tests
    # ============================================

    test 'generates CSV with UTF-8 encoding' do
      service = ExportCsvService.new(records: @records, params: @params)
      result = service.call

      csv_data = result.value![:data]
      assert_equal Encoding::UTF_8, csv_data.encoding
    end

    test 'handles special characters in data' do
      production = Production.create!(
        date: Date.today,
        ticket_estate_no: 'TEST-Spécial-Çharš',
        ticket_mill_no: 'MILL-ñ-ü',
        total_bunches: 100,
        total_weight_ton: 2.5,
        block: blocks(:one),
        mill: mills(:one)
      )

      records = Production.where(id: production.id)
      service = ExportCsvService.new(records: records, params: @params)
      result = service.call

      assert result.success?
      csv_data = result.value![:data]
      assert_match 'Spécial', csv_data
    ensure
      production&.destroy
    end
  end
end
