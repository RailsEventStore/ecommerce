module Stores
  class CustomerRegistration
    def initialize(event_store)
      @event_store = event_store
    end

    def call(cmd)
      @event_store.publish(customer_registered_event(cmd), stream_name: stream_name(cmd))
    end

    private

    def customer_registered_event(cmd)
      CustomerRegistered.new(
        data: {
          store_id: cmd.store_id,
          customer_id: cmd.customer_id,
        }
      )
    end

    def stream_name(cmd)
      "Stores::Store$#{cmd.store_id}"
    end
  end
end
