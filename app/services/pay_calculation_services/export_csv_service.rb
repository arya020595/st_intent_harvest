# frozen_string_literal: true

module PayCalculationServices
  # CSV Exporter for Pay Calculation Details (Workers List)
  # Exports worker pay details with deduction breakdowns
  class ExportCsvService < Exporters::CsvExporter
    HEADERS = [
      'Worker ID',
      'Worker Name',
      'Gross Salary',
      'Employee EPF',
      'Employee SOCSO',
      'Employee EIS',
      'Net Salary',
      'Employer EPF',
      'Employer SOCSO',
      'Employer EIS',
      'Total Deduction (Employee)',
      'Position'
    ].freeze

    def initialize(records:, params: {}, pay_calculation: nil, **)
      super(records: records, params: params, **)
      @pay_calculation = pay_calculation
    end

    protected

    def resource_name
      'pay_calculation_workers'
    end

    def headers
      HEADERS
    end

    def row_data(detail)
      breakdown = parse_deduction_breakdown(detail.deduction_breakdown)

      [
        detail.worker.id,
        detail.worker.name,
        format_decimal(detail.gross_salary),
        extract_employee_deduction(breakdown, 'EPF'),
        extract_employee_deduction(breakdown, 'SOCSO'),
        extract_employee_deduction(breakdown, 'EIS'),
        format_decimal(detail.net_salary),
        extract_employer_deduction(breakdown, 'EPF'),
        extract_employer_deduction(breakdown, 'SOCSO'),
        extract_employer_deduction(breakdown, 'EIS'),
        format_decimal(detail.employee_deductions),
        detail.worker.position || '-'
      ]
    end

    def generate_filename
      month_year = @pay_calculation&.month_year || 'unknown'
      formatted_month = begin
        Date.strptime(month_year, '%Y-%m').strftime('%B_%Y')
      rescue StandardError
        month_year
      end
      "pay_calculation_workers-#{formatted_month}.csv"
    end

    private

    # Extract employee deduction amount for given deduction type (EPF, SOCSO, EIS)
    # The deduction_breakdown keys can be like 'EPF_LOCAL', 'EPF_FOREIGN', 'SOCSO', 'EIS_LOCAL', etc.
    def extract_employee_deduction(breakdown, deduction_type)
      deduction = find_deduction_by_type(breakdown, deduction_type)
      return '-' unless deduction

      amount = deduction['employee_amount'].to_f
      amount.zero? ? '-' : format_decimal(amount)
    end

    # Extract employer deduction amount for given deduction type
    def extract_employer_deduction(breakdown, deduction_type)
      deduction = find_deduction_by_type(breakdown, deduction_type)
      return '-' unless deduction

      amount = deduction['employer_amount'].to_f
      amount.zero? ? '-' : format_decimal(amount)
    end

    # Find deduction by type (matches EPF, EPF_LOCAL, EPF_FOREIGN, etc.)
    def find_deduction_by_type(breakdown, deduction_type)
      key = breakdown.keys.find { |k| k.to_s.start_with?(deduction_type) }
      breakdown[key] if key
    end

    # Parse deduction_breakdown - handles both Hash (from DB) and String (from fixtures)
    def parse_deduction_breakdown(breakdown)
      return {} if breakdown.nil?
      return breakdown if breakdown.is_a?(Hash)

      JSON.parse(breakdown)
    rescue JSON::ParserError
      {}
    end
  end
end
