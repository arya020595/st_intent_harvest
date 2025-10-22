class CreateBlocks < ActiveRecord::Migration[7.2]
  def change
    create_table :blocks do |t|
      t.string :block_number
      t.decimal :hectarage

      t.timestamps
    end
  end
end
