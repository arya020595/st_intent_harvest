class AddDateOfBirthToWorkers < ActiveRecord::Migration[7.0]
  def change
    add_column :workers, :date_of_birth, :date
  end
end
