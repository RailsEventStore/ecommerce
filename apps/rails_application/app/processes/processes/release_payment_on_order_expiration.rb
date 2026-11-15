module Processes
  class ReleasePaymentOnOrderExpiration
    include RubyEventStore::ProcessManager.with_state { JoinDefinition::State }
    include JoinProcess

    Definition = JoinDefinition.new(
      [JoinDefinition::Rule.new(
        JoinDefinition.event(Payments::PaymentAuthorized) & JoinDefinition.event(Pricing::OfferExpired),
        :release_payment,
        JoinDefinition::Pattern.new([])
      )],
      { Payments::PaymentReleased => Payments::PaymentAuthorized },
      JoinDefinition.event(Payments::PaymentReleased)
    )

    subscribes_to(
      Payments::PaymentAuthorized,
      Payments::PaymentReleased,
      Fulfillment::OrderRegistered,
      Pricing::OfferExpired,
      Fulfillment::OrderConfirmed
    )

    private

    def release_payment
      command_bus.call(Payments::ReleasePayment.new(id))
    end
  end
end
