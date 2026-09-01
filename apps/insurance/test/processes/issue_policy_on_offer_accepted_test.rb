require "test_helper"

module Processes
  class IssuePolicyOnOfferAcceptedTest < ProcessTest
    cover "Processes::IssuePolicyOnOfferAccepted*"

    def test_issues_policy_with_accepted_premium
      application_id = SecureRandom.uuid
      process = IssuePolicyOnOfferAccepted.new(command_bus)

      process.call(
        Underwriting::OfferAccepted.new(data: { application_id: application_id, premium: BigDecimal("50") })
      )

      assert_command(Policies::IssuePolicy.new(policy_id: application_id, premium: BigDecimal("50")))
    end
  end
end
