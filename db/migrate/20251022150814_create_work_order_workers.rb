class CreateWorkOrderWorkers < ActiveRecord::Migration[7.2]
  def change
    create_table :work_order_workers do |t|
      t.references :work_order, foreign_key: true, null: false
      t.references :worker, foreign_key: true, null: false
      t.string :worker_name
      t.integer :work_area_size
      t.decimal :rate, precision: 10, scale: 2
      t.decimal :amount, precision: 10, scale: 2
      t.text :remarks

      t.timestamps
    end
  end
end
