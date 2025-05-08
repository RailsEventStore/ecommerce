module Processes
  class ShipmentProcessStateRepository
    include Infra::ProcessRepository

    ProcessState = Data.define(:order, :shipment) do
      def initialize(order: nil, shipment: nil) = super
    end

    apply_event do |current_state, event|
    case event
      when Shipping::ShippingAddressAddedToShipment
        current_state.with(shipment: :address_set)
      when Fulfillment::OrderRegistered
        current_state.with(order: :placed)
      when Fulfillment::OrderConfirmed
        current_state.with(order: :confirmed)
      else
        current_state
      end
    end
  end
end