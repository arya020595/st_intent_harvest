class AddMinAgeAndMaxAgeToDeductionWageRanges < ActiveRecord::Migration[8.1]
  def change
    add_column :deduction_wage_ranges, :min_age, :integer
    add_column :deduction_wage_ranges, :max_age, :integer
  end
end
