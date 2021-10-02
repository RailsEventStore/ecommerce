require_relative "test_helper"

module Shipping
  class ShipmentTest < Test
    cover "Shipping::Shipment*"

    def test_add_item_publishes_event
      product_id = SecureRandom.uuid
      shipment = Shipment.new(order_id)

      shipment.add_item(product_id)

      assert_changes(
        shipment.unpublished_events,
        [
          ItemAddedToShipmentPickingList.new(
            data: {
              order_id: order_id,
              product_id: product_id
            }
          )
        ]
      )
    end

    def test_remove_item_publishes_event
      product_id = SecureRandom.uuid
      shipment = Shipment.new(order_id)

      shipment.add_item(product_id)
      shipment.remove_item(product_id)

      assert_changes(
        shipment.unpublished_events,
        [
          ItemAddedToShipmentPickingList.new(
            data: {
              order_id: order_id,
              product_id: product_id
            }
          ),
          ItemRemovedFromShipmentPickingList.new(
            data: {
              order_id: order_id,
              product_id: product_id
            }
          )
        ]
      )
    end

    def test_should_not_allow_removing_non_existing_items
      product_id = SecureRandom.uuid
      shipment = Shipment.new(order_id)

      assert_raises(Shipment::ItemNotFound) { shipment.remove_item(product_id)  }
    end

    private

    def order_id
      @order_id ||= SecureRandom.uuid
    end
  end
end
