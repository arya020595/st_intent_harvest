class AddVehicleToWorkOrders < ActiveRecord::Migration[8.1]
  disable_ddl_transaction!

  def change
    # Add vehicle_id column if it does not exist, then add foreign key
    unless column_exists?(:work_orders, :vehicle_id)
      add_reference :work_orders, :vehicle, index: { algorithm: :concurrently }, foreign_key: false
    end
    add_foreign_key :work_orders, :vehicles, validate: false unless foreign_key_exists?(:work_orders, :vehicles)
  end
end
