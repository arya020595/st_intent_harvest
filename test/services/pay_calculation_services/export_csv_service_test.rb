# frozen_string_literal: true

require 'test_helper'

module PayCalculationServices
  class ExportCsvServiceTest < ActiveSupport::TestCase
    setup do
      @pay_calculation = pay_calculations(:january_2025)
      @detail1 = pay_calculation_details(:john_january)
      @detail2 = pay_calculation_details(:jane_january)
      @records = PayCalculationDetail.where(pay_calculation: @pay_calculation)
      @params = {}
    end

    # ============================================
    # Success Cases
    # ============================================

    test 'call returns Success monad with export data' do
      service = ExportCsvService.new(records: @records, params: @params, pay_calculation: @pay_calculation)
      result = service.call

      assert result.success?
      assert result.value!.key?(:data)
      assert result.value!.key?(:filename)
      assert result.value!.key?(:content_type)
    end

    test 'generates CSV with correct headers' do
      service = ExportCsvService.new(records: @records, params: @params, pay_calculation: @pay_calculation)
      result = service.call

      csv_data = result.value![:data]
      lines = csv_data.split("\n")
      expected_headers = 'Worker ID,Worker Name,Gross Salary,Employee EPF,Employee SOCSO,Employee EIS,' \
                         'Net Salary,Employer EPF,Employer SOCSO,Employer EIS,Total Deduction (Employee),Position'

      assert_equal expected_headers, lines.first
    end

    test 'includes all pay calculation details in CSV' do
      service = ExportCsvService.new(records: @records, params: @params, pay_calculation: @pay_calculation)
      result = service.call

      csv_data = result.value![:data]

      assert_match @detail1.worker.name, csv_data
      assert_match @detail2.worker.name, csv_data
    end

    test 'formats decimal numbers with 2 decimal places' do
      service = ExportCsvService.new(records: @records, params: @params, pay_calculation: @pay_calculation)
      result = service.call

      csv_data = result.value![:data]
      # Should have decimal precision for salary values
      assert_match(/\d+\.\d{2}/, csv_data)
    end

    test 'includes worker association data' do
      service = ExportCsvService.new(records: @records, params: @params, pay_calculation: @pay_calculation)
      result = service.call

      csv_data = result.value![:data]

      assert_match @detail1.worker.id.to_s, csv_data
      assert_match @detail1.worker.name, csv_data
    end

    test 'content type is text/csv' do
      service = ExportCsvService.new(records: @records, params: @params, pay_calculation: @pay_calculation)
      result = service.call

      assert_equal 'text/csv', result.value![:content_type]
    end

    # ============================================
    # Filename Generation Tests
    # ============================================

    test 'generates filename with formatted month year' do
      service = ExportCsvService.new(records: @records, params: @params, pay_calculation: @pay_calculation)
      result = service.call

      # January 2025 should format to January_2025
      expected_filename = 'pay_calculation_workers-January_2025.csv'
      assert_equal expected_filename, result.value![:filename]
    end

    test 'generates filename with unknown when pay_calculation is nil' do
      service = ExportCsvService.new(records: @records, params: @params)
      result = service.call

      expected_filename = 'pay_calculation_workers-unknown.csv'
      assert_equal expected_filename, result.value![:filename]
    end

    test 'handles different month formats in filename' do
      @pay_calculation.update!(month_year: '2025-12')
      service = ExportCsvService.new(records: @records, params: @params, pay_calculation: @pay_calculation)
      result = service.call

      expected_filename = 'pay_calculation_workers-December_2025.csv'
      assert_equal expected_filename, result.value![:filename]
    end

    # ============================================
    # Deduction Breakdown Extraction Tests
    # ============================================

    test 'extracts SOCSO employee deduction from breakdown' do
      service = ExportCsvService.new(records: @records, params: @params, pay_calculation: @pay_calculation)
      result = service.call

      csv_data = result.value![:data]
      # The fixture has SOCSO with employee_amount: 21.25
      assert_match '21.25', csv_data
    end

    test 'extracts SOCSO employer deduction from breakdown' do
      service = ExportCsvService.new(records: @records, params: @params, pay_calculation: @pay_calculation)
      result = service.call

      csv_data = result.value![:data]
      # The fixture has SOCSO with employer_amount: 74.35
      assert_match '74.35', csv_data
    end

    test 'returns dash for missing EPF deduction' do
      service = ExportCsvService.new(records: @records, params: @params, pay_calculation: @pay_calculation)
      result = service.call

      csv_data = result.value![:data]
      lines = csv_data.split("\n")
      data_line = lines[1] # First data row
      columns = data_line.split(',')

      # EPF columns (indices 3 and 7) should be '-' when not present
      assert_equal '-', columns[3] # Employee EPF
      assert_equal '-', columns[7] # Employer EPF
    end

    test 'returns dash for missing EIS deduction' do
      service = ExportCsvService.new(records: @records, params: @params, pay_calculation: @pay_calculation)
      result = service.call

      csv_data = result.value![:data]
      lines = csv_data.split("\n")
      data_line = lines[1] # First data row
      columns = data_line.split(',')

      # EIS columns (indices 5 and 9) should be '-' when not present
      assert_equal '-', columns[5] # Employee EIS
      assert_equal '-', columns[9] # Employer EIS
    end

    test 'handles EPF_LOCAL and EPF_FOREIGN keys correctly' do
      # Update fixture with EPF_LOCAL deduction
      breakdown = {
        'EPF_LOCAL' => { 'name' => 'EPF', 'employee_amount' => 550.0, 'employer_amount' => 650.0 },
        'SOCSO' => { 'name' => 'SOCSO', 'employee_amount' => 21.25, 'employer_amount' => 74.35 }
      }
      @detail1.update!(deduction_breakdown: breakdown)

      service = ExportCsvService.new(records: @records.reload, params: @params, pay_calculation: @pay_calculation)
      result = service.call

      csv_data = result.value![:data]
      assert_match '550.00', csv_data # Employee EPF
      assert_match '650.00', csv_data # Employer EPF
    end

    test 'handles EIS_LOCAL key correctly' do
      # Update fixture with EIS_LOCAL deduction
      breakdown = {
        'SOCSO' => { 'name' => 'SOCSO', 'employee_amount' => 21.25, 'employer_amount' => 74.35 },
        'EIS_LOCAL' => { 'name' => 'EIS', 'employee_amount' => 9.90, 'employer_amount' => 9.90 }
      }
      @detail1.update!(deduction_breakdown: breakdown)

      service = ExportCsvService.new(records: @records.reload, params: @params, pay_calculation: @pay_calculation)
      result = service.call

      csv_data = result.value![:data]
      assert_match '9.90', csv_data # EIS amounts
    end

    test 'handles nil deduction_breakdown gracefully' do
      @detail1.update_columns(deduction_breakdown: nil)

      service = ExportCsvService.new(records: @records.reload, params: @params, pay_calculation: @pay_calculation)
      result = service.call

      assert result.success?
      csv_data = result.value![:data]
      # Should have dashes for all deduction columns
      assert_match '-', csv_data
    end

    test 'handles empty deduction_breakdown hash' do
      @detail1.update_columns(deduction_breakdown: {})

      service = ExportCsvService.new(records: @records.reload, params: @params, pay_calculation: @pay_calculation)
      result = service.call

      assert result.success?
    end

    test 'returns dash when deduction amount is zero' do
      breakdown = {
        'EPF_LOCAL' => { 'name' => 'EPF', 'employee_amount' => 0, 'employer_amount' => 0 }
      }
      @detail1.update!(deduction_breakdown: breakdown)

      service = ExportCsvService.new(records: @records.reload, params: @params, pay_calculation: @pay_calculation)
      result = service.call

      csv_data = result.value![:data]
      lines = csv_data.split("\n")
      # Find the line with John Worker
      john_line = lines.find { |l| l.include?('John Worker') }
      columns = john_line.split(',')

      # EPF should be '-' for zero amount
      assert_equal '-', columns[3] # Employee EPF
      assert_equal '-', columns[7] # Employer EPF
    end

    # ============================================
    # Edge Cases and Error Handling
    # ============================================

    test 'handles empty records collection' do
      empty_records = PayCalculationDetail.none

      service = ExportCsvService.new(records: empty_records, params: @params, pay_calculation: @pay_calculation)
      result = service.call

      assert result.success?
      csv_data = result.value![:data]
      lines = csv_data.split("\n")

      # Should have header but no data rows
      assert_equal 1, lines.length
    end

    test 'handles nil position gracefully with dash' do
      # Use update_columns to bypass validations for test fixture
      @detail1.worker.update_columns(position: nil)

      service = ExportCsvService.new(records: @records.reload, params: @params, pay_calculation: @pay_calculation)
      result = service.call

      assert result.success?
      csv_data = result.value![:data]
      # Position column should have dash for nil
      assert_match ',-', csv_data
    end

    test 'includes position in export when present' do
      service = ExportCsvService.new(records: @records, params: @params, pay_calculation: @pay_calculation)
      result = service.call

      csv_data = result.value![:data]
      # Worker one has position: Harvester from fixture
      assert_match 'Harvester', csv_data
    end

    test 'returns Failure monad when records is nil' do
      service = ExportCsvService.new(records: nil, params: @params, pay_calculation: @pay_calculation)
      result = service.call

      assert result.failure?
      assert_match 'Records cannot be nil', result.failure
    end

    test 'handles large dataset' do
      # Create multiple records
      10.times do |i|
        worker = Worker.create!(
          name: "Test Worker #{i}",
          worker_type: Worker::WORKER_TYPES.first,
          nationality: 'local'
        )
        PayCalculationDetail.create!(
          pay_calculation: @pay_calculation,
          worker: worker,
          gross_salary: 1000 + (i * 100),
          employee_deductions: 50,
          employer_deductions: 75,
          net_salary: 950 + (i * 100),
          deduction_breakdown: { 'SOCSO' => { 'name' => 'SOCSO', 'employee_amount' => 50, 'employer_amount' => 75 } }
        )
      end

      all_records = PayCalculationDetail.where(pay_calculation: @pay_calculation)
      service = ExportCsvService.new(records: all_records, params: @params, pay_calculation: @pay_calculation)
      result = service.call

      assert result.success?
      csv_data = result.value![:data]
      lines = csv_data.split("\n")

      # Should have header + original + new data rows
      assert lines.length >= 12
    end

    # ============================================
    # UTF-8 Encoding Tests
    # ============================================

    test 'generates CSV with UTF-8 encoding' do
      service = ExportCsvService.new(records: @records, params: @params, pay_calculation: @pay_calculation)
      result = service.call

      csv_data = result.value![:data]
      assert_equal Encoding::UTF_8, csv_data.encoding
    end

    test 'handles special characters in worker names' do
      @detail1.worker.update_columns(name: 'José García-Müller')

      service = ExportCsvService.new(records: @records.reload, params: @params, pay_calculation: @pay_calculation)
      result = service.call

      assert result.success?
      csv_data = result.value![:data]
      assert_match 'José García-Müller', csv_data
    end

    # ============================================
    # Row Data Tests
    # ============================================

    test 'includes correct worker ID in export' do
      service = ExportCsvService.new(records: @records, params: @params, pay_calculation: @pay_calculation)
      result = service.call

      csv_data = result.value![:data]
      assert_match @detail1.worker.id.to_s, csv_data
    end

    test 'includes gross salary in export' do
      service = ExportCsvService.new(records: @records, params: @params, pay_calculation: @pay_calculation)
      result = service.call

      csv_data = result.value![:data]
      # Fixture has gross_salary: 4500.00
      assert_match '4500.00', csv_data
    end

    test 'includes net salary in export' do
      service = ExportCsvService.new(records: @records, params: @params, pay_calculation: @pay_calculation)
      result = service.call

      csv_data = result.value![:data]
      # Fixture has net_salary: 4478.75
      assert_match '4478.75', csv_data
    end

    test 'includes total employee deductions in export' do
      service = ExportCsvService.new(records: @records, params: @params, pay_calculation: @pay_calculation)
      result = service.call

      csv_data = result.value![:data]
      # Fixture has employee_deductions: 21.25
      assert_match '21.25', csv_data
    end
  end
end
