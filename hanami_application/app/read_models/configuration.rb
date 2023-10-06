module Ecommerce
  module ReadModels
    class Configuration
      include Deps[
        event_store: "event_store.client",
      ]

      def call
        event_store.subscribe(SubmitOrder, to: [Ordering::OrderSubmitted])
      end
    end
  end
end
