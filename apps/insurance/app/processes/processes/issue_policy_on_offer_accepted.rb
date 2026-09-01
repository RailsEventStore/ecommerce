module Processes
  class IssuePolicyOnOfferAccepted
    def initialize(command_bus)
      @command_bus = command_bus
    end

    def call(event)
      command_bus.call(
        Policies::IssuePolicy.new(
          policy_id: event.data.fetch(:application_id),
          premium: event.data.fetch(:premium)
        )
      )
    end

    private

    attr_reader :command_bus
  end
end
