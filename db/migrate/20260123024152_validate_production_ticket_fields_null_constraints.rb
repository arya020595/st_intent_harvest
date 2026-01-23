class ValidateProductionTicketFieldsNullConstraints < ActiveRecord::Migration[8.1]
  disable_ddl_transaction!

  def up
    validate_check_constraint :productions, name: "productions_ticket_estate_no_null"
    change_column_null :productions, :ticket_estate_no, false
    remove_check_constraint :productions, name: "productions_ticket_estate_no_null"

    validate_check_constraint :productions, name: "productions_ticket_mill_no_null"
    change_column_null :productions, :ticket_mill_no, false
    remove_check_constraint :productions, name: "productions_ticket_mill_no_null"
  end

  def down
    add_check_constraint :productions, "ticket_estate_no IS NOT NULL", name: "productions_ticket_estate_no_null", validate: false
    change_column_null :productions, :ticket_estate_no, true

    add_check_constraint :productions, "ticket_mill_no IS NOT NULL", name: "productions_ticket_mill_no_null", validate: false
    change_column_null :productions, :ticket_mill_no, true
  end
end
