require_relative "test_helper"

module Claims
  class ReportLossTest < Test
    cover "Claims*"

    def test_damage_can_be_reported
      claim_id = SecureRandom.uuid
      policy_id = SecureRandom.uuid

      assert_events(
        stream(claim_id),
        LossReported.new(data: { claim_id: claim_id, policy_id: policy_id, description: "Flooded kitchen" })
      ) { report_loss(claim_id, policy_id) }
    end

    def test_damage_can_not_be_reported_twice
      claim_id = SecureRandom.uuid
      policy_id = SecureRandom.uuid
      report_loss(claim_id, policy_id)

      assert_raises(Claim::InvalidState) do
        report_loss(claim_id, policy_id)
      end
    end
  end
end
