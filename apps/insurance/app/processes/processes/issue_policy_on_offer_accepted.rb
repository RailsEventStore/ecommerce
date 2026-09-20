module Processes
  class IssuePolicyOnOfferAccepted
    def initialize(command_bus)
      @command_bus = command_bus
    end

    def call(event)
      command_bus.call(
        Policies::IssuePolicy.new(
          event.data.fetch(:application_id),
          event.data.fetch(:premium)
        )
      )
    end

    private

    attr_reader :command_bus
  end
end
