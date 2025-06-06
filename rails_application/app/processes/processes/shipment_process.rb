module Processes
  class ShipmentProcess
    include Infra::ProcessManager.with_state { ProcessState }

    subscribes_to(
      Shipping::ShippingAddressAddedToShipment,
      Fulfillment::OrderRegistered,
      Fulfillment::OrderConfirmed
    )

    private

    def act
      case state
      in { shipment: :address_set, order: :placed }
        submit_shipment
      in { shipment: :address_set, order: :confirmed }
        submit_shipment
        authorize_shipment
      else
      end
    end

    def apply(event)
      case event
      when Shipping::ShippingAddressAddedToShipment
        state.with(shipment: :address_set)
      when Fulfillment::OrderRegistered
        state.with(order: :placed)
      when Fulfillment::OrderConfirmed
        state.with(order: :confirmed)
      end
    end

    def submit_shipment
      command_bus.call(Shipping::SubmitShipment.new(order_id: id))
    end

    def authorize_shipment
      command_bus.call(Shipping::AuthorizeShipment.new(order_id: id))
    end

    def fetch_id(event)
      event.data.fetch(:order_id)
    end

    ProcessState = Data.define(:order, :shipment) do
      def initialize(order: nil, shipment: nil) = super
    end
  end
end
