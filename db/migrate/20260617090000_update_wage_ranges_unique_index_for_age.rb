class UpdateWageRangesUniqueIndexForAge < ActiveRecord::Migration[7.0]
  def up
    remove_index :deduction_wage_ranges, name: "idx_wage_ranges_unique"

    safety_assured do
      execute <<~SQL
        CREATE UNIQUE INDEX idx_wage_ranges_unique
          ON deduction_wage_ranges (
            deduction_type_id,
            min_wage,
            COALESCE(max_wage, 999999999),
            COALESCE(min_age, -1),
            COALESCE(max_age, -1)
          );
      SQL
    end
  end

  def down
    remove_index :deduction_wage_ranges, name: "idx_wage_ranges_unique"

    safety_assured do
      execute <<~SQL
        CREATE UNIQUE INDEX idx_wage_ranges_unique
          ON deduction_wage_ranges (
            deduction_type_id,
            min_wage,
            COALESCE(max_wage, 999999999)
          );
      SQL
    end
  end
end
