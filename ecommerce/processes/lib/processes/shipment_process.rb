module Processes
  class ShipmentProcess
    include Infra::ProcessManager.with_state(
      state_repository_class: ShipmentProcessStateRepository
    )

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

    def submit_shipment
      command_bus.call(Shipping::SubmitShipment.new(order_id: id))
    end

    def authorize_shipment
      command_bus.call(Shipping::AuthorizeShipment.new(order_id: id))
    end

    def fetch_id(event)
      event.data.fetch(:order_id)
    end
  end
end
