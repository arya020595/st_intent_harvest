# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.1].define(version: 2025_12_22_062302) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "audits", force: :cascade do |t|
    t.string "action"
    t.integer "associated_id"
    t.string "associated_type"
    t.integer "auditable_id"
    t.string "auditable_type"
    t.text "audited_changes"
    t.string "comment"
    t.datetime "created_at"
    t.string "remote_address"
    t.string "request_uuid"
    t.integer "user_id"
    t.string "user_type"
    t.string "username"
    t.integer "version", default: 0
    t.index ["associated_type", "associated_id"], name: "associated_index"
    t.index ["auditable_type", "auditable_id", "version"], name: "auditable_index"
    t.index ["created_at"], name: "index_audits_on_created_at"
    t.index ["request_uuid"], name: "index_audits_on_request_uuid"
    t.index ["user_id", "user_type"], name: "user_index"
  end

  create_table "blocks", force: :cascade do |t|
    t.string "block_number"
    t.datetime "created_at", null: false
    t.datetime "discarded_at"
    t.decimal "hectarage", precision: 10, scale: 2
    t.datetime "updated_at", null: false
    t.index ["discarded_at"], name: "index_blocks_on_discarded_at"
  end

  create_table "categories", force: :cascade do |t|
    t.string "category_type"
    t.datetime "created_at", null: false
    t.datetime "discarded_at"
    t.string "name"
    t.integer "parent_id"
    t.datetime "updated_at", null: false
    t.index ["discarded_at"], name: "index_categories_on_discarded_at"
  end

  create_table "deduction_types", force: :cascade do |t|
    t.string "applies_to_nationality", comment: "Nationality filter: all, malaysian, foreign"
    t.string "calculation_type", default: "percentage", null: false, comment: "Type of calculation: percentage (multiply by gross_salary) or fixed (use amount as-is)"
    t.string "code", null: false
    t.datetime "created_at", null: false
    t.text "description"
    t.datetime "discarded_at"
    t.date "effective_from"
    t.date "effective_until"
    t.decimal "employee_contribution", precision: 10, scale: 2, default: "0.0", comment: "Employee's contribution rate (percentage) or fixed amount (RM)"
    t.decimal "employer_contribution", precision: 10, scale: 2, default: "0.0", comment: "Employer's contribution rate (percentage) or fixed amount (RM)"
    t.boolean "is_active", default: true, null: false
    t.string "name", null: false
    t.datetime "updated_at", null: false
    t.index ["applies_to_nationality"], name: "index_deduction_types_on_applies_to_nationality"
    t.index ["calculation_type"], name: "index_deduction_types_on_calculation_type"
    t.index ["code", "effective_until"], name: "index_deduction_types_on_code_and_effective_until"
    t.index ["code"], name: "index_deduction_types_on_code"
    t.index ["discarded_at"], name: "index_deduction_types_on_discarded_at"
    t.index ["effective_from"], name: "index_deduction_types_on_effective_from"
    t.index ["effective_until"], name: "index_deduction_types_on_effective_until"
    t.index ["is_active"], name: "index_deduction_types_on_is_active"
  end

  create_table "deduction_wage_ranges", force: :cascade do |t|
    t.string "calculation_method", default: "fixed", null: false
    t.datetime "created_at", null: false
    t.bigint "deduction_type_id", null: false
    t.datetime "discarded_at"
    t.decimal "employee_amount", precision: 10, scale: 2, default: "0.0", null: false
    t.decimal "employee_percentage", precision: 5, scale: 2, default: "0.0", null: false
    t.decimal "employer_amount", precision: 10, scale: 2, default: "0.0", null: false
    t.decimal "employer_percentage", precision: 5, scale: 2, default: "0.0", null: false
    t.decimal "max_wage", precision: 10, scale: 2
    t.decimal "min_wage", precision: 10, scale: 2, null: false
    t.datetime "updated_at", null: false
    t.index "deduction_type_id, min_wage, COALESCE(max_wage, (999999999)::numeric)", name: "idx_wage_ranges_unique", unique: true
    t.index ["deduction_type_id", "min_wage", "max_wage"], name: "idx_wage_ranges_salary_lookup"
    t.index ["deduction_type_id"], name: "index_deduction_wage_ranges_on_deduction_type_id"
    t.index ["discarded_at"], name: "index_deduction_wage_ranges_on_discarded_at"
    t.check_constraint "calculation_method::text = ANY (ARRAY['fixed'::character varying, 'percentage'::character varying]::text[])", name: "calculation_method_check"
    t.check_constraint "max_wage IS NULL OR max_wage >= min_wage", name: "max_wage_check"
  end

  create_table "inventories", force: :cascade do |t|
    t.bigint "category_id"
    t.datetime "created_at", null: false
    t.datetime "discarded_at"
    t.string "name", null: false
    t.bigint "unit_id"
    t.datetime "updated_at", null: false
    t.index ["category_id"], name: "index_inventories_on_category_id"
    t.index ["discarded_at"], name: "index_inventories_on_discarded_at"
    t.index ["unit_id"], name: "index_inventories_on_unit_id"
  end

  create_table "inventory_orders", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.date "date_of_arrival"
    t.datetime "discarded_at"
    t.bigint "inventory_id", null: false
    t.date "purchase_date", null: false
    t.integer "quantity", null: false
    t.string "supplier", null: false
    t.decimal "total_price", precision: 10, scale: 2, null: false
    t.decimal "unit_price", precision: 10, scale: 2
    t.datetime "updated_at", null: false
    t.index ["discarded_at"], name: "index_inventory_orders_on_discarded_at"
    t.index ["inventory_id"], name: "index_inventory_orders_on_inventory_id"
    t.index ["purchase_date"], name: "index_inventory_orders_on_purchase_date"
  end

  create_table "mandays", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "discarded_at"
    t.datetime "updated_at", null: false
    t.date "work_month", null: false
    t.index ["discarded_at"], name: "index_mandays_on_discarded_at"
    t.index ["work_month"], name: "index_mandays_on_work_month", unique: true, comment: "Ensure one manday entry per month"
  end

  create_table "mandays_workers", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "days"
    t.datetime "discarded_at"
    t.bigint "manday_id", null: false
    t.text "remarks"
    t.datetime "updated_at", null: false
    t.bigint "worker_id", null: false
    t.index ["discarded_at"], name: "index_mandays_workers_on_discarded_at"
    t.index ["manday_id", "worker_id"], name: "index_mandays_workers_on_manday_id_and_worker_id", unique: true, comment: "Ensure one entry per worker per month"
    t.index ["manday_id"], name: "index_mandays_workers_on_manday_id"
    t.index ["worker_id"], name: "index_mandays_workers_on_worker_id"
  end

  create_table "pay_calculation_details", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "currency", default: "RM"
    t.jsonb "deduction_breakdown", comment: "JSON breakdown of deductions: {EPF: {worker: 0, employee: 0}, SOCSO: {...}}"
    t.decimal "deductions", precision: 10, scale: 2
    t.datetime "discarded_at"
    t.decimal "employee_deductions", precision: 10, scale: 2, default: "0.0", null: false, comment: "Employee's total deductions (deducted from salary)"
    t.decimal "employer_deductions", precision: 10, scale: 2, default: "0.0", null: false, comment: "Employer's total contributions (company cost)"
    t.decimal "gross_salary", precision: 10, scale: 2
    t.decimal "net_salary", precision: 10, scale: 2
    t.bigint "pay_calculation_id", null: false
    t.datetime "updated_at", null: false
    t.bigint "worker_id", null: false
    t.index ["discarded_at"], name: "index_pay_calculation_details_on_discarded_at"
    t.index ["pay_calculation_id"], name: "index_pay_calculation_details_on_pay_calculation_id"
    t.index ["worker_id"], name: "index_pay_calculation_details_on_worker_id"
  end

  create_table "pay_calculations", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "discarded_at"
    t.string "month_year", null: false
    t.decimal "total_deductions", precision: 10, scale: 2, default: "0.0", null: false
    t.decimal "total_gross_salary", precision: 10, scale: 2, default: "0.0", null: false
    t.decimal "total_net_salary", precision: 10, scale: 2, default: "0.0", null: false
    t.datetime "updated_at", null: false
    t.index ["discarded_at"], name: "index_pay_calculations_on_discarded_at"
  end

  create_table "permissions", force: :cascade do |t|
    t.string "code", null: false
    t.datetime "created_at", null: false
    t.datetime "discarded_at"
    t.string "name", null: false
    t.string "resource", null: false
    t.string "section"
    t.datetime "updated_at", null: false
    t.index ["code"], name: "index_permissions_on_code", unique: true
    t.index ["discarded_at"], name: "index_permissions_on_discarded_at"
    t.index ["resource"], name: "index_permissions_on_resource"
  end

  create_table "roles", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.text "description"
    t.datetime "discarded_at"
    t.string "name"
    t.datetime "updated_at", null: false
    t.index ["discarded_at"], name: "index_roles_on_discarded_at"
  end

  create_table "roles_permissions", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "discarded_at"
    t.bigint "permission_id", null: false
    t.bigint "role_id", null: false
    t.datetime "updated_at", null: false
    t.index ["discarded_at"], name: "index_roles_permissions_on_discarded_at"
    t.index ["permission_id"], name: "index_roles_permissions_on_permission_id"
    t.index ["role_id", "permission_id"], name: "index_roles_permissions_on_role_id_and_permission_id", unique: true
    t.index ["role_id"], name: "index_roles_permissions_on_role_id"
  end

  create_table "units", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "discarded_at"
    t.string "name"
    t.string "unit_type"
    t.datetime "updated_at", null: false
    t.index ["discarded_at"], name: "index_units_on_discarded_at"
  end

  create_table "users", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "current_sign_in_at"
    t.string "current_sign_in_ip"
    t.datetime "discarded_at"
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.boolean "is_active", default: true
    t.datetime "last_sign_in_at"
    t.string "last_sign_in_ip"
    t.string "name"
    t.datetime "remember_created_at"
    t.datetime "reset_password_sent_at"
    t.string "reset_password_token"
    t.bigint "role_id"
    t.integer "sign_in_count", default: 0, null: false
    t.datetime "updated_at", null: false
    t.index ["discarded_at"], name: "index_users_on_discarded_at"
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
    t.index ["role_id"], name: "index_users_on_role_id"
  end

  create_table "vehicles", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "discarded_at"
    t.datetime "updated_at", null: false
    t.string "vehicle_model"
    t.string "vehicle_number"
    t.index ["discarded_at"], name: "index_vehicles_on_discarded_at"
  end

  create_table "work_order_histories", force: :cascade do |t|
    t.string "action"
    t.datetime "created_at", null: false
    t.datetime "discarded_at"
    t.string "from_state"
    t.text "remarks"
    t.string "to_state"
    t.jsonb "transition_details", default: {}
    t.datetime "updated_at", null: false
    t.bigint "user_id"
    t.string "user_name"
    t.bigint "work_order_id", null: false
    t.index ["discarded_at"], name: "index_work_order_histories_on_discarded_at"
    t.index ["user_id"], name: "index_work_order_histories_on_user_id"
    t.index ["work_order_id", "created_at"], name: "index_work_order_histories_on_order_and_created"
    t.index ["work_order_id"], name: "index_work_order_histories_on_work_order_id"
  end

  create_table "work_order_items", force: :cascade do |t|
    t.integer "amount_used"
    t.string "category_name"
    t.datetime "created_at", null: false
    t.datetime "discarded_at"
    t.bigint "inventory_id"
    t.string "item_name"
    t.decimal "price", precision: 10, scale: 2
    t.integer "unit_id"
    t.string "unit_name"
    t.datetime "updated_at", null: false
    t.bigint "work_order_id", null: false
    t.index ["discarded_at"], name: "index_work_order_items_on_discarded_at"
    t.index ["inventory_id"], name: "index_work_order_items_on_inventory_id"
    t.index ["work_order_id"], name: "index_work_order_items_on_work_order_id"
  end

  create_table "work_order_rates", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "currency", default: "RM"
    t.datetime "discarded_at"
    t.decimal "rate", precision: 10, scale: 2
    t.bigint "unit_id"
    t.datetime "updated_at", null: false
    t.string "work_order_name"
    t.string "work_order_rate_type", default: "normal", comment: "Type of work order rate: normal (all fields), resources (resource fields only), work_days (worker details only)"
    t.index ["discarded_at"], name: "index_work_order_rates_on_discarded_at"
    t.index ["unit_id"], name: "index_work_order_rates_on_unit_id"
  end

  create_table "work_order_workers", force: :cascade do |t|
    t.decimal "amount", precision: 10, scale: 2
    t.datetime "created_at", null: false
    t.datetime "discarded_at"
    t.decimal "rate", precision: 10, scale: 2
    t.text "remarks"
    t.datetime "updated_at", null: false
    t.decimal "work_area_size", precision: 10, scale: 3
    t.integer "work_days", comment: "How many days worker works in given month"
    t.bigint "work_order_id", null: false
    t.bigint "worker_id", null: false
    t.string "worker_name"
    t.index ["discarded_at"], name: "index_work_order_workers_on_discarded_at"
    t.index ["work_order_id"], name: "index_work_order_workers_on_work_order_id"
    t.index ["worker_id"], name: "index_work_order_workers_on_worker_id"
  end

  create_table "work_orders", force: :cascade do |t|
    t.datetime "approved_at"
    t.string "approved_by"
    t.string "block_hectarage"
    t.bigint "block_id"
    t.string "block_number"
    t.date "completion_date"
    t.datetime "created_at", null: false
    t.date "date_of_usage"
    t.datetime "discarded_at"
    t.bigint "field_conductor_id"
    t.string "field_conductor_name"
    t.date "start_date"
    t.datetime "updated_at", null: false
    t.bigint "vehicle_id"
    t.string "vehicle_model"
    t.string "vehicle_number"
    t.date "work_month", comment: "First day of the month for Mandays calculation"
    t.bigint "work_order_rate_id"
    t.string "work_order_rate_name"
    t.decimal "work_order_rate_price", precision: 10, scale: 2
    t.string "work_order_rate_type"
    t.string "work_order_rate_unit_name"
    t.string "work_order_status", default: "ongoing"
    t.index ["block_id", "work_order_rate_id"], name: "index_work_orders_on_block_and_rate"
    t.index ["block_id"], name: "index_work_orders_on_block_id"
    t.index ["discarded_at"], name: "index_work_orders_on_discarded_at"
    t.index ["field_conductor_id"], name: "index_work_orders_on_field_conductor_id"
    t.index ["vehicle_id"], name: "index_work_orders_on_vehicle_id"
    t.index ["work_order_rate_id"], name: "index_work_orders_on_work_order_rate_id"
    t.index ["work_order_rate_type"], name: "index_work_orders_on_work_order_rate_type"
    t.index ["work_order_rate_unit_name"], name: "index_work_orders_on_work_order_rate_unit_name"
  end

  create_table "workers", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "discarded_at"
    t.string "gender"
    t.date "hired_date"
    t.string "identity_number"
    t.boolean "is_active"
    t.string "name"
    t.string "nationality"
    t.string "position"
    t.datetime "updated_at", null: false
    t.string "worker_type"
    t.index ["discarded_at"], name: "index_workers_on_discarded_at"
  end

  add_foreign_key "deduction_wage_ranges", "deduction_types", on_delete: :cascade
  add_foreign_key "inventories", "categories"
  add_foreign_key "inventories", "units"
  add_foreign_key "inventory_orders", "inventories"
  add_foreign_key "mandays_workers", "mandays"
  add_foreign_key "mandays_workers", "workers"
  add_foreign_key "pay_calculation_details", "pay_calculations"
  add_foreign_key "pay_calculation_details", "workers"
  add_foreign_key "roles_permissions", "permissions"
  add_foreign_key "roles_permissions", "roles"
  add_foreign_key "users", "roles"
  add_foreign_key "work_order_histories", "users"
  add_foreign_key "work_order_histories", "work_orders"
  add_foreign_key "work_order_items", "inventories"
  add_foreign_key "work_order_items", "work_orders"
  add_foreign_key "work_order_rates", "units"
  add_foreign_key "work_order_workers", "work_orders"
  add_foreign_key "work_order_workers", "workers"
  add_foreign_key "work_orders", "blocks"
  add_foreign_key "work_orders", "users", column: "field_conductor_id"
  add_foreign_key "work_orders", "vehicles", validate: false
  add_foreign_key "work_orders", "work_order_rates"
end
