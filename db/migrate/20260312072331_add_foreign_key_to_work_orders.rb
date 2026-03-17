class AddForeignKeyToWorkOrders < ActiveRecord::Migration[8.1]
  def change
    constraint_exists = safety_assured {
      execute("SELECT 1 FROM pg_constraint WHERE conname = 'fk_rails_d5db43ba21'").any?
    }

    unless constraint_exists
      add_foreign_key :work_orders, :field_conductors, validate: false
    end
  end
end
