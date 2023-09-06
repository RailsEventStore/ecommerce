# frozen_string_literal: true

class ValidateAddForeignKeyOnEventIdToEventStoreEventsInStreams < ActiveRecord::Migration[7.0]
  def change
    validate_foreign_key :event_store_events_in_streams, :event_store_events, column: :event_id, primary_key: :event_id
  end
end
