require_relative "test_helper"

module Shipping
  class OnAddShippingAddressToShipmentTest < Test
    cover "Shipping::OnAddShippingAddressToShipment*"

    def test_add_item_to_shipment_picking_list
      order_id = SecureRandom.uuid
      address = fake_address
      stream = "Shipping::Shipment$#{order_id}"

      assert_events(
        stream,
        ShippingAddressAddedToShipment.new(
          data: {
            order_id: order_id,
            postal_address: address
          }
        )
      ) do
        act(
          AddShippingAddressToShipment.new(
            order_id: order_id,
            postal_address: address
          )
        )
      end
    end
  end
end