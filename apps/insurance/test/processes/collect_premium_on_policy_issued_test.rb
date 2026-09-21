require "test_helper"

module Processes
  class CollectPremiumOnPolicyIssuedTest < ProcessTest
    cover "Processes::CollectPremiumOnPolicyIssued*"

    def test_sets_payment_amount_to_premium
      policy_id = SecureRandom.uuid
      process = CollectPremiumOnPolicyIssued.new(command_bus)

      process.call(
        Policies::PolicyIssued.new(data: { policy_id: policy_id, premium: BigDecimal("50") })
      )

      assert_instance_of(Payments::SetPaymentAmount, command_bus.received)
      assert_equal(policy_id, command_bus.received.order_id)
      assert_equal(BigDecimal("50"), command_bus.received.amount)
    end
  end
end
