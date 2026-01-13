# frozen_string_literal: true

class CreateInventoryOrders < ActiveRecord::Migration[8.1]
  def change
    create_table :inventory_orders do |t|
      t.references :inventory, null: false, foreign_key: true
      t.integer :quantity, null: false
      t.decimal :unit_price, precision: 10, scale: 2
      t.decimal :total_price, precision: 10, scale: 2, null: false
      t.string :supplier, null: false
      t.date :purchase_date, null: false

      t.timestamps
    end

    add_index :inventory_orders, :purchase_date
  end
end
