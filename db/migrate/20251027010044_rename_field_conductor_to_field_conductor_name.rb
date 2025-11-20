# frozen_string_literal: true

class RenameFieldConductorToFieldConductorName < ActiveRecord::Migration[8.1]
  def change
    rename_column :work_orders, :field_conductor, :field_conductor_name
  end
end
