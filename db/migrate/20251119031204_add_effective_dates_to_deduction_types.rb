class AddEffectiveDatesToDeductionTypes < ActiveRecord::Migration[8.1]
  disable_ddl_transaction!

  def change
    add_column :deduction_types, :effective_from, :date unless column_exists?(:deduction_types, :effective_from)

    add_column :deduction_types, :effective_until, :date unless column_exists?(:deduction_types, :effective_until)

    unless index_exists?(:deduction_types, :effective_from)
      add_index :deduction_types, :effective_from, algorithm: :concurrently
    end

    unless index_exists?(:deduction_types, :effective_until)
      add_index :deduction_types, :effective_until, algorithm: :concurrently
    end

    # Set default effective_from to created_at for existing records
    reversible do |dir|
      dir.up do
        safety_assured do
          execute <<-SQL
            UPDATE deduction_types#{' '}
            SET effective_from = DATE(created_at)
            WHERE effective_from IS NULL
          SQL
        end
      end
    end
  end
end
