# frozen_string_literal: true

class ChangeWorkAreaSizeToDecimalInWorkOrderWorkers < ActiveRecord::Migration[8.1]
  def up
    safety_assured do
      change_column :work_order_workers, :work_area_size, :decimal, precision: 10, scale: 3
    end
  end

  def down
    safety_assured do
      change_column :work_order_workers, :work_area_size, :integer
    end
  end
end
