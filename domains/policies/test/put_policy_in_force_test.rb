require_relative "test_helper"

module Policies
  class PutPolicyInForceTest < Test
    cover "Policies*"

    def test_issued_policy_can_be_put_in_force
      policy_id = SecureRandom.uuid
      issue_policy(policy_id)

      assert_events(
        stream(policy_id),
        PolicyInForce.new(data: { policy_id: policy_id })
      ) { put_policy_in_force(policy_id) }
    end

    def test_policy_can_not_be_put_in_force_before_issuance
      policy_id = SecureRandom.uuid

      assert_raises(Policy::InvalidState) do
        put_policy_in_force(policy_id)
      end
    end

    def test_policy_can_not_be_put_in_force_twice
      policy_id = SecureRandom.uuid
      issue_policy(policy_id)
      put_policy_in_force(policy_id)

      assert_raises(Policy::InvalidState) do
        put_policy_in_force(policy_id)
      end
    end
  end
end
