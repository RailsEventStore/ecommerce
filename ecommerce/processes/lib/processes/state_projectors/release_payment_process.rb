module Processes
  module StateProjectors
    class ReleasePaymentProcess
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
