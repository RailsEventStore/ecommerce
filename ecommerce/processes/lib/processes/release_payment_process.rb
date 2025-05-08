module Processes
  class ReleasePaymentProcess
    include Infra::ProcessManager.with_state(state_repository_class: ReleasePaymentProcessStateRepository)


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
  end
end
