class CreateWorkOrders < ActiveRecord::Migration[7.2]
  def change
    create_table :work_orders do |t|
      t.references :block, foreign_key: true
      t.date :start_date
      t.boolean :is_active, default: true
      t.date :hired_date
      t.string :work_order_status
      t.string :identity_number
      t.string :approved_by
      t.datetime :approved_at

      t.timestamps
    end
    
    add_index :work_orders, :identity_number
  end
end
