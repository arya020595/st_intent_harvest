class AddVehicleToWorkOrders < ActiveRecord::Migration[8.1]
  disable_ddl_transaction!

  def change
    # Add vehicle_id column if it does not exist, then add foreign key
    add_reference :work_orders, :vehicle, index: true, foreign_key: false unless column_exists?(:work_orders, :vehicle_id)
    add_foreign_key :work_orders, :vehicles, validate: false unless foreign_key_exists?(:work_orders, :vehicles)
  end
end
