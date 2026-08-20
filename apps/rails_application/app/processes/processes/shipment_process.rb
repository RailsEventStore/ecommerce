module Processes
  class ShipmentProcess
    include RubyEventStore::ProcessManager.with_state { ProcessState }

    subscribes_to(
      Shipping::ShippingAddressAddedToShipment,
      Shipping::ShipmentSubmitted,
      Shipping::ShipmentAuthorized,
      Fulfillment::OrderRegistered,
      Fulfillment::OrderConfirmed,
      Stores::OfferRegistered
    )

    private

    def act
      if state.ready_to_submit?
        register_and_submit_shipment
      elsif state.ready_to_authorize?
        authorize_shipment
      end
    end

    def apply(event)
      case event
      when Shipping::ShippingAddressAddedToShipment
        state.with(shipping_address_set: true)
      when Shipping::ShipmentSubmitted
        state.with(shipment_submitted: true)
      when Shipping::ShipmentAuthorized
        state.with(shipment_authorized: true)
      when Fulfillment::OrderRegistered
        state.with(order_placed: true)
      when Fulfillment::OrderConfirmed
        state.with(order_confirmed: true)
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

    def register_and_submit_shipment
      register_shipment
      command_bus.call(Shipping::SubmitShipment.new(order_id: id))
    end

    def authorize_shipment
      command_bus.call(Shipping::AuthorizeShipment.new(order_id: id))
    end

    def fetch_id(event)
      event.data.fetch(:order_id)
    end

    ProcessState = Data.define(
      :order_placed,
      :order_confirmed,
      :shipping_address_set,
      :shipment_submitted,
      :shipment_authorized,
      :store_id
    ) do
      def initialize(
        order_placed: false,
        order_confirmed: false,
        shipping_address_set: false,
        shipment_submitted: false,
        shipment_authorized: false,
        store_id: nil
      )
        super
      end

      def ready_to_submit?
        order_placed && shipping_address_set && !shipment_submitted
      end

      def ready_to_authorize?
        order_confirmed && shipment_submitted && !shipment_authorized
      end
    end
  end
end
