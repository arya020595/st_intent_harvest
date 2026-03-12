# frozen_string_literal: true

class AddFieldConductorToWorkOrders < ActiveRecord::Migration[8.1]
  disable_ddl_transaction!

  def change
    add_reference :work_orders, :field_conductor, index: { algorithm: :concurrently }
  end
end
