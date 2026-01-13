# frozen_string_literal: true

class CreateMandays < ActiveRecord::Migration[8.1]
  def change
    create_table :mandays do |t|
      t.date :work_month, null: false

      t.timestamps
    end

    add_index :mandays, :work_month, unique: true, comment: 'Ensure one manday entry per month'
  end
end
