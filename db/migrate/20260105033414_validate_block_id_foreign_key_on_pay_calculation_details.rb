class ValidateBlockIdForeignKeyOnPayCalculationDetails < ActiveRecord::Migration[8.1]
  def change
    validate_foreign_key :pay_calculation_details, :blocks
  end
end
