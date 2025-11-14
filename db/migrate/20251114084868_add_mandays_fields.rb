# frozen_string_literal: true

class AddMandaysFields < ActiveRecord::Migration[7.0]
  def change
    # Add work_month to work_orders for tracking which month the work was done
    add_column :work_orders, :work_month, :date,
               comment: 'First day of the month for Mandays calculation'

    # Add work_days to work_order_workers to track days worked per worker per month
    add_column :work_order_workers, :work_days, :integer,
               default: 0, null: false, comment: 'How many days worker works in given month'
  end
end
