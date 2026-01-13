class CreateMandaysWorkers < ActiveRecord::Migration[8.1]
  def change
    create_table :mandays_workers do |t|
      t.references :worker, null: false, foreign_key: true
      t.references :manday, null: false, foreign_key: true
      t.integer :days
      t.text :remarks

      t.timestamps
    end

    add_index :mandays_workers, %i[manday_id worker_id], unique: true,
                                                         comment: 'Ensure one entry per worker per month'
  end
end
