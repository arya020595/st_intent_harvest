# frozen_string_literal: true

class AddCurrencyToInventories < ActiveRecord::Migration[7.2]
  def change
    add_column :inventories, :currency, :string, default: 'RM'
  end
end
