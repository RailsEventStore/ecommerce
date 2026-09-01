require "test_helper"

module Processes
  class PutPolicyInForceOnPaymentCapturedTest < ProcessTest
    cover "Processes::PutPolicyInForceOnPaymentCaptured*"

    def test_puts_policy_in_force_when_premium_is_captured
      policy_id = SecureRandom.uuid
      process = PutPolicyInForceOnPaymentCaptured.new(command_bus)

      process.call(
        Payments::PaymentCaptured.new(data: { order_id: policy_id })
      )

      assert_command(Policies::PutPolicyInForce.new(policy_id: policy_id))
    end
  end
end
