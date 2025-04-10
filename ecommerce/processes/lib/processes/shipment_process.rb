module Processes
  class ShipmentProcess

    private

    def act
      submit_shipment(state) if state.submit?
      authorize_shipment(state) if state.authorize?
    end

    def process_id(event)
      event.data.fetch(:order_id)
    end

    def submit_shipment(state)
      command_bus.call(Shipping::SubmitShipment.new(order_id: state.order_id))
    end

    def authorize_shipment(state)
      command_bus.call(Shipping::AuthorizeShipment.new(order_id: state.order_id))
    end

    class ProcessState
      def initialize
        @order = :draft
        @shipment = :draft
      end

      attr_reader :order_id

      def call(event)
        case event
        when Shipping::ShippingAddressAddedToShipment
          @shipment = :address_set
        when Shipping::ShipmentSubmitted
          @shipment = :submitted
        when Fulfillment::OrderRegistered
          @order = :placed
          @order_id = event.data.fetch(:order_id)
        when Fulfillment::OrderConfirmed
          @order = :confirmed
        end
      end

      def submit?
        return false if @shipment == :submitted

        @shipment == :address_set && @order != :draft
      end

      def authorize?
        @shipment == :address_set && @order == :confirmed
      end
    end

    include Infra::ProcessManager.with_state(ProcessState)

    subscribes_to(
      Shipping::ShippingAddressAddedToShipment,
      Shipping::ShipmentSubmitted,
      Fulfillment::OrderRegistered,
      Fulfillment::OrderConfirmed
    )
  end
end
