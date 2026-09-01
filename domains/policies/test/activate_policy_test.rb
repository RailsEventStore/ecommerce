require_relative "test_helper"

module Policies
  class ActivatePolicyTest < Test
    cover "Policies*"

    def test_issued_policy_can_be_activated
      policy_id = SecureRandom.uuid
      issue_policy(policy_id)

      assert_events(
        stream(policy_id),
        PolicyActivated.new(data: { policy_id: policy_id })
      ) { activate_policy(policy_id) }
    end

    def test_policy_can_not_be_activated_before_issuance
      policy_id = SecureRandom.uuid

      assert_raises(Policy::InvalidState) do
        activate_policy(policy_id)
      end
    end

    def test_policy_can_not_be_activated_twice
      policy_id = SecureRandom.uuid
      issue_policy(policy_id)
      activate_policy(policy_id)

      assert_raises(Policy::InvalidState) do
        activate_policy(policy_id)
      end
    end
  end
end
