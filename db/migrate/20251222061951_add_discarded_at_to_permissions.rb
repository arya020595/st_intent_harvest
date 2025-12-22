class AddDiscardedAtToPermissions < ActiveRecord::Migration[8.1]
  disable_ddl_transaction!

  def change
    add_column :permissions, :discarded_at, :datetime
    add_index :permissions, :discarded_at, algorithm: :concurrently
  end
end
