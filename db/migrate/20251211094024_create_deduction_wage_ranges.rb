# frozen_string_literal: true

class CreateDeductionWageRanges < ActiveRecord::Migration[8.1]
  def change
    # Allow NULL contributions for wage_range calculation types
    change_column_null :deduction_types, :employee_contribution, true
    change_column_null :deduction_types, :employer_contribution, true

    # Create wage ranges table with support for both fixed and percentage calculations
    create_table :deduction_wage_ranges do |t|
      t.references :deduction_type, null: false, foreign_key: { on_delete: :cascade }, index: true

      # Wage range boundaries
      t.decimal :min_wage, precision: 10, scale: 2, null: false
      t.decimal :max_wage, precision: 10, scale: 2 # NULL means "and above"

      # Fixed amount calculations (e.g., SOCSO local workers)
      t.decimal :employee_amount, precision: 10, scale: 2, default: 0.0, null: false
      t.decimal :employer_amount, precision: 10, scale: 2, default: 0.0, null: false

      # Percentage calculations (for future flexibility)
      t.decimal :employee_percentage, precision: 5, scale: 2, default: 0.0, null: false
      t.decimal :employer_percentage, precision: 5, scale: 2, default: 0.0, null: false

      # Calculation method for this range
      t.string :calculation_method, default: 'fixed', null: false

      t.timestamps
    end

    # Composite index for fast salary lookup queries
    add_index :deduction_wage_ranges,
              %i[deduction_type_id min_wage max_wage],
              name: 'idx_wage_ranges_salary_lookup'

    # Database-level constraints for data integrity
    reversible do |dir|
      dir.up do
        safety_assured do
          execute <<-SQL
            -- Ensure calculation_method is valid
            ALTER TABLE deduction_wage_ranges
            ADD CONSTRAINT calculation_method_check
            CHECK (calculation_method IN ('fixed', 'percentage'));

            -- Ensure max_wage >= min_wage
            ALTER TABLE deduction_wage_ranges
            ADD CONSTRAINT max_wage_check
            CHECK (max_wage IS NULL OR max_wage >= min_wage);

            -- Prevent overlapping wage ranges for same deduction type
            CREATE UNIQUE INDEX idx_wage_ranges_unique
            ON deduction_wage_ranges (deduction_type_id, min_wage, COALESCE(max_wage, 999999999));
          SQL
        end
      end

      dir.down do
        safety_assured do
          execute <<-SQL
            ALTER TABLE deduction_wage_ranges DROP CONSTRAINT IF EXISTS calculation_method_check;
            ALTER TABLE deduction_wage_ranges DROP CONSTRAINT IF EXISTS max_wage_check;
            DROP INDEX IF EXISTS idx_wage_ranges_unique;
          SQL
        end
      end
    end
  end
end
