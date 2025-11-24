# frozen_string_literal: true

class AddCurrencyToPayCalculationDetails < ActiveRecord::Migration[7.2]
  def change
    add_column :pay_calculation_details, :currency, :string, default: 'RM'
  end
end
