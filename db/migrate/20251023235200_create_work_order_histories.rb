class CreateWorkOrderHistories < ActiveRecord::Migration[7.2]
  def change
    create_table :work_order_histories do |t|
      t.references :work_order, foreign_key: true, null: false
      t.string :from_state
      t.string :to_state
      t.string :action
      t.references :user, foreign_key: true, null: true
      t.text :remarks
      t.jsonb :transition_details, default: {}

      t.timestamps
    end
    
    add_index :work_order_histories, [:work_order_id, :created_at], name: 'index_work_order_histories_on_order_and_created'
  end
end
