# frozen_string_literal: true

# Migration to add discarded_at column to all models for soft delete functionality
#
# This adds the discarded_at column to tables that should support soft delete.
# Tables excluded: audits (system table), permissions, roles_permissions (reference data)
#
class AddDiscardedAtToAllModels < ActiveRecord::Migration[8.1]
  # Disable DDL transaction for concurrent index creation
  disable_ddl_transaction!

  # List of tables to add soft delete support
  # Organized by domain for maintainability (Single Responsibility)
  SOFT_DELETABLE_TABLES = %i[
    blocks
    categories
    deduction_types
    deduction_wage_ranges
    inventories
    inventory_orders
    mandays
    mandays_workers
    pay_calculations
    pay_calculation_details
    roles
    units
    users
    vehicles
    work_orders
    work_order_histories
    work_order_items
    work_order_rates
    work_order_workers
    workers
  ].freeze

  def up
    SOFT_DELETABLE_TABLES.each do |table_name|
      unless column_exists?(table_name, :discarded_at)
        add_column table_name, :discarded_at, :datetime
        say "Added discarded_at column to #{table_name}"
      end

      unless index_exists?(table_name, :discarded_at)
        add_index table_name, :discarded_at, algorithm: :concurrently
        say "Added discarded_at index to #{table_name}"
      end
    end
  end

  def down
    SOFT_DELETABLE_TABLES.each do |table_name|
      next unless column_exists?(table_name, :discarded_at)

      remove_index table_name, :discarded_at, algorithm: :concurrently if index_exists?(table_name, :discarded_at)
      remove_column table_name, :discarded_at

      say "Removed discarded_at from #{table_name}"
    end
  end
end
