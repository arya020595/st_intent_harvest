# frozen_string_literal: true

class AddCalculationTypeToDeductionTypes < ActiveRecord::Migration[8.1]
  disable_ddl_transaction!

  def change
    add_column :deduction_types, :calculation_type, :string, default: 'percentage', null: false,
                                                             comment: 'Type of calculation: percentage (multiply by gross_salary) or fixed (use amount as-is)'
    add_column :deduction_types, :applies_to_nationality, :string,
               comment: 'Nationality filter: all, malaysian, foreign'

    # Set default for existing records
    reversible do |dir|
      dir.up do
        safety_assured do
          execute "UPDATE deduction_types SET calculation_type = 'percentage', applies_to_nationality = 'all' WHERE calculation_type IS NULL"
        end
      end
    end

    # Add indexes for common queries
    unless index_exists?(:deduction_types, :calculation_type)
      add_index :deduction_types, :calculation_type, algorithm: :concurrently
    end
    return if index_exists?(:deduction_types, :applies_to_nationality)

    add_index :deduction_types, :applies_to_nationality, algorithm: :concurrently
  end
end
