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

ActiveRecord::Schema[7.0].define(version: 2024_08_22_170829) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "customers", force: :cascade do |t|
    t.string "first_name"
    t.string "last_name"
    t.string "email"
    t.decimal "paid_orders_summary", precision: 8, scale: 2, default: "0.0"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "vip", default: false
  end

  create_table "invoices_tbl", force: :cascade do |t|
    t.bigint "order_id"
    t.string "order_number"
    t.decimal "total_value", precision: 10, scale: 2
    t.string "address"
    t.datetime "payment_date"
    t.datetime "issued_at"
    t.bigint "tax_id_number"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "order_items", force: :cascade do |t|
    t.bigint "order_id", null: false
    t.bigint "product_id", null: false
    t.integer "quantity"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["order_id"], name: "index_order_items_on_order_id"
    t.index ["product_id"], name: "index_order_items_on_product_id"
  end

  create_table "orders", force: :cascade do |t|
    t.string "number"
    t.string "address"
    t.string "phone"
    t.string "email"
    t.string "status"
    t.decimal "total", precision: 10, scale: 2
    t.decimal "discount", precision: 10, scale: 2
    t.datetime "completed_at"
    t.datetime "discount_updated_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "customer_id"
    t.string "country"
    t.string "city"
    t.string "street"
    t.string "zip"
    t.string "addressed_to"
    t.string "invoice_address"
    t.string "invoice_tax_id_number"
    t.boolean "invoice_issued", default: false
    t.date "invoice_issue_date"
    t.date "invoice_disposal_date"
    t.date "invoice_payment_date"
    t.decimal "invoice_total_value", precision: 8, scale: 2
    t.string "invoice_country"
    t.string "invoice_city"
    t.string "invoice_addressed_to"
    t.string "invoice_payment_status", default: "Unpaid"
    t.index ["customer_id"], name: "index_orders_on_customer_id"
  end

  create_table "products", force: :cascade do |t|
    t.string "name"
    t.decimal "price", precision: 10, scale: 2
    t.integer "vat_rate"
    t.boolean "active", default: true
    t.string "sku"
    t.string "description"
    t.string "category"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "stock_level"
    t.decimal "future_price", precision: 8, scale: 2
    t.datetime "future_price_start_time"
  end

  create_table "time_promotions", force: :cascade do |t|
    t.datetime "start_time"
    t.datetime "end_time"
    t.string "label"
    t.decimal "discount", precision: 5, scale: 2
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  add_foreign_key "order_items", "orders"
  add_foreign_key "order_items", "products"
  add_foreign_key "orders", "customers"
end
