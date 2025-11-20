# frozen_string_literal: true

class RenameDeductionTypeAmountColumns < ActiveRecord::Migration[8.1]
  def change
    # Rename columns to use proper terminology:
    # worker_amount -> employee_contribution (what the employee/worker pays)
    # employee_amount -> employer_contribution (what the employer/company pays)

    safety_assured do
      rename_column :deduction_types, :worker_amount, :employee_contribution
      rename_column :deduction_types, :employee_amount, :employer_contribution
    end

    # Update column comments for clarity
    change_column_comment :deduction_types, :employee_contribution,
                          from: 'Fixed worker contribution amount in RM',
                          to: "Employee's contribution rate (percentage) or fixed amount (RM)"

    change_column_comment :deduction_types, :employer_contribution,
                          from: 'Fixed employer contribution amount in RM',
                          to: "Employer's contribution rate (percentage) or fixed amount (RM)"
  end
end
