module Processes
  class ShipmentProcess < Infra::ProcessManager

    subscribes_to(
      Shipping::ShippingAddressAddedToShipment,
      Fulfillment::OrderRegistered,
      Fulfillment::OrderConfirmed,
      Stores::OfferRegistered
    )

    private

    def initial_state
      ProcessState.new
    end

    def act
      case state
      in { shipment: :address_set, order: :placed }
        register_shipment
        submit_shipment
      in { shipment: :address_set, order: :confirmed }
        register_shipment
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
      when Stores::OfferRegistered
        state.with(store_id: event.data.fetch(:store_id))
      end
    end

    def register_shipment
      return unless state.store_id

      command_bus.call(
        Stores::RegisterShipment.new(
          shipment_id: id,
          store_id: state.store_id
        )
      )
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

    ProcessState = Data.define(:order, :shipment, :store_id) do
      def initialize(order: nil, shipment: nil, store_id: nil) = super
    end
  end
end
