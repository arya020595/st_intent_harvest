# frozen_string_literal: true

# Migration to add rounding_precision to deduction_types
#
# SOLID Principle: Open/Closed
# - Allows each deduction type to define its own rounding behavior
# - No need to modify calculator code when adding new rounding rules
#
# Default: 2 (standard 2 decimal places for currency)
# EPF uses: 0 (whole numbers as per Malaysian EPF rounding rules)
class AddRoundingPrecisionToDeductionTypes < ActiveRecord::Migration[8.1]
  def change
    add_column :deduction_types, :rounding_precision, :integer, default: 2, null: false,
               comment: 'Decimal places for rounding calculated amounts (e.g., 0 for whole numbers, 2 for cents)'
  end
end
