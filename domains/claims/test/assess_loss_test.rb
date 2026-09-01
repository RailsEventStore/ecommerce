require_relative "test_helper"

module Claims
  class AssessLossTest < Test
    cover "Claims*"

    def test_reported_damage_can_be_evaluated
      claim_id = SecureRandom.uuid
      policy_id = SecureRandom.uuid
      report_loss(claim_id, policy_id)

      assert_events(
        stream(claim_id),
        LossAssessed.new(data: { claim_id: claim_id, policy_id: policy_id, amount: BigDecimal("300") })
      ) { assess_loss(claim_id) }
    end

    def test_damage_can_not_be_evaluated_before_report
      claim_id = SecureRandom.uuid

      assert_raises(Claim::InvalidState) do
        assess_loss(claim_id)
      end
    end

    def test_damage_can_not_be_evaluated_twice
      claim_id = SecureRandom.uuid
      report_loss(claim_id, SecureRandom.uuid)
      assess_loss(claim_id)

      assert_raises(Claim::InvalidState) do
        assess_loss(claim_id)
      end
    end
  end
end
