module Shipments
  class AssignStoreToShipment
    def call(event)
      Shipment.find_or_initialize_by(order_uid: event.data.fetch(:shipment_id)).update!(store_id: event.data.fetch(:store_id))
    end
  end
end
