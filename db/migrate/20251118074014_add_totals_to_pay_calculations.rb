# frozen_string_literal: true

class AddTotalsToPayCalculations < ActiveRecord::Migration[8.1]
  def change
    add_column :pay_calculations, :total_gross_salary, :decimal, precision: 10, scale: 2, default: 0, null: false
    add_column :pay_calculations, :total_deductions, :decimal, precision: 10, scale: 2, default: 0, null: false
    add_column :pay_calculations, :total_net_salary, :decimal, precision: 10, scale: 2, default: 0, null: false
  end
end
