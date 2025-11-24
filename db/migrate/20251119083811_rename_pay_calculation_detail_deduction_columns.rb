# frozen_string_literal: true

class RenamePayCalculationDetailDeductionColumns < ActiveRecord::Migration[8.1]
  def change
    # Rename columns to use proper terminology:
    # worker_deductions -> employee_deductions (what the employee/worker pays)
    # employee_deductions -> employer_deductions (what the employer/company pays)
    #
    # Use temporary column name to avoid conflict since employee_deductions already exists

    safety_assured do
      # Step 1: Rename employee_deductions to employer_deductions
      rename_column :pay_calculation_details, :employee_deductions, :employer_deductions

      # Step 2: Rename worker_deductions to employee_deductions
      rename_column :pay_calculation_details, :worker_deductions, :employee_deductions
    end

    # Update column comments for clarity
    change_column_comment :pay_calculation_details, :employee_deductions,
                          from: 'Total worker deductions (deducted from salary)',
                          to: "Employee's total deductions (deducted from salary)"

    change_column_comment :pay_calculation_details, :employer_deductions,
                          from: 'Total employer deductions (company cost)',
                          to: "Employer's total contributions (company cost)"
  end
end
