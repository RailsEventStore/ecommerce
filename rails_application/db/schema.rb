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

ActiveRecord::Schema[7.0].define(version: 2023_02_02_175228) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pgcrypto"
  enable_extension "plpgsql"

  create_table "accounts", force: :cascade do |t|
    t.uuid "client_id"
    t.text "password"
    t.uuid "account_id"
  end

  create_table "availability_products", force: :cascade do |t|
    t.uuid "uid"
    t.integer "available"
  end

  create_table "client_order_lines", force: :cascade do |t|
    t.string "order_uid"
    t.string "product_name"
    t.integer "product_quantity"
    t.decimal "product_price", precision: 8, scale: 2
    t.uuid "product_id"
  end

  create_table "client_order_products", force: :cascade do |t|
    t.uuid "uid", null: false
    t.string "name"
    t.decimal "price", precision: 8, scale: 2
  end

  create_table "client_orders", force: :cascade do |t|
    t.uuid "client_uid"
    t.string "number"
    t.uuid "order_uid"
    t.string "state"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "client_name"
    t.decimal "percentage_discount", precision: 8, scale: 2
    t.decimal "total_value", precision: 8, scale: 2
    t.decimal "discounted_value", precision: 8, scale: 2
  end

  create_table "clients", force: :cascade do |t|
    t.uuid "uid"
    t.string "name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.decimal "paid_orders_summary", precision: 8, scale: 2, default: "0.0"
  end

  create_table "coupons", force: :cascade do |t|
    t.uuid "uid", null: false
    t.string "name"
    t.string "code"
    t.decimal "discount"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "customers", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "name"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.datetime "registered_at", precision: nil
    t.boolean "vip", default: false, null: false
    t.decimal "paid_orders_summary", precision: 8, scale: 2, default: "0.0"
    t.uuid "account_id"
  end

  create_table "event_store_events", id: :serial, force: :cascade do |t|
    t.uuid "event_id", null: false
    t.string "event_type", null: false
    t.jsonb "metadata"
    t.jsonb "data", null: false
    t.datetime "created_at", precision: nil, null: false
    t.datetime "valid_at", precision: nil
    t.index ["created_at"], name: "index_event_store_events_on_created_at"
    t.index ["event_id"], name: "index_event_store_events_on_event_id", unique: true
    t.index ["event_type"], name: "index_event_store_events_on_event_type"
    t.index ["valid_at"], name: "index_event_store_events_on_valid_at"
  end

  create_table "event_store_events_in_streams", id: :serial, force: :cascade do |t|
    t.string "stream", null: false
    t.integer "position"
    t.uuid "event_id", null: false
    t.datetime "created_at", precision: nil, null: false
    t.index ["created_at"], name: "index_event_store_events_in_streams_on_created_at"
    t.index ["stream", "event_id"], name: "index_event_store_events_in_streams_on_stream_and_event_id", unique: true
    t.index ["stream", "position"], name: "index_event_store_events_in_streams_on_stream_and_position", unique: true
  end

  create_table "invoice_items", force: :cascade do |t|
    t.bigint "invoice_id"
    t.string "name"
    t.decimal "unit_price", precision: 8, scale: 2
    t.decimal "vat_rate", precision: 4, scale: 1
    t.integer "quantity"
    t.decimal "value", precision: 8, scale: 2
    t.index ["invoice_id"], name: "index_invoice_items_on_invoice_id"
  end

  create_table "invoices", force: :cascade do |t|
    t.string "order_uid", null: false
    t.string "number"
    t.string "tax_id_number"
    t.string "address_line_1"
    t.string "address_line_2"
    t.string "address_line_3"
    t.string "address_line_4"
    t.boolean "address_present", default: false
    t.boolean "issued", default: false
    t.date "issue_date"
    t.date "disposal_date"
    t.date "payment_date"
    t.decimal "total_value", precision: 8, scale: 2
  end

  create_table "invoices_orders", force: :cascade do |t|
    t.uuid "uid", null: false
    t.boolean "submitted", default: false
  end

  create_table "order_lines", force: :cascade do |t|
    t.uuid "order_uid", null: false
    t.string "product_name"
    t.integer "quantity"
    t.decimal "price", precision: 8, scale: 2
    t.uuid "product_id"
  end

  create_table "orders", force: :cascade do |t|
    t.uuid "uid", null: false
    t.string "number"
    t.string "customer"
    t.string "state"
    t.decimal "percentage_discount", precision: 8, scale: 2
    t.decimal "total_value", precision: 8, scale: 2
    t.decimal "discounted_value", precision: 8, scale: 2
    t.decimal "happy_hour_value", precision: 8, scale: 2
    t.datetime "total_value_updated_at"
    t.datetime "discount_updated_at"
    t.index ["uid"], name: "index_orders_on_uid", unique: true
  end

  create_table "orders_customers", force: :cascade do |t|
    t.uuid "uid", null: false
    t.string "name"
  end

  create_table "orders_products", force: :cascade do |t|
    t.uuid "uid", null: false
    t.string "name"
    t.decimal "price", precision: 8, scale: 2
  end

  create_table "products", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "name"
    t.integer "stock_level"
    t.datetime "registered_at", precision: nil
    t.string "vat_rate_code"
    t.text "current_prices_calendar"
  end

  create_table "public_offer_products", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "name"
    t.decimal "price"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.decimal "lowest_recent_price", precision: 8, scale: 2
  end

  create_table "shipments", force: :cascade do |t|
    t.string "order_uid", null: false
    t.string "address_line_1"
    t.string "address_line_2"
    t.string "address_line_3"
    t.string "address_line_4"
  end

  create_table "shipments_orders", force: :cascade do |t|
    t.uuid "uid", null: false
    t.boolean "submitted", default: false
  end

  create_table "time_promotions", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "label"
    t.integer "discount"
    t.datetime "start_time"
    t.datetime "end_time"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "active", default: false
  end

end
