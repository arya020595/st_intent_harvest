class CreateMills < ActiveRecord::Migration[8.1]
  def change
    create_table :mills do |t|
      t.string :name, null: false
      t.datetime :discarded_at, index: true

      t.timestamps
    end

    add_index :mills, :name, unique: true
  end
end
