module Processes
  module StateProjectors
    class DetermineVatRatesOnOrderPlaced
      ProcessState = Data.define(:offer_accepted, :order_placed, :order_id, :order_lines) do
        def initialize(offer_accepted: false, order_placed: false, order_id: nil, order_lines: [])
          super
        end

        def placed? = offer_accepted && order_placed
      end

      def self.initial_state_instance
        ProcessState.new
      end

      def self.apply(state_instance, event)
        case event
        when Pricing::OfferAccepted
          state_instance.with(
            offer_accepted: true,
            order_lines: event.data.fetch(:order_lines),
            order_id: event.data.fetch(:order_id)
          )
        when Fulfillment::OrderRegistered
          state_instance.with(order_placed: true)
        end
      end
    end
  end
end
