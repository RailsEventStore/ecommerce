require "minitest/autorun" unless defined?(Mutant)
require "mutant/minitest/coverage"

require_relative "../lib/policies"

module Policies
  class Test < Infra::InMemoryTest
    def before_setup
      super
      Configuration.new.call(event_store, command_bus)
    end

    private

    def stream(policy_id)
      "Policies::Policy$#{policy_id}"
    end

    def issue_policy(policy_id, premium = BigDecimal("50"))
      act(IssuePolicy.new(policy_id: policy_id, premium: premium))
    end

    def activate_policy(policy_id)
      act(ActivatePolicy.new(policy_id: policy_id))
    end

    def terminate_policy(policy_id)
      act(TerminatePolicy.new(policy_id: policy_id))
    end
  end
end
