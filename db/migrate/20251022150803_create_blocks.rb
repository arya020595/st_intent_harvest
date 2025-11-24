# frozen_string_literal: true

class CreateBlocks < ActiveRecord::Migration[7.2]
  def change
    create_table :blocks do |t|
      t.string :block_number
      t.decimal :hectarage, precision: 10, scale: 2

      t.timestamps
    end
  end
end
