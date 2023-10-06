# frozen_string_literal: true

ROM::SQL.migration do
  change do
    create_table? :event_store_events_in_streams do
      primary_key :id, type: :Bignum, null: false

      column :stream, String, null: false
      column :position, Integer

      column :event_id, :uuid, null: false

      column :created_at,
             DateTime,
             null: false,
             type: "TIMESTAMP",
             index: "index_event_store_events_in_streams_on_created_at"

      index %i[stream position], unique: true, name: "index_event_store_events_in_streams_on_stream_and_position"
      index %i[created_at], name: "index_event_store_events_in_streams_on_created_at"
      index %i[stream event_id], unique: true, name: "index_event_store_events_in_streams_on_stream_and_event_id"
    end

    create_table? :event_store_events do
      primary_key :id, type: :Bignum, null: false

      column :event_id, :uuid, null: false

      column :event_type, String, null: false

      column :metadata, :jsonb
      column :data, :jsonb, null: false

      column :created_at,
             DateTime,
             null: false,
             type: "TIMESTAMP",
             index: "index_event_store_events_on_created_at"
      column :valid_at,
             DateTime,
             null: false,
             type: "TIMESTAMP",
             index: "index_event_store_events_on_valid_at"

      index %i[event_id], unique: true, name: "index_event_store_events_on_event_id"
      index %i[created_at], name: "index_event_store_events_on_created_at"
      index %i[valid_at], name: "index_event_store_events_on_valid_at"
      index %i[event_type], name: "index_event_store_events_on_event_type"
    end
  end
end
