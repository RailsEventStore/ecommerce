module Stores
  class OfferRegistration
    def initialize(event_store)
      @event_store = event_store
    end

    def call(cmd)
      @event_store.publish(offer_registered_event(cmd), stream_name: stream_name(cmd))
    end

    private

    def offer_registered_event(cmd)
      OfferRegistered.new(
        data: {
          store_id: cmd.store_id,
          order_id: cmd.order_id,
        }
      )
    end

    def stream_name(cmd)
      "Stores::Store$#{cmd.store_id}"
    end
  end
end
