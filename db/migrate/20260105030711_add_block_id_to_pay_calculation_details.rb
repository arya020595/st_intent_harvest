# frozen_string_literal: true

class AddBlockIdToPayCalculationDetails < ActiveRecord::Migration[8.1]
  disable_ddl_transaction!

  def change
    # Allow null initially to support backfilling existing records
    # Block is optional because a worker might have multiple work orders across different blocks
    add_reference :pay_calculation_details, :block, null: true, index: { algorithm: :concurrently }
  end
end
