# frozen_string_literal: true

class AddCurrencyToWorkOrderRates < ActiveRecord::Migration[7.2]
  def change
    add_column :work_order_rates, :currency, :string, default: 'RM'
  end
end
