require "infra"
require_relative "policies/events/policy_issued"
require_relative "policies/events/policy_activated"
require_relative "policies/events/policy_terminated"
require_relative "policies/commands/issue_policy"
require_relative "policies/commands/activate_policy"
require_relative "policies/commands/terminate_policy"
require_relative "policies/policy_service"
require_relative "policies/policy"

module Policies
  class Configuration
    def call(event_store, command_bus)
      command_bus.register(IssuePolicy, OnIssuePolicy.new(event_store))
      command_bus.register(ActivatePolicy, OnActivatePolicy.new(event_store))
      command_bus.register(TerminatePolicy, OnTerminatePolicy.new(event_store))
    end
  end
end
