module Processes
  class ReleasePaymentProcess
    include Infra::ProcessManager

    subscribes_to(
      Payments::PaymentAuthorized,
      Payments::PaymentReleased,
      Fulfillment::OrderRegistered,
      Pricing::OfferExpired,
      Fulfillment::OrderConfirmed
    )

    private

    def act
      release_payment if state.release?
    end

    def apply(event)
      case event
      when Payments::PaymentAuthorized
        state.with(payment: :authorized)
      when Payments::PaymentReleased
        state.with(payment: :released)
      when Fulfillment::OrderRegistered
        state.with(
          order: :placed,
          order_id: event.data.fetch(:order_id)
        )
      when Pricing::OfferExpired
        state.with(order: :expired)
      when Fulfillment::OrderConfirmed
        state.with(order: :confirmed)
      end
    end

    def release_payment
      command_bus.call(Payments::ReleasePayment.new(order_id: state.order_id))
    end

    def fetch_id(event)
      event.data.fetch(:order_id)
    end

    ProcessState = Data.define(:order, :payment, :order_id) do
      def initialize(order: :draft, payment: :none, order_id: nil)
        super
      end

      def release?
        payment.eql?(:authorized) && order.eql?(:expired)
      end
    end

    process_state(ProcessState)
  end
end
