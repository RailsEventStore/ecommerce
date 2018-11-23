class IndexByEventType < ActiveRecord::Migration[4.2]
  def change
    add_index :event_store_events, :event_type unless index_exists? :event_store_events, :event_type
  end
end
