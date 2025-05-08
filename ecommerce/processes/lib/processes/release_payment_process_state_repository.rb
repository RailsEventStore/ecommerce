module Processes
  class ReleasePaymentProcessStateRepository
    include Infra::ProcessRepository

    ProcessState = Data.define(:order, :payment, :order_id) do
      def initialize(order: :draft, payment: :none, order_id: nil)
        super
      end

      def release?
        payment.eql?(:authorized) && order.eql?(:expired)
      end
    end

    apply_event do |current_state, event|
      case event
      when Payments::PaymentAuthorized
        current_state.with(payment: :authorized)
      when Payments::PaymentReleased
        current_state.with(payment: :released)
      when Fulfillment::OrderRegistered
        current_state.with(
          order: :placed,
          order_id: event.data.fetch(:order_id)
        )
      when Pricing::OfferExpired
        current_state.with(order: :expired)
      when Fulfillment::OrderConfirmed
        current_state.with(order: :confirmed)
      end
    end
  end
end