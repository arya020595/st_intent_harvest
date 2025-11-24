# frozen_string_literal: true

class RemoveWorkOrderRateUnitIdFromWorkOrders < ActiveRecord::Migration[8.1]
  disable_ddl_transaction!

  def up
    if index_exists?(:work_orders, :work_order_rate_unit_id, name: 'index_work_orders_on_work_order_rate_unit_id')
      safety_assured do
        execute <<-SQL
          DROP INDEX CONCURRENTLY IF EXISTS index_work_orders_on_work_order_rate_unit_id;
        SQL
      end
    end
    return unless column_exists?(:work_orders, :work_order_rate_unit_id)

    safety_assured { remove_column :work_orders, :work_order_rate_unit_id }
  end

  def down
    add_column :work_orders, :work_order_rate_unit_id, :integer unless column_exists?(:work_orders,
                                                                                      :work_order_rate_unit_id)
    unless index_exists?(:work_orders, :work_order_rate_unit_id, name: 'index_work_orders_on_work_order_rate_unit_id')
      add_index :work_orders, :work_order_rate_unit_id,
                name: 'index_work_orders_on_work_order_rate_unit_id',
                algorithm: :concurrently
    end
  end
end
