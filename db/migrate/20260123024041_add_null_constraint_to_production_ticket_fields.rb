class AddNullConstraintToProductionTicketFields < ActiveRecord::Migration[8.1]
  def change
    change_column_null :productions, :ticket_estate_no, false
    change_column_null :productions, :ticket_mill_no, false
  end
end
