class AddNullConstraintToProductionTicketFields < ActiveRecord::Migration[8.1]
  def change
    add_check_constraint :productions, "ticket_estate_no IS NOT NULL", name: "productions_ticket_estate_no_null", validate: false
    add_check_constraint :productions, "ticket_mill_no IS NOT NULL", name: "productions_ticket_mill_no_null", validate: false
  end
end
