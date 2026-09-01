module Processes
  class Configuration
    def call(event_store, command_bus)
      event_store.subscribe(
        IssuePolicyOnOfferAccepted.new(command_bus),
        to: [Underwriting::OfferAccepted]
      )
      event_store.subscribe(
        CollectPremiumOnPolicyIssued.new(command_bus),
        to: [Policies::PolicyIssued]
      )
      event_store.subscribe(
        ActivatePolicyOnPaymentCaptured.new(command_bus),
        to: [Payments::PaymentCaptured]
      )
      event_store.subscribe(
        CompensationProcess.new(event_store, command_bus),
        to: CompensationProcess.subscribed_events
      )
    end
  end
end
