# frozen_string_literal: true

class CreateRoles < ActiveRecord::Migration[7.2]
  def change
    create_table :roles do |t|
      t.string :name
      t.text :description

      t.timestamps
    end
  end
end
