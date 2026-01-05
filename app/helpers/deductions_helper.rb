# frozen_string_literal: true

module DeductionsHelper
  # Sort deduction breakdown in standard order: EPF, SOCSO, EIS, then others alphabetically
  # This ensures consistent display across all views (pay calculations, payslips, PDFs)
  #
  # @param deduction_breakdown [Hash] Hash of deduction code => deduction data
  # @return [Array<Array>] Sorted array of [deduction_code, data] pairs
  #
  # Example:
  #   deduction_breakdown = {
  #     'EPF_LOCAL' => { 'name' => 'EPF', ... },
  #     'SOCSO' => { 'name' => 'SOCSO', ... },
  #     'EIS_LOCAL' => { 'name' => 'EIS', ... }
  #   }
  #   sorted_deductions(deduction_breakdown)
  #   # => [['EPF_LOCAL', {...}], ['SOCSO', {...}], ['EIS_LOCAL', {...}]]
  def sorted_deductions(deduction_breakdown)
    return [] unless deduction_breakdown.is_a?(Hash)

    deduction_breakdown.sort_by do |deduction_code, _data|
      priority = case deduction_code
                 when /^EPF/i then 0 # EPF_LOCAL, EPF_FOREIGN
                 when /^SOCSO$/i then 1 # SOCSO (exact match)
                 when /^EIS/i then 2 # EIS_LOCAL, EIS_FOREIGN
                 else 3 # Other deductions
                 end
      [priority, deduction_code]
    end
  end

  # Format deduction amount based on rounding precision from deduction data
  # Uses stored rounding_precision for SOLID compliance (Open/Closed principle)
  # - Precision 0: Whole numbers (e.g., "49")
  # - Precision 2: Currency format (e.g., "15.75")
  #
  # @param data [Hash] The deduction data containing 'rounding_precision'
  # @param amount [Numeric] The amount to format
  # @return [String] Formatted amount or '-' if zero
  #
  # Example:
  #   format_deduction_amount({ 'rounding_precision' => 0 }, 49.0)  # => "49"
  #   format_deduction_amount({ 'rounding_precision' => 2 }, 15.75)  # => "15.75"
  #   format_deduction_amount({}, 0)  # => "-"
  def format_deduction_amount(data, amount)
    return '-' if amount.to_f.zero?

    # Get precision from data, default to 2 for backward compatibility
    precision = data['rounding_precision'] || 2

    if precision.zero?
      number_with_delimiter(amount.to_i, delimiter: ',')
    else
      number_to_currency(amount, unit: '', separator: '.', delimiter: ',', precision: precision)
    end
  end
end
