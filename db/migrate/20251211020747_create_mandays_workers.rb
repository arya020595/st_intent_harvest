class CreateMandaysWorkers < ActiveRecord::Migration[8.1]
  def change
    create_table :mandays_workers do |t|
      t.string :worker_name
      t.integer :days
      t.text :remarks
      t.references :manday, null: false, foreign_key: true

      t.timestamps
    end
  end
end
