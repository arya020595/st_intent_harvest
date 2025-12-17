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
end
