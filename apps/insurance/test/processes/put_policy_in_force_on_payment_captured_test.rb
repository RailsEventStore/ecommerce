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

      assert_instance_of(Policies::PutPolicyInForce, command_bus.received)
      assert_equal(policy_id, command_bus.received.policy_id)
    end
  end
end
