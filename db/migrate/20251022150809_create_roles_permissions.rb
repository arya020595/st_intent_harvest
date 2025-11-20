# frozen_string_literal: true

class CreateRolesPermissions < ActiveRecord::Migration[7.2]
  def change
    create_table :roles_permissions do |t|
      t.references :role, foreign_key: true, null: false
      t.references :permission, foreign_key: true, null: false

      t.timestamps
    end

    add_index :roles_permissions, %i[role_id permission_id], unique: true
  end
end
