class AddDateOfUsageToWorkOrders < ActiveRecord::Migration[8.1]
  def change
    add_column :work_orders, :date_of_usage, :date
  end
end
