# auto_register: false
# frozen_string_literal: true

module HanamiApplication
  module Processes
    class OrderFulfillment
      def initialize(command_bus)
        @command_bus = command_bus
      end

      def subscribe(event_store)
        event_store.subscribe(method(:register_order), to: [Pricing::OfferAccepted])
        event_store.subscribe(method(:confirm_order), to: [Fulfillment::OrderRegistered])
        self
      end

      private

      def register_order(event)
        @command_bus.call(Fulfillment::RegisterOrder.new(order_id: event.data.fetch(:order_id)))
      end

      def confirm_order(event)
        @command_bus.call(Fulfillment::ConfirmOrder.new(order_id: event.data.fetch(:order_id)))
      end
    end
  end
end
