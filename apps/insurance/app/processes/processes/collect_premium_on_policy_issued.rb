module Processes
  class CollectPremiumOnPolicyIssued
    def initialize(command_bus)
      @command_bus = command_bus
    end

    def call(event)
      command_bus.call(
        Payments::SetPaymentAmount.new(
          order_id: event.data.fetch(:policy_id),
          amount: event.data.fetch(:premium)
        )
      )
    end

    private

    attr_reader :command_bus
  end
end
