class RemoveUniqueIndexFromDeductionTypesCode < ActiveRecord::Migration[8.1]
  disable_ddl_transaction!

  def change
    # Remove unique index on code to allow multiple records with same code
    # (needed for effective date tracking - same code can have different rates over time)
    remove_index :deduction_types, :code if index_exists?(:deduction_types, :code, unique: true)

    # Add non-unique index for query performance
    add_index :deduction_types, :code, algorithm: :concurrently unless index_exists?(:deduction_types, :code)

    # Add composite index for common query: finding current active deduction by code
    return if index_exists?(:deduction_types, %i[code effective_until])

    add_index :deduction_types, %i[code effective_until],
              name: 'index_deduction_types_on_code_and_effective_until',
              algorithm: :concurrently
  end
end
