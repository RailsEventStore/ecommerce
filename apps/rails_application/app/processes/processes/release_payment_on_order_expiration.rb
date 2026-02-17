module Processes
  class ReleasePaymentOnOrderExpiration < Infra::ProcessManager

    subscribes_to(
      Payments::PaymentAuthorized,
      Payments::PaymentReleased,
      Fulfillment::OrderRegistered,
      Pricing::OfferExpired,
      Fulfillment::OrderConfirmed
    )

    private

    def initial_state
      ProcessState.new
    end

    def act
      release_payment if state.release?
    end

    def apply(event)
      case event
      when Payments::PaymentAuthorized
        state.with(payment_authorized: true)
      when Payments::PaymentReleased
        state.with(payment_authorized: false)
      when Pricing::OfferExpired
        state.with(order_expired: true)
      else
        state
      end
    end

    def release_payment
      command_bus.call(Payments::ReleasePayment.new(order_id: id))
    end

    def fetch_id(event)
      event.data.fetch(:order_id)
    end

    ProcessState = Data.define(:payment_authorized, :order_expired) do
      def initialize(payment_authorized: false, order_expired: false) = super

      def release?
        payment_authorized && order_expired
      end
    end
  end
end
