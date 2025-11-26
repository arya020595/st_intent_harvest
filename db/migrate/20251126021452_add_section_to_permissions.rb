class AddSectionToPermissions < ActiveRecord::Migration[8.1]
  def change
    add_column :permissions, :section, :string
  end
end
