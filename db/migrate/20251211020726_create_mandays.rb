class CreateMandays < ActiveRecord::Migration[8.1]
  def change
    create_table :mandays do |t|
      t.date :work_month

      t.timestamps
    end
  end
end
