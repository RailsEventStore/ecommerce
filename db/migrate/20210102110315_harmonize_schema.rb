class HarmonizeSchema < ActiveRecord::Migration[5.2]
  def change
    execute "ALTER TABLE event_store_events ALTER COLUMN id TYPE uuid USING id::uuid;"
    execute "ALTER TABLE event_store_events_in_streams ALTER COLUMN event_id TYPE uuid USING event_id::uuid;"
  end
end
