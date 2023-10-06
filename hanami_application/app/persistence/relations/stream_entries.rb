module Ecommerce
  module Persistence
    module Relations
      class StreamEntries < ROM::Relation[:sql]
        schema(:event_store_events_in_streams, infer: true, as: :stream_entries) do
        end
      end
    end
  end
end
