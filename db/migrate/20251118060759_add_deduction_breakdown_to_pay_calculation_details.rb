# frozen_string_literal: true

class AddDeductionBreakdownToPayCalculationDetails < ActiveRecord::Migration[8.1]
  def change
    add_column :pay_calculation_details, :deduction_breakdown, :jsonb,
               comment: 'JSON breakdown of deductions: {EPF: {worker: 0, employee: 0}, SOCSO: {...}}'
    add_column :pay_calculation_details, :worker_deductions, :decimal, precision: 10, scale: 2, default: 0,
                                                                       null: false, comment: 'Total worker deductions (deducted from salary)'
    add_column :pay_calculation_details, :employee_deductions, :decimal, precision: 10, scale: 2, default: 0,
                                                                         null: false, comment: 'Total employer deductions (company cost)'
  end
end
