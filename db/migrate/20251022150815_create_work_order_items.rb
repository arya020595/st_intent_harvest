# frozen_string_literal: true

class CreateWorkOrderItems < ActiveRecord::Migration[7.2]
  def change
    create_table :work_order_items do |t|
      t.references :work_order, foreign_key: true, null: false
      t.references :inventory, foreign_key: true
      t.string :item_name
      t.integer :amount_used
      t.decimal :price, precision: 10, scale: 2
      t.string :unit_name
      t.string :category_name

      t.timestamps
    end
  end
end
