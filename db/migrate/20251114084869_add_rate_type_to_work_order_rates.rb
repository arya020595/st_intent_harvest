# frozen_string_literal: true

class AddRateTypeToWorkOrderRates < ActiveRecord::Migration[8.1]
  def change
    add_column :work_order_rates, :work_order_rate_type, :string,
               default: 'normal',
               comment: 'Type of work order rate: normal (all fields), resources (resource fields only), work_days (worker details only)'
  end
end
