require_relative "test_helper"

module Policies
  class TerminatePolicyTest < Test
    cover "Policies*"

    def test_active_policy_can_be_terminated
      policy_id = SecureRandom.uuid
      issue_policy(policy_id)
      activate_policy(policy_id)

      assert_events(
        stream(policy_id),
        PolicyTerminated.new(data: { policy_id: policy_id })
      ) { terminate_policy(policy_id) }
    end

    def test_policy_can_not_be_terminated_before_activation
      policy_id = SecureRandom.uuid
      issue_policy(policy_id)

      assert_raises(Policy::InvalidState) do
        terminate_policy(policy_id)
      end
    end

    def test_policy_can_not_be_terminated_twice
      policy_id = SecureRandom.uuid
      issue_policy(policy_id)
      activate_policy(policy_id)
      terminate_policy(policy_id)

      assert_raises(Policy::InvalidState) do
        terminate_policy(policy_id)
      end
    end
  end
end
