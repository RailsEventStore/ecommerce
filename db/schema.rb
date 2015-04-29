# encoding: UTF-8
# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 20150429222352) do

  create_table "event_store_events", force: :cascade do |t|
    t.string   "stream",     null: false
    t.string   "event_type", null: false
    t.string   "event_id",   null: false
    t.text     "metadata"
    t.text     "data",       null: false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "event_store_events", ["event_id"], name: "index_event_store_events_on_event_id"
  add_index "event_store_events", ["stream"], name: "index_event_store_events_on_stream"

end
