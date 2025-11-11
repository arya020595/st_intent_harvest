class CreateVehicles < ActiveRecord::Migration[7.2]
  def change
    create_table :vehicles do |t|
      t.string :vehicle_number
      t.string :vehicle_model

      t.timestamps
    end
  end
end
