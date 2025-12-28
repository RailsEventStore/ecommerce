require "test_helper"

module Processes
  class ShipmentProcessTest < ProcessTest
    cover "Processes::ShipmentProcess*"

    def test_submit_and_authorize_shipment_when_order_confirmed_and_address_set
      given([order_placed, order_confirmed, shipping_address_added], process:)
      assert_all_commands(
        Shipping::SubmitShipment.new(order_id:),
        Shipping::AuthorizeShipment.new(order_id:),
      )
    end

    def test_submit_shipment_when_order_placed_then_address_set
      given([order_placed, shipping_address_added], process:)
      assert_all_commands(
        Shipping::SubmitShipment.new(order_id:),
      )
    end

    def test_submit_shipment_when_address_set_then_order_placed
      given([shipping_address_added, order_placed], process:)
      assert_all_commands(
        Shipping::SubmitShipment.new(order_id:),
      )
    end

    def test_dont_submit_shipment_for_draft_order
      given([shipping_address_added], process:)
      assert_no_command
    end

    def test_need_address_to_submit_shipment
      given([order_placed], process:)
      assert_no_command
    end

    def test_need_address_to_authorize_shipment
      given([order_placed, order_confirmed], process:)
      assert_no_command
    end

    def test_submit_and_authorize_shipment_with_store_registration
      given([offer_registered, order_placed, order_confirmed, shipping_address_added], process:)
      assert_all_commands(
        Stores::RegisterShipment.new(shipment_id: order_id, store_id: store_id),
        Shipping::SubmitShipment.new(order_id:),
        Shipping::AuthorizeShipment.new(order_id:),
      )
    end

    def test_submit_shipment_with_store_registration_when_order_placed
      given([offer_registered, order_placed, shipping_address_added], process:)
      assert_all_commands(
        Stores::RegisterShipment.new(shipment_id: order_id, store_id: store_id),
        Shipping::SubmitShipment.new(order_id:),
      )
    end

    private

    def process
      ShipmentProcess.new(event_store, command_bus)
    end

    def shipping_address_added
      Shipping::ShippingAddressAddedToShipment.new(
        data: {
          order_id: order_id,
          postal_address: { line_1: "123 Some Street", line_2: "", line_3: "", line_4: "" },
        }
      )
    end

    def offer_registered
      Stores::OfferRegistered.new(
        data: {
          order_id: order_id,
          store_id: store_id
        }
      )
    end

    def store_id
      @store_id ||= SecureRandom.uuid
    end
  end
end
