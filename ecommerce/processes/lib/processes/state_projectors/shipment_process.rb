module Processes
  module StateProjectors
    class ShipmentProcess
      ProcessState = Data.define(:order, :shipment) do
        def initialize(order: nil, shipment: nil) = super
      end

      def self.initial_state_instance
        ProcessState.new
      end

      def self.apply(state_instance, event)
        case event
        when Shipping::ShippingAddressAddedToShipment
          state_instance.with(shipment: :address_set)
        when Fulfillment::OrderRegistered
          state_instance.with(order: :placed)
        when Fulfillment::OrderConfirmed
          state_instance.with(order: :confirmed)
        end
      end
    end
  end
end
