require_relative "test_helper"

module Shipping
  class OnSubmitShipmentTest < Test
    cover "Shipping::OnSubmitShipment*"

    def test_submit_shipment
      order_id = SecureRandom.uuid
      stream = "Shipping::Shipment$#{order_id}"

      run_command(
        AddShippingAddressToShipment.new(
          order_id: order_id,
          line_1: "Mme Anna Kowalska",
          line_2: "Ul. Bosmanska 1",
          line_3: "81-116 GDYNIA",
          line_4: "POLAND"
        )
      )

      assert_events(
        stream,
        ShipmentSubmitted.new(
          data: {
            order_id: order_id
          }
        )
      ) { act(SubmitShipment.new(order_id: order_id)) }
    end

    def test_shipment_cannot_be_submitted_when_shipping_address_is_missing
      order_id = SecureRandom.uuid
      stream = "Shipping::Shipment$#{order_id}"

      assert_raises(Shipment::ShippingAddressMissing) do
        act(SubmitShipment.new(order_id: order_id))
      end
    end

    def test_shipment_cannot_be_submitted_when_already_submitted
      order_id = SecureRandom.uuid
      stream = "Shipping::Shipment$#{order_id}"

      arrange(
        AddShippingAddressToShipment.new(
          order_id: order_id,
          line_1: "Mme Anna Kowalska",
          line_2: "Ul. Bosmanska 1",
          line_3: "81-116 GDYNIA",
          line_4: "POLAND"
        ),
        SubmitShipment.new(order_id: order_id)
      )

      assert_raises(Shipment::AlreadySubmitted) do
        act(SubmitShipment.new(order_id: order_id))
      end
    end
  end
end
