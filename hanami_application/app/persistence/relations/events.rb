module Ecommerce
  module Persistence
    module Relations
      class Events < ROM::Relation[:sql]
        schema(:event_store_events, infer: true, as: :events) do
        end
      end
    end
  end
end
