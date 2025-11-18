class CreateDeductionTypes < ActiveRecord::Migration[8.1]
  def change
    create_table :deduction_types do |t|
      t.string :name, null: false
      t.string :code, null: false
      t.text :description
      t.boolean :is_active, default: true, null: false
      t.decimal :worker_amount, precision: 10, scale: 2, default: 0, null: false,
                                comment: 'Fixed worker contribution amount in RM'
      t.decimal :employee_amount, precision: 10, scale: 2, default: 0, null: false,
                                  comment: 'Fixed employer contribution amount in RM'

      t.timestamps
    end

    add_index :deduction_types, :code, unique: true
    add_index :deduction_types, :is_active
  end
end
