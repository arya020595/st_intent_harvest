# frozen_string_literal: true

class AddVehicleNumberToWorkOrders < ActiveRecord::Migration[8.1]
  def change
    add_column :work_orders, :vehicle_number, :string
    add_column :work_orders, :vehicle_model, :string
  end
end
