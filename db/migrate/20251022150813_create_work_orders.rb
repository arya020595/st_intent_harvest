class CreateWorkOrders < ActiveRecord::Migration[7.2]
  def change
    create_table :work_orders do |t|
      t.references :block, foreign_key: true
      t.string :block_number
      t.string :block_hectarage
      t.references :work_order_rate, foreign_key: true
      t.string :work_order_rate_name
      t.decimal :work_order_rate_price, precision: 10, scale: 2
      t.date :start_date
      t.string :work_order_status
      t.string :field_conductor
      t.string :approved_by
      t.datetime :approved_at

      t.timestamps
    end
    
    # Composite index to optimize queries filtering by block and work order rate
    add_index :work_orders, [:block_id, :work_order_rate_id], name: 'index_work_orders_on_block_and_rate'
  end
end
