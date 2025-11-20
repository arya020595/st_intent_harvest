class RefactorPermissionsTable < ActiveRecord::Migration[8.1]
  disable_ddl_transaction!

  def change
    # Clear existing permissions data since we're changing the structure
    safety_assured do
      reversible do |dir|
        dir.up do
          # Delete all existing permissions and their associations
          execute 'DELETE FROM roles_permissions'
          execute 'DELETE FROM permissions'
        end
      end

      # Remove old columns
      remove_column :permissions, :subject, :string
      remove_column :permissions, :action, :string
    end

    # Add new columns
    add_column :permissions, :code, :string, null: false
    add_column :permissions, :name, :string, null: false
    add_column :permissions, :resource, :string, null: false

    # Add unique index on code (concurrently to avoid blocking writes)
    add_index :permissions, :code, unique: true, algorithm: :concurrently

    # Add index on resource for faster filtering (concurrently)
    add_index :permissions, :resource, algorithm: :concurrently
  end
end
