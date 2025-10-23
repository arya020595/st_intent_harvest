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

ActiveRecord::Schema[7.2].define(version: 2025_10_22_231803) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "blocks", force: :cascade do |t|
    t.string "block_number"
    t.decimal "hectarage", precision: 10, scale: 2
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "categories", force: :cascade do |t|
    t.string "name"
    t.string "category_type"
    t.integer "parent_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "inventories", force: :cascade do |t|
    t.string "name", null: false
    t.integer "stock_quantity", default: 0
    t.bigint "category_id"
    t.bigint "unit_id"
    t.decimal "price", precision: 10, scale: 2
    t.string "supplier"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "currency", default: "RM"
    t.index ["category_id"], name: "index_inventories_on_category_id"
    t.index ["unit_id"], name: "index_inventories_on_unit_id"
  end

  create_table "pay_calculation_details", force: :cascade do |t|
    t.bigint "pay_calculation_id", null: false
    t.bigint "worker_id", null: false
    t.decimal "gross_salary", precision: 10, scale: 2
    t.decimal "deductions", precision: 10, scale: 2
    t.decimal "net_salary", precision: 10, scale: 2
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "currency", default: "RM"
    t.index ["pay_calculation_id"], name: "index_pay_calculation_details_on_pay_calculation_id"
    t.index ["worker_id"], name: "index_pay_calculation_details_on_worker_id"
  end

  create_table "pay_calculations", force: :cascade do |t|
    t.string "month_year", null: false
    t.decimal "overall_total", precision: 10, scale: 2
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "permissions", force: :cascade do |t|
    t.string "subject"
    t.string "action"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "roles", force: :cascade do |t|
    t.string "name"
    t.text "description"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "roles_permissions", force: :cascade do |t|
    t.bigint "role_id", null: false
    t.bigint "permission_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["permission_id"], name: "index_roles_permissions_on_permission_id"
    t.index ["role_id", "permission_id"], name: "index_roles_permissions_on_role_id_and_permission_id", unique: true
    t.index ["role_id"], name: "index_roles_permissions_on_role_id"
  end

  create_table "units", force: :cascade do |t|
    t.string "name"
    t.string "unit_type"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "users", force: :cascade do |t|
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.string "name"
    t.boolean "is_active", default: true
    t.bigint "role_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
    t.index ["role_id"], name: "index_users_on_role_id"
  end

  create_table "vehicles", force: :cascade do |t|
    t.string "vehicle_number"
    t.string "vehicle_model"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "work_order_items", force: :cascade do |t|
    t.bigint "work_order_id", null: false
    t.bigint "inventory_id"
    t.string "item_name"
    t.integer "amount_used"
    t.decimal "price", precision: 10, scale: 2
    t.string "unit_name"
    t.string "category_name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["inventory_id"], name: "index_work_order_items_on_inventory_id"
    t.index ["work_order_id"], name: "index_work_order_items_on_work_order_id"
  end

  create_table "work_order_rates", force: :cascade do |t|
    t.string "work_order_name"
    t.decimal "rate", precision: 10, scale: 2
    t.bigint "unit_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "currency", default: "RM"
    t.index ["unit_id"], name: "index_work_order_rates_on_unit_id"
  end

  create_table "work_order_workers", force: :cascade do |t|
    t.bigint "work_order_id", null: false
    t.bigint "worker_id", null: false
    t.string "worker_name"
    t.integer "work_area_size"
    t.decimal "rate", precision: 10, scale: 2
    t.decimal "amount", precision: 10, scale: 2
    t.text "remarks"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["work_order_id"], name: "index_work_order_workers_on_work_order_id"
    t.index ["worker_id"], name: "index_work_order_workers_on_worker_id"
  end

  create_table "work_orders", force: :cascade do |t|
    t.bigint "block_id"
    t.string "block_number"
    t.string "block_hectarage"
    t.bigint "work_order_rate_id"
    t.string "work_order_rate_name"
    t.decimal "work_order_rate_price", precision: 10, scale: 2
    t.date "start_date"
    t.string "work_order_status"
    t.string "field_conductor"
    t.string "approved_by"
    t.datetime "approved_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["block_id", "work_order_rate_id"], name: "index_work_orders_on_block_and_rate"
    t.index ["block_id"], name: "index_work_orders_on_block_id"
    t.index ["work_order_rate_id"], name: "index_work_orders_on_work_order_rate_id"
  end

  create_table "workers", force: :cascade do |t|
    t.string "name"
    t.string "worker_type"
    t.string "gender"
    t.boolean "is_active"
    t.date "hired_date"
    t.string "nationality"
    t.string "identity_number"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  add_foreign_key "inventories", "categories"
  add_foreign_key "inventories", "units"
  add_foreign_key "pay_calculation_details", "pay_calculations"
  add_foreign_key "pay_calculation_details", "workers"
  add_foreign_key "roles_permissions", "permissions"
  add_foreign_key "roles_permissions", "roles"
  add_foreign_key "users", "roles"
  add_foreign_key "work_order_items", "inventories"
  add_foreign_key "work_order_items", "work_orders"
  add_foreign_key "work_order_rates", "units"
  add_foreign_key "work_order_workers", "work_orders"
  add_foreign_key "work_order_workers", "workers"
  add_foreign_key "work_orders", "blocks"
  add_foreign_key "work_orders", "work_order_rates"
end
