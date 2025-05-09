module Processes
  module StateProjectors
    class ReservationProcess
      ProcessState = Data.define(:order, :order_lines) do
        def initialize(order: nil, order_lines: [])
          super(order:, order_lines: order_lines.freeze)
        end

        def reserved_product_ids
          order_lines.keys
        end
      end

      def self.initial_state_instance
        ProcessState.new
      end

      def self.apply(state_instance, event)
        case event
        when Pricing::OfferAccepted
          state_instance.with(
            order: :accepted,
            order_lines: event.data.fetch(:order_lines).map { |ol| [ol.fetch(:product_id), ol.fetch(:quantity)] }.to_h
          )
        when Fulfillment::OrderCancelled
          state_instance.with(order: :cancelled)
        when Fulfillment::OrderConfirmed
          state_instance.with(order: :confirmed)
        else
          state_instance
        end
      end
    end
  end
end
