# frozen_string_literal: true

class AddDateOfArrivalToInventoryOrders < ActiveRecord::Migration[8.1]
  def change
    add_column :inventory_orders, :date_of_arrival, :date
  end
end
