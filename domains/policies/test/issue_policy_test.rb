require_relative "test_helper"

module Policies
  class IssuePolicyTest < Test
    cover "Policies*"

    def test_policy_can_be_issued
      policy_id = SecureRandom.uuid

      assert_events(
        stream(policy_id),
        PolicyIssued.new(data: { policy_id: policy_id, premium: BigDecimal("50") })
      ) { issue_policy(policy_id) }
    end

    def test_policy_can_not_be_issued_twice
      policy_id = SecureRandom.uuid
      issue_policy(policy_id)

      assert_raises(Policy::InvalidState) do
        issue_policy(policy_id)
      end
    end
  end
end
