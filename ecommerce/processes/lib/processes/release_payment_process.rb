module Processes
  class ReleasePaymentProcess
    include Infra::ProcessManager.with_state { StateProjector }
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

    def release_payment
      command_bus.call(Payments::ReleasePayment.new(order_id: state.order_id))
    end

    def fetch_id(event)
      event.data.fetch(:order_id)
    end

    class StateProjector
      ProcessState = Data.define(:order, :payment, :order_id) do
        def initialize(order: :draft, payment: :none, order_id: nil)
          super
        end

        def release?
          payment.eql?(:authorized) && order.eql?(:expired)
        end
      end

      def self.initial_state_instance
        ProcessState.new
      end

      def self.apply(state_instance, event)
        case event
        when Payments::PaymentAuthorized
          state_instance.with(payment: :authorized)
        when Payments::PaymentReleased
          state_instance.with(payment: :released)
        when Fulfillment::OrderRegistered
          state_instance.with(
            order: :placed,
            order_id: event.data.fetch(:order_id)
          )
        when Pricing::OfferExpired
          state_instance.with(order: :expired)
        when Fulfillment::OrderConfirmed
          state_instance.with(order: :confirmed)
        end
      end
    end
  end
end
