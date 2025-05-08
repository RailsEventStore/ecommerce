module Processes
  class DetermineVatRatesOnOrderPlacedStateRepository
    include Infra::ProcessRepository

    ProcessState = Data.define(:offer_accepted, :order_placed, :order_id, :order_lines) do
      def initialize(offer_accepted: false, order_placed: false, order_id: nil, order_lines: [])
        super
      end

      def placed? = offer_accepted && order_placed
    end

    apply_event do |current_state, event|
      case event
      when Pricing::OfferAccepted
        current_state.with(
          offer_accepted: true,
          order_lines: event.data.fetch(:order_lines),
          order_id: event.data.fetch(:order_id)
        )
      when Fulfillment::OrderRegistered
        current_state.with(order_placed: true)
      end
    end

    def placed?
      new_state.offer_accepted && new_state.order_placed
    end
  end
end