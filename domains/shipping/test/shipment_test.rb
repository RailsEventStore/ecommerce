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

    def test_add_address_publishes_event
      shipment = Shipment.new(order_id)
      address = fake_address

      shipment.add_address(address)

      assert_changes(
        shipment.unpublished_events,
        [
          ShippingAddressAddedToShipment.new(
            data: {
              order_id: order_id,
              postal_address: address
            }
          )
        ]
      )
    end

    def test_submit_shipment_publishes_event
      shipment = Shipment.new(order_id)
      address = fake_address

      shipment.add_address(address)
      shipment.submit

      assert_changes(
        shipment.unpublished_events,
        [
          ShippingAddressAddedToShipment.new(
            data: {
              order_id: order_id,
              postal_address: address
            }
          ),
          ShipmentSubmitted.new(
            data: {
              order_id: order_id
            }
          )
        ]
      )
    end
    def test_authorize_shipment_publishes_event
      shipment = Shipment.new(order_id)
      address = fake_address

      shipment.add_address(address)
      shipment.submit
      shipment.authorize

      assert_changes(
        shipment.unpublished_events,
        [
          ShippingAddressAddedToShipment.new(
            data: {
              order_id: order_id,
              postal_address: address
            }
          ),
          ShipmentSubmitted.new(
            data: {
              order_id: order_id
            }
          ),
          ShipmentAuthorized.new(
            data: {
              order_id: order_id
            }
          )
        ]
      )
    end

    def test_default_state_is_draft
      shipment = Shipment.new(order_id)

      assert_equal :draft, shipment.state
    end

    private

    def order_id
      @order_id ||= SecureRandom.uuid
    end
  end
end
