class CreateWorkOrderRates < ActiveRecord::Migration[7.2]
  def change
    create_table :work_order_rates do |t|
      t.string :work_order_name
      t.decimal :rate, precision: 10, scale: 2
      t.references :unit, foreign_key: true

      t.timestamps
    end
  end
end
