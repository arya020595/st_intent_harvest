class CreateMills < ActiveRecord::Migration[8.1]
  def change
    create_table :mills do |t|
      t.string   :mill_name, null: false
      t.datetime :discarded_at, index: true

      t.timestamps
    end
  end
end
