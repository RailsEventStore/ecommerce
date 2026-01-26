require_relative "test_helper"

module Shipping
  class OnAddItemToShipmentPickingListTest < Test
    cover "Shipping::OnAddItemToShipmentPickingList*"

    def test_add_item_to_shipment_picking_list
      order_id = SecureRandom.uuid
      product_id = SecureRandom.uuid
      stream = "Shipping::Shipment$#{order_id}"

      assert_events(
        stream,
        ItemAddedToShipmentPickingList.new(
          data: {
            order_id: order_id,
            product_id: product_id
          }
        )
      ) { act(AddItemToShipmentPickingList.new(order_id: order_id, product_id: product_id)) }
    end
  end
end
