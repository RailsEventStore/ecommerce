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

ActiveRecord::Schema[8.1].define(version: 2026_04_01_120000) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"
  enable_extension "pgcrypto"

  create_table "accounts", force: :cascade do |t|
    t.uuid "account_id"
    t.uuid "client_id"
    t.text "password"
  end

  create_table "admin_stores", id: :uuid, default: nil, force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "name"
    t.datetime "updated_at", null: false
  end

  create_table "authorizations", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.uuid "resource_id"
    t.uuid "store_id"
    t.datetime "updated_at", null: false
    t.index ["resource_id", "store_id"], name: "index_authorizations_on_resource_id_and_store_id"
    t.index ["store_id"], name: "index_authorizations_on_store_id"
  end

  create_table "availability_products", force: :cascade do |t|
    t.integer "available"
    t.uuid "uid"
  end

  create_table "available_vat_rates", force: :cascade do |t|
    t.string "code", null: false
    t.datetime "created_at", null: false
    t.decimal "rate", null: false
    t.uuid "store_id"
    t.uuid "uid", null: false
    t.datetime "updated_at", null: false
  end

  create_table "client_inbox_messages", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "client_uid", null: false
    t.datetime "created_at", null: false
    t.boolean "read", default: false, null: false
    t.string "title", null: false
    t.datetime "updated_at", null: false
    t.index ["client_uid"], name: "index_client_inbox_messages_on_client_uid"
  end

  create_table "client_order_lines", force: :cascade do |t|
    t.string "order_uid"
    t.uuid "product_id"
    t.string "product_name"
    t.decimal "product_price", precision: 8, scale: 2
    t.integer "product_quantity"
  end

  create_table "client_order_products", force: :cascade do |t|
    t.boolean "available", default: true
    t.string "name"
    t.decimal "price", precision: 8, scale: 2
    t.uuid "uid", null: false
  end

  create_table "client_orders", force: :cascade do |t|
    t.string "client_name"
    t.uuid "client_uid"
    t.datetime "created_at", null: false
    t.decimal "discounted_value", precision: 8, scale: 2
    t.string "number"
    t.uuid "order_uid"
    t.decimal "percentage_discount", precision: 8, scale: 2
    t.string "state"
    t.jsonb "time_promotion_discount"
    t.decimal "total_value", precision: 8, scale: 2
    t.datetime "updated_at", null: false
  end

  create_table "clients", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "name"
    t.decimal "paid_orders_summary", precision: 8, scale: 2, default: "0.0"
    t.uuid "uid"
    t.datetime "updated_at", null: false
  end

  create_table "coupons", force: :cascade do |t|
    t.string "code"
    t.datetime "created_at", null: false
    t.decimal "discount"
    t.string "name"
    t.uuid "store_id"
    t.uuid "uid", null: false
    t.datetime "updated_at", null: false
  end

  create_table "customers", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "account_id"
    t.datetime "created_at", precision: nil, null: false
    t.string "name"
    t.decimal "paid_orders_summary", precision: 8, scale: 2, default: "0.0"
    t.datetime "registered_at", precision: nil
    t.uuid "store_id"
    t.datetime "updated_at", precision: nil, null: false
    t.boolean "vip", default: false, null: false
  end

  create_table "deals", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.uuid "customer_id"
    t.string "customer_name"
    t.string "order_number"
    t.string "stage", default: "Draft", null: false
    t.uuid "store_id"
    t.uuid "uid", null: false
    t.datetime "updated_at", null: false
    t.decimal "value", precision: 8, scale: 2
    t.index ["uid"], name: "index_deals_on_uid", unique: true
  end

  create_table "deals_customers", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.uuid "customer_id", null: false
    t.string "name"
    t.datetime "updated_at", null: false
    t.index ["customer_id"], name: "index_deals_customers_on_customer_id", unique: true
  end

  create_table "event_store_events", id: :serial, force: :cascade do |t|
    t.datetime "created_at", precision: nil, null: false
    t.jsonb "data", null: false
    t.uuid "event_id", null: false
    t.string "event_type", null: false
    t.jsonb "metadata"
    t.datetime "valid_at", precision: nil
    t.index ["created_at"], name: "index_event_store_events_on_created_at"
    t.index ["event_id"], name: "index_event_store_events_on_event_id", unique: true
    t.index ["event_type"], name: "index_event_store_events_on_event_type"
    t.index ["valid_at"], name: "index_event_store_events_on_valid_at"
  end

  create_table "event_store_events_in_streams", id: :serial, force: :cascade do |t|
    t.datetime "created_at", precision: nil, null: false
    t.uuid "event_id", null: false
    t.integer "position"
    t.string "stream", null: false
    t.index ["created_at"], name: "index_event_store_events_in_streams_on_created_at"
    t.index ["event_id"], name: "index_event_store_events_in_streams_on_event_id"
    t.index ["stream", "event_id"], name: "index_event_store_events_in_streams_on_stream_and_event_id", unique: true
    t.index ["stream", "position"], name: "index_event_store_events_in_streams_on_stream_and_position", unique: true
  end

  create_table "invoice_items", force: :cascade do |t|
    t.bigint "invoice_id"
    t.string "name"
    t.integer "quantity"
    t.decimal "unit_price", precision: 8, scale: 2
    t.decimal "value", precision: 8, scale: 2
    t.decimal "vat_rate", precision: 4, scale: 1
    t.index ["invoice_id"], name: "index_invoice_items_on_invoice_id"
  end

  create_table "invoices", force: :cascade do |t|
    t.string "address_line_1"
    t.string "address_line_2"
    t.string "address_line_3"
    t.string "address_line_4"
    t.boolean "address_present", default: false
    t.date "disposal_date"
    t.date "issue_date"
    t.boolean "issued", default: false
    t.string "number"
    t.string "order_uid", null: false
    t.date "payment_date"
    t.uuid "store_id"
    t.string "tax_id_number"
    t.decimal "total_value", precision: 8, scale: 2
  end

  create_table "invoices_orders", force: :cascade do |t|
    t.boolean "submitted", default: false
    t.uuid "uid", null: false
  end

  create_table "order_header_customers", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.uuid "customer_id"
    t.string "name"
    t.datetime "updated_at", null: false
    t.index ["customer_id"], name: "index_order_header_customers_on_customer_id", unique: true
  end

  create_table "order_headers", force: :cascade do |t|
    t.boolean "billing_address_present", default: false
    t.datetime "created_at", null: false
    t.string "customer"
    t.uuid "customer_id"
    t.boolean "invoice_issued", default: false
    t.string "invoice_number"
    t.string "number"
    t.boolean "shipping_address_present", default: false
    t.string "state", null: false
    t.uuid "store_id"
    t.uuid "uid", null: false
    t.datetime "updated_at", null: false
    t.index ["uid"], name: "index_order_headers_on_uid", unique: true
  end

  create_table "order_lines", force: :cascade do |t|
    t.uuid "order_uid", null: false
    t.decimal "price", precision: 8, scale: 2
    t.uuid "product_id"
    t.string "product_name"
    t.integer "quantity"
  end

  create_table "orders", force: :cascade do |t|
    t.datetime "discount_updated_at"
    t.decimal "discounted_value", precision: 8, scale: 2
    t.decimal "percentage_discount", precision: 8, scale: 2
    t.uuid "store_id"
    t.decimal "time_promotion_discount_value", precision: 8, scale: 2
    t.decimal "total_value", precision: 8, scale: 2
    t.datetime "total_value_updated_at"
    t.uuid "uid", null: false
    t.index ["uid"], name: "index_orders_on_uid", unique: true
  end

  create_table "orders_customers", force: :cascade do |t|
    t.string "name"
    t.uuid "uid", null: false
  end

  create_table "orders_products", force: :cascade do |t|
    t.string "name"
    t.decimal "price", precision: 8, scale: 2
    t.uuid "uid", null: false
  end

  create_table "products", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.integer "available"
    t.text "current_prices_calendar"
    t.string "name"
    t.datetime "registered_at", precision: nil
    t.integer "stock_level"
    t.uuid "store_id"
    t.string "vat_rate_code"
  end

  create_table "public_offer_products", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.datetime "created_at", null: false
    t.decimal "lowest_recent_price", precision: 8, scale: 2
    t.string "name"
    t.decimal "price"
    t.uuid "store_id"
    t.datetime "updated_at", null: false
  end

  create_table "return_items", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.decimal "price", precision: 8, scale: 2, null: false
    t.uuid "product_uid", null: false
    t.integer "quantity", null: false
    t.uuid "return_uid", null: false
    t.datetime "updated_at", null: false
  end

  create_table "returns", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "order_number"
    t.uuid "order_uid", null: false
    t.string "status", null: false
    t.decimal "total_value", precision: 8, scale: 2, null: false
    t.uuid "uid", null: false
    t.datetime "updated_at", null: false
  end

  create_table "shipment_items", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.uuid "product_id", null: false
    t.string "product_name", null: false
    t.integer "quantity", null: false
    t.bigint "shipment_id", null: false
    t.datetime "updated_at", null: false
    t.index ["shipment_id"], name: "index_shipment_items_on_shipment_id"
  end

  create_table "shipments", force: :cascade do |t|
    t.string "address_line_1"
    t.string "address_line_2"
    t.string "address_line_3"
    t.string "address_line_4"
    t.string "order_number"
    t.uuid "order_uid", null: false
    t.uuid "store_id"
  end

  create_table "shipments_orders", force: :cascade do |t|
    t.boolean "submitted", default: false
    t.uuid "uid", null: false
  end

  create_table "time_promotions", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.boolean "active", default: false
    t.datetime "created_at", null: false
    t.integer "discount"
    t.datetime "end_time"
    t.string "label"
    t.datetime "start_time"
    t.uuid "store_id"
    t.datetime "updated_at", null: false
  end

  add_foreign_key "event_store_events_in_streams", "event_store_events", column: "event_id", primary_key: "event_id"
end
