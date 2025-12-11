class AddPositionToWorkers < ActiveRecord::Migration[8.1]
  def change
    add_column :workers, :position, :string
  end
end
