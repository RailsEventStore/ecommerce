class AddStreamIdIndexToEventStoreEventsInStreams < ActiveRecord::Migration[8.0]
  disable_ddl_transaction!

  def change
    add_index :event_store_events_in_streams, [:stream, :id],
              name: "index_event_store_events_in_streams_on_stream_and_id",
              algorithm: :concurrently,
              if_not_exists: true
  end
end
