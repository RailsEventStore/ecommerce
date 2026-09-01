require "test_helper"

module Processes
  class ActivatePolicyOnPaymentCapturedTest < ProcessTest
    cover "Processes::ActivatePolicyOnPaymentCaptured*"

    def test_activates_policy_when_premium_is_captured
      policy_id = SecureRandom.uuid
      process = ActivatePolicyOnPaymentCaptured.new(command_bus)

      process.call(
        Payments::PaymentCaptured.new(data: { order_id: policy_id })
      )

      assert_command(Policies::ActivatePolicy.new(policy_id: policy_id))
    end
  end
end
