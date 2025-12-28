class LimitForEventId < ActiveRecord::Migration[4.2]
  def change
    postgres = ActiveRecord::Base.connection.adapter_name == "PostgreSQL"
    change_column(:event_store_events_in_streams, :event_id, :string, limit: 36) unless postgres
  end
end
