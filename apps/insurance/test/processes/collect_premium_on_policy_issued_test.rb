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

      assert_command(Payments::SetPaymentAmount.new(order_id: policy_id, amount: BigDecimal("50")))
    end
  end
end
