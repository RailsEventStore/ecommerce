module Stores
  class ProductRegistration
    def initialize(event_store)
      @event_store = event_store
    end

    def call(cmd)
      @event_store.publish(product_registered_event(cmd), stream_name: stream_name(cmd))
    end

    private

    def product_registered_event(cmd)
      ProductRegistered.new(
        data: {
          store_id: cmd.store_id,
          product_id: cmd.product_id,
        }
      )
    end

    def stream_name(cmd)
      "Stores::Store$#{cmd.store_id}"
    end
  end
end
