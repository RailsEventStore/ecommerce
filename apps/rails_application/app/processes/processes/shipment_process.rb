module Processes
  class ShipmentProcess
    include RubyEventStore::ProcessManager.with_state { JoinDefinition::State }
    include JoinProcess

    Definition = JoinDefinition.new(
      [
        JoinDefinition::Rule.new(
          JoinDefinition.event(Fulfillment::OrderRegistered) & JoinDefinition.event(Shipping::ShippingAddressAddedToShipment),
          :register_and_submit_shipment,
          JoinDefinition.event(Shipping::ShipmentSubmitted)
        ),
        JoinDefinition::Rule.new(
          JoinDefinition.event(Fulfillment::OrderConfirmed) & JoinDefinition.event(Shipping::ShipmentSubmitted),
          :authorize_shipment,
          JoinDefinition.event(Shipping::ShipmentAuthorized)
        )
      ],
      {},
      JoinDefinition.event(Shipping::ShipmentAuthorized)
    )

    subscribes_to(
      Shipping::ShippingAddressAddedToShipment,
      Shipping::ShipmentSubmitted,
      Shipping::ShipmentAuthorized,
      Fulfillment::OrderRegistered,
      Fulfillment::OrderConfirmed,
      Stores::OfferRegistered
    )

    private

    def store_id
      state.events.fetch(Stores::OfferRegistered, nil)&.data&.fetch(:store_id)
    end

    def register_shipment
      return unless store_id

      command_bus.call(
        Stores::RegisterShipment.new(
          store_id,
          id
        )
      )
    end

    def register_and_submit_shipment
      register_shipment
      command_bus.call(Shipping::SubmitShipment.new(id))
    end

    def authorize_shipment
      command_bus.call(Shipping::AuthorizeShipment.new(id))
    end
  end
end
