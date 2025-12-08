class RemoveUnusedColumnsFromInventories < ActiveRecord::Migration[8.1]
  def change
    safety_assured do
      remove_column :inventories, :currency, :string, default: 'RM'
      remove_column :inventories, :input_date, :date
      remove_column :inventories, :price, :decimal, precision: 10, scale: 2
      remove_column :inventories, :stock_quantity, :integer, default: 0
      remove_column :inventories, :supplier, :string
    end
  end
end
