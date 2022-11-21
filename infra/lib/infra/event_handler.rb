module Infra
  class EventHandler < ActiveJob::Base
    queue_as :default

    def perform(payload)
      event = event_store.read.event(payload.symbolize_keys.fetch(:event_id))
      event_store.with_metadata(correlation_id: event.metadata[:correlation_id], causation_id: event.event_id) do
        call(event)
      end
    end

    private

    def event_store
      Rails.configuration.event_store
    end
  end
end