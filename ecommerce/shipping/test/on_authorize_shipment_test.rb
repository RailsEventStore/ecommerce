require_relative "test_helper"

module Shipping
  class OnAuthorizeShipmentTest < Test
    cover "Shipping::OnAuthorizeShipment*"

    def test_authorize_shipment
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

      assert_events(
        stream,
        ShipmentAuthorized.new(
          data: {
            order_id: order_id
          }
        )
      ) { act(AuthorizeShipment.new(order_id: order_id)) }
    end

    def test_shipment_cannot_be_authorized_when_not_submitted
      order_id = SecureRandom.uuid
      stream = "Shipping::Shipment$#{order_id}"

      assert_raises(Shipment::NotSubmitted) do
        act(AuthorizeShipment.new(order_id: order_id))
      end
    end

    def test_shipment_cannot_be_authorized_when_already_authorized
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
        SubmitShipment.new(order_id: order_id),
        AuthorizeShipment.new(order_id: order_id)
      )

      assert_raises(Shipment::AlreadyAuthorized) do
        act(AuthorizeShipment.new(order_id: order_id))
      end
    end
  end
end
