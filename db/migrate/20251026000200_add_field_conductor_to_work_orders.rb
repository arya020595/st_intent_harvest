# frozen_string_literal: true

class AddFieldConductorToWorkOrders < ActiveRecord::Migration[7.2]
  def change
    add_reference :work_orders, :field_conductor, foreign_key: { to_table: :users }, index: true
  end
end
