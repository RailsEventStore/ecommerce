require_relative "test_helper"

module Shipping
  class OnSubmitShipmentTest < Test
    cover "Shipping::OnSubmitShipment*"

    def test_submit_shipment
      order_id = SecureRandom.uuid
      address = fake_address
      stream = "Shipping::Shipment$#{order_id}"

      run_command(
        AddShippingAddressToShipment.new(
          order_id: order_id,
          postal_address: address
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

      assert_raises(Shipment::ShippingAddressMissing) do
        act(SubmitShipment.new(order_id: order_id))
      end
    end

    def test_shipment_cannot_be_submitted_when_already_submitted
      order_id = SecureRandom.uuid
      address = fake_address

      arrange(
        AddShippingAddressToShipment.new(
          order_id: order_id,
          postal_address: address
        ),
        SubmitShipment.new(order_id: order_id)
      )

      assert_raises(Shipment::AlreadySubmitted) do
        act(SubmitShipment.new(order_id: order_id))
      end
    end
  end
end
