class AddUnitIdToWorkOrderItems < ActiveRecord::Migration[8.1]
  def change
    add_column :work_order_items, :unit_id, :integer
  end
end
