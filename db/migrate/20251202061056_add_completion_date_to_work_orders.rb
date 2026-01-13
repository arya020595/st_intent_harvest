# frozen_string_literal: true

class AddCompletionDateToWorkOrders < ActiveRecord::Migration[8.1]
  def change
    add_column :work_orders, :completion_date, :date
  end
end
