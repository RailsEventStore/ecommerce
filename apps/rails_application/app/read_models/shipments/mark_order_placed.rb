module Shipments
  class MarkOrderPlaced
    def call(event)
      order_id = event.data.fetch(:order_id)
      order_number = event.data.fetch(:order_number)

      Order.find_or_initialize_by(uid: order_id).update!(submitted: true)
      Shipment.find_by(order_uid: order_id)&.update!(order_number: order_number)
    end
  end
end
