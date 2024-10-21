module Shipments
  class AddItemToShipment
    def call(event)
      product_id = event.data.fetch(:product_id)
      order_id = event.data.fetch(:order_id)
      product = Orders::Product.find_by_uid!(product_id)

      item = find_or_create_item(order_id, product)
      item.quantity += 1
      item.save!
    end

    private

    def find_or_create_item(order_id, product)
      Shipment
        .find_or_create_by!(order_uid: order_id)
        .shipment_items
        .create_with(product_name: product.name, quantity: 0)
        .find_or_create_by!(product_id: product.uid)
    end
  end
end
