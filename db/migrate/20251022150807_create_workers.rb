# frozen_string_literal: true

class CreateWorkers < ActiveRecord::Migration[7.2]
  def change
    create_table :workers do |t|
      t.string :name
      t.string :worker_type
      t.string :gender
      t.boolean :is_active
      t.date :hired_date
      t.string :nationality
      t.string :identity_number

      t.timestamps
    end
  end
end
