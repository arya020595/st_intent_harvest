class CreatePermissions < ActiveRecord::Migration[7.2]
  def change
    create_table :permissions do |t|
      t.string :subject
      t.string :action

      t.timestamps
    end
  end
end
