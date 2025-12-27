require_relative 'test_helper'
module Stores
  class ShipmentRegistrationTest < Test
    cover "Stores*"

    def test_shipment_should_get_registered
      store_id = SecureRandom.uuid
      shipment_id = SecureRandom.uuid
      assert register_shipment(store_id, shipment_id)
    end

    def test_should_publish_event
      store_id = SecureRandom.uuid
      shipment_id = SecureRandom.uuid
      shipment_registered = Stores::ShipmentRegistered.new(data: { store_id: store_id, shipment_id: shipment_id })
      assert_events("Stores::Store$#{store_id}", shipment_registered) do
        register_shipment(store_id, shipment_id)
      end
    end

    private

    def register_shipment(store_id, shipment_id)
      run_command(RegisterShipment.new(store_id: store_id, shipment_id: shipment_id))
    end
  end
end
