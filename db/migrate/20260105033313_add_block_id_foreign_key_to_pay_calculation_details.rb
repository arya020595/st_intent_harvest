class AddBlockIdForeignKeyToPayCalculationDetails < ActiveRecord::Migration[8.1]
  disable_ddl_transaction!

  def change
    add_foreign_key :pay_calculation_details, :blocks, column: :block_id, validate: false
  end
end
