# frozen_string_literal: true

class RemoveOverallTotalFromPayCalculations < ActiveRecord::Migration[8.1]
  def change
    safety_assured { remove_column :pay_calculations, :overall_total, :decimal }
  end
end
