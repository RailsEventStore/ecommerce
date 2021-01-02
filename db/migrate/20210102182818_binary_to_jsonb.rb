class BinaryToJsonb < ActiveRecord::Migration[5.2]
  def change
    execute "ALTER TABLE event_store_events ALTER COLUMN data     TYPE jsonb USING convert_from(data, 'UTF-8')::jsonb"
    execute "ALTER TABLE event_store_events ALTER COLUMN metadata TYPE jsonb USING convert_from(metadata, 'UTF-8')::jsonb"
  end
end
