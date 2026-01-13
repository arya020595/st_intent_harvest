# frozen_string_literal: true

class AddRoundingMethodToDeductionTypes < ActiveRecord::Migration[8.1]
  def up
    add_column :deduction_types, :rounding_method, :string, default: 'round', null: false

    # EPF uses ceiling rounding (50.20 → 51)
    safety_assured do
      execute <<-SQL.squish
        UPDATE deduction_types
        SET rounding_method = 'ceil'
        WHERE code LIKE 'EPF%'
      SQL
    end
  end

  def down
    remove_column :deduction_types, :rounding_method
  end
end
