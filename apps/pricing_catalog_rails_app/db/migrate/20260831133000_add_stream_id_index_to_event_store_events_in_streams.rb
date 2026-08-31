class AddStreamIdIndexToEventStoreEventsInStreams < ActiveRecord::Migration[7.1]
  def change
    add_index :event_store_events_in_streams, [:stream, :id],
              name: "index_event_store_events_in_streams_on_stream_and_id",
              if_not_exists: true
  end
end
