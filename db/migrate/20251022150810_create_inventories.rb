# frozen_string_literal: true

class CreateInventories < ActiveRecord::Migration[7.2]
  def change
    create_table :inventories do |t|
      t.string :name, null: false
      t.integer :stock_quantity, default: 0
      t.references :category, foreign_key: true
      t.references :unit, foreign_key: true
      t.date :input_date
      t.decimal :price, precision: 10, scale: 2
      t.string :supplier

      t.timestamps
    end
  end
end
