class CreatePayCalculationDetails < ActiveRecord::Migration[7.2]
  def change
    create_table :pay_calculation_details do |t|
      t.references :pay_calculation, foreign_key: true, null: false
      t.references :worker, foreign_key: true, null: false
      t.decimal :gross_salary, precision: 10, scale: 2
      t.decimal :deductions, precision: 10, scale: 2
      t.decimal :net_salary, precision: 10, scale: 2

      t.timestamps
    end
  end
end
