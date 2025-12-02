class AddVehicleToWorkOrders < ActiveRecord::Migration[8.1]
  disable_ddl_transaction!

  def change
    # Column already exists from previous attempt, just add foreign key
    add_foreign_key :work_orders, :vehicles, validate: false unless foreign_key_exists?(:work_orders, :vehicles)
  end
end
