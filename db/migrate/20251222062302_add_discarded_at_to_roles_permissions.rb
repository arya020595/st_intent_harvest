class AddDiscardedAtToRolesPermissions < ActiveRecord::Migration[8.1]
  disable_ddl_transaction!

  def change
    add_column :roles_permissions, :discarded_at, :datetime
    add_index :roles_permissions, :discarded_at, algorithm: :concurrently
  end
end
