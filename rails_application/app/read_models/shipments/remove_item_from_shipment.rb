module Shipments
  class RemoveItemFromShipment
    def call(event)
      product_id = event.data.fetch(:product_id)
      order_id = event.data.fetch(:order_id)

      item = find(order_id, product_id)
      item.quantity -= 1
      item.quantity > 0 ? item.save! : item.destroy!
    end

    private

    def find(order_uid, product_id)
      Shipment
        .find_by!(order_uid: order_uid)
        .shipment_items
        .find_by!(product_id: product_id)
    end
  end
end
