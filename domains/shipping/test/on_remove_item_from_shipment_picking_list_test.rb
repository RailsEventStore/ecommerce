require_relative "test_helper"

module Shipping
  class OnRemoveItemFromShipmentPickingListTest < Test
    cover "Shipping::OnRemoveItemFromShipmentPickingList*"

    def test_remove_item_from_shipment_picking_list
      order_id = SecureRandom.uuid
      product_id = SecureRandom.uuid
      stream = "Shipping::Shipment$#{order_id}"

      run_command(AddItemToShipmentPickingList.new(
        order_id: order_id,
        product_id: product_id
      ))

      assert_events(
        stream,
        ItemRemovedFromShipmentPickingList.new(
          data: {
            order_id: order_id,
            product_id: product_id
          }
        )
      ) { act(RemoveItemFromShipmentPickingList.new(order_id: order_id, product_id: product_id)) }
    end

    def test_should_not_allow_removing_non_existing_items
      order_id = SecureRandom.uuid
      product_id = SecureRandom.uuid
      stream = "Shipping::Shipment$#{order_id}"

      assert_raises(Shipment::ItemNotFound) do
        act(RemoveItemFromShipmentPickingList.new(
          order_id: order_id,
          product_id: product_id
        ))
      end
    end
  end
end
