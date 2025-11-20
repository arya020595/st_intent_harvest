# frozen_string_literal: true

class AddIndexToPermissions < ActiveRecord::Migration[8.1]
  def change
    add_index :permissions, %i[subject action], unique: true, name: 'index_permissions_on_subject_and_action'
  end
end
