require_relative "test_helper"

module Shipping
  class OnAddShippingAddressToShipmentTest < Test
    cover "Shipping::OnAddShippingAddressToShipment*"

    def test_add_item_to_shipment_picking_list
      order_id = SecureRandom.uuid
      product_id = SecureRandom.uuid
      stream = "Shipping::Shipment$#{order_id}"

      assert_events(
        stream,
        ShippingAddressAddedToShipment.new(
          data: {
            order_id: order_id,
            line_1: "Mme Anna Kowalska",
            line_2: "Ul. Bosmanska 1",
            line_3: "81-116 GDYNIA",
            line_4: "POLAND"
          }
        )
      ) do
        act(
          AddShippingAddressToShipment.new(
            order_id: order_id,
            line_1: "Mme Anna Kowalska",
            line_2: "Ul. Bosmanska 1",
            line_3: "81-116 GDYNIA",
            line_4: "POLAND"
          )
        )
      end
    end
  end
end