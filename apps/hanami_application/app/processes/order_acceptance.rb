module HanamiApplication
  module Processes
    class OrderAcceptance
      IsEmpty = Class.new(StandardError)

      def initialize(command_bus, orders)
        @command_bus = command_bus
        @orders = orders
      end

      def subscribe(event_store)
        event_store.subscribe(self, to: [Pricing::OrderAcceptanceRequested])
      end

      def call(event)
        order_id = event.data.fetch(:order_id)
        raise IsEmpty if @orders.item_count(order_id).zero?

        @command_bus.call(Pricing::AcceptOffer.new(order_id))
      end
    end
  end
end
