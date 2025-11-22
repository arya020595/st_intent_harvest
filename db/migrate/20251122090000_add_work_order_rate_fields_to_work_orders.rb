# frozen_string_literal: true

class AddWorkOrderRateFieldsToWorkOrders < ActiveRecord::Migration[8.1]
  # Disable the surrounding transaction so we can create/drop indexes concurrently.
  # Creating indexes concurrently avoids blocking writes in production.
  disable_ddl_transaction!

  # Add denormalized work_order_rate fields to work_orders and backfill existing rows.
  # Use direct SQL for the backfill to avoid depending on app models in migrations.
  def up
    # Add columns only if they don't already exist (handles partial runs).
    unless column_exists?(:work_orders, :work_order_rate_unit_name)
      add_column :work_orders, :work_order_rate_unit_name, :string
    end

    add_column :work_orders, :work_order_rate_type, :string unless column_exists?(:work_orders, :work_order_rate_type)

    # Backfill denormalized values from work_order_rates for existing records.
    # strong_migrations cannot inspect raw SQL inside `execute`. Wrap in
    # safety_assured to acknowledge it's safe for our use (backfilling a small
    # predictable set of values). See https://github.com/ankane/strong_migrations
    safety_assured do
      execute <<-SQL
        UPDATE work_orders
        SET work_order_rate_unit_name = units.name,
            work_order_rate_type = work_order_rates.work_order_rate_type
        FROM work_order_rates
        LEFT JOIN units ON units.id = work_order_rates.unit_id
        WHERE work_order_rates.id = work_orders.work_order_rate_id
      SQL
    end

    # Add indexes concurrently to avoid write locks on the table. Check for
    # existing indexes to make this migration safe to run multiple times.
    unless index_exists?(:work_orders, :work_order_rate_unit_name,
                         name: 'index_work_orders_on_work_order_rate_unit_name')
      add_index :work_orders, :work_order_rate_unit_name,
                name: 'index_work_orders_on_work_order_rate_unit_name',
                algorithm: :concurrently
    end

    return if index_exists?(:work_orders, :work_order_rate_type, name: 'index_work_orders_on_work_order_rate_type')

    add_index :work_orders, :work_order_rate_type,
              name: 'index_work_orders_on_work_order_rate_type',
              algorithm: :concurrently
  end

  def down
    # Drop indexes concurrently then remove columns.
    safety_assured do
      execute <<-SQL
        DROP INDEX CONCURRENTLY IF EXISTS index_work_orders_on_work_order_rate_unit_name;
      SQL

      execute <<-SQL
        DROP INDEX CONCURRENTLY IF EXISTS index_work_orders_on_work_order_rate_type;
      SQL
    end

    remove_column :work_orders, :work_order_rate_unit_name if column_exists?(:work_orders, :work_order_rate_unit_name)
    remove_column :work_orders, :work_order_rate_type if column_exists?(:work_orders, :work_order_rate_type)
  end
end
