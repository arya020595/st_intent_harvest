# frozen_string_literal: true

class CreateProductions < ActiveRecord::Migration[8.1]
  def change
    create_table :productions do |t|
      t.date :date, null: false
      t.references :block, null: false, foreign_key: true
      t.string :ticket_estate_no
      t.string :ticket_mill_no
      t.references :mill, null: false, foreign_key: true
      t.integer :total_bunches, null: false, default: 0
      t.decimal :total_weight_ton, precision: 10, scale: 2, null: false, default: 0.0
      t.datetime :discarded_at, index: true

      t.timestamps
    end

    add_index :productions, :date
    add_index :productions, %i[date block_id]
  end
end
