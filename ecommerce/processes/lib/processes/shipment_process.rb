module Processes
  class ShipmentProcess
    def initialize(event_store, command_bus)
      @event_store = event_store
      @command_bus = command_bus
      @event_store.subscribe(
        self,
        to: [
          Shipping::ShippingAddressAddedToShipment,
          Shipping::ShipmentSubmitted,
          Ordering::OrderSubmitted,
          Ordering::OrderConfirmed
        ]
      )
    end

    def call(event)
      state = build_state(event)
      submit_shipment(state) if state.submit?
      authorize_shipment(state) if state.authorize?
    end

    private

    def submit_shipment(state)
      command_bus.call(Shipping::SubmitShipment.new(order_id: state.order_id))
    end

    def authorize_shipment(state)
      command_bus.call(Shipping::AuthorizeShipment.new(order_id: state.order_id))
    end

    attr_reader :command_bus, :event_store

    def build_state(event)
      stream_name = "ShipmentProcess$#{event.data.fetch(:order_id)}"
      past_events = event_store.read.stream(stream_name).to_a
      last_stored = past_events.size - 1
      event_store.link(event.event_id, stream_name: stream_name, expected_version: last_stored)
      ProcessState.new.tap do |state|
        past_events.each { |ev| state.call(ev) }
        state.call(event)
      end
    rescue RubyEventStore::WrongExpectedEventVersion
      retry
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
        when Ordering::OrderSubmitted
          @order = :submitted
          @order_id = event.data.fetch(:order_id)
        when Ordering::OrderConfirmed
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
  end
end