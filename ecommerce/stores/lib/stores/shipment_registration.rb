module Stores
  class ShipmentRegistration
    def initialize(event_store)
      @event_store = event_store
    end

    def call(cmd)
      @event_store.publish(shipment_registered_event(cmd), stream_name: stream_name(cmd))
    end

    private

    def shipment_registered_event(cmd)
      ShipmentRegistered.new(
        data: {
          store_id: cmd.store_id,
          shipment_id: cmd.shipment_id,
        }
      )
    end

    def stream_name(cmd)
      "Stores::Store$#{cmd.store_id}"
    end
  end
end
