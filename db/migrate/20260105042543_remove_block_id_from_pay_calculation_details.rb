class RemoveBlockIdFromPayCalculationDetails < ActiveRecord::Migration[8.1]
  def change
    # Remove foreign key first
    remove_foreign_key :pay_calculation_details, :blocks, if_exists: true

    # Remove the column and index (safe because ignored_columns is set in model)
    safety_assured { remove_reference :pay_calculation_details, :block, index: true, foreign_key: false }
  end
end
