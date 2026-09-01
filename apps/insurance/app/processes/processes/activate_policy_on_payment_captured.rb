module Processes
  class ActivatePolicyOnPaymentCaptured
    def initialize(command_bus)
      @command_bus = command_bus
    end

    def call(event)
      command_bus.call(
        Policies::ActivatePolicy.new(policy_id: event.data.fetch(:order_id))
      )
    end

    private

    attr_reader :command_bus
  end
end
