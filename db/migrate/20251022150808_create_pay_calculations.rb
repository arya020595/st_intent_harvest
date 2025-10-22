class CreatePayCalculations < ActiveRecord::Migration[7.2]
  def change
    create_table :pay_calculations do |t|
      t.string :month_year, null: false
      t.decimal :overall_total, precision: 10, scale: 2

      t.timestamps
    end
  end
end
