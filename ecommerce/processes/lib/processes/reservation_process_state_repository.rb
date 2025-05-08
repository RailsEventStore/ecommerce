module Processes
  class ReservationProcessStateRepository
    include Infra::ProcessRepository

    ProcessState = Data.define(:order, :order_lines) do
      def initialize(order: nil, order_lines: [])
        super(order:, order_lines: order_lines.freeze)
      end

      def reserved_product_ids = order_lines.keys
    end

    apply_event do |current_state, event|
      case event
      when Pricing::OfferAccepted
        current_state.with(
          order: :accepted,
          order_lines: event.data.fetch(:order_lines).map { |ol| [ol.fetch(:product_id), ol.fetch(:quantity)] }.to_h
        )
      when Fulfillment::OrderCancelled
        current_state.with(order: :cancelled)
      when Fulfillment::OrderConfirmed
        current_state.with(order: :confirmed)
      end
    end
  end
end