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

ActiveRecord::Schema[8.0].define(version: 2026_02_18_130003) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "activities", force: :cascade do |t|
    t.string "entity_type", null: false
    t.uuid "entity_uid", null: false
    t.string "action", null: false
    t.datetime "occurred_at", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["occurred_at"], name: "index_activities_on_occurred_at"
  end

  create_table "companies", force: :cascade do |t|
    t.uuid "uid", null: false
    t.string "name", null: false
    t.string "linkedin_url"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["uid"], name: "index_companies_on_uid", unique: true
  end

  create_table "contacts", force: :cascade do |t|
    t.uuid "uid", null: false
    t.string "name", null: false
    t.string "email"
    t.string "phone"
    t.string "linkedin_url"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.uuid "company_uid"
    t.index ["uid"], name: "index_contacts_on_uid", unique: true
  end

  create_table "deal_companies", force: :cascade do |t|
    t.uuid "deal_uid", null: false
    t.uuid "company_uid", null: false
    t.index ["deal_uid", "company_uid"], name: "index_deal_companies_on_deal_uid_and_company_uid", unique: true
  end

  create_table "deal_contacts", force: :cascade do |t|
    t.uuid "deal_uid", null: false
    t.uuid "contact_uid", null: false
    t.index ["deal_uid", "contact_uid"], name: "index_deal_contacts_on_deal_uid_and_contact_uid", unique: true
  end

  create_table "deals", force: :cascade do |t|
    t.uuid "uid", null: false
    t.uuid "pipeline_uid", null: false
    t.string "name", null: false
    t.integer "value"
    t.string "expected_close_date"
    t.string "stage"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["uid"], name: "index_deals_on_uid", unique: true
  end

  create_table "entity_names", force: :cascade do |t|
    t.string "entity_type", null: false
    t.uuid "entity_uid", null: false
    t.string "name", null: false
    t.index ["entity_type", "entity_uid"], name: "index_entity_names_on_entity_type_and_entity_uid", unique: true
  end

  create_table "event_store_events", force: :cascade do |t|
    t.uuid "event_id", null: false
    t.string "event_type", null: false
    t.binary "metadata"
    t.binary "data", null: false
    t.datetime "created_at", null: false
    t.datetime "valid_at"
    t.index ["created_at"], name: "index_event_store_events_on_created_at"
    t.index ["event_id"], name: "index_event_store_events_on_event_id", unique: true
    t.index ["event_type"], name: "index_event_store_events_on_event_type"
    t.index ["valid_at"], name: "index_event_store_events_on_valid_at"
  end

  create_table "event_store_events_in_streams", force: :cascade do |t|
    t.string "stream", null: false
    t.integer "position"
    t.uuid "event_id", null: false
    t.datetime "created_at", null: false
    t.index ["created_at"], name: "index_event_store_events_in_streams_on_created_at"
    t.index ["event_id"], name: "index_event_store_events_in_streams_on_event_id"
    t.index ["stream", "event_id"], name: "index_event_store_events_in_streams_on_stream_and_event_id", unique: true
    t.index ["stream", "position"], name: "index_event_store_events_in_streams_on_stream_and_position", unique: true
  end

  create_table "pipeline_stages", force: :cascade do |t|
    t.uuid "pipeline_uid", null: false
    t.string "stage_name", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["pipeline_uid", "stage_name"], name: "index_pipeline_stages_on_pipeline_uid_and_stage_name", unique: true
  end

  create_table "pipelines", force: :cascade do |t|
    t.uuid "uid", null: false
    t.string "name", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["uid"], name: "index_pipelines_on_uid", unique: true
  end

  add_foreign_key "event_store_events_in_streams", "event_store_events", column: "event_id", primary_key: "event_id"
end
