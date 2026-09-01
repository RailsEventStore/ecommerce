require_relative "test_helper"

module Claims
  class SettleClaimTest < Test
    cover "Claims*"

    def test_evaluated_claim_compensation_is_paid_out
      claim_id = SecureRandom.uuid
      policy_id = SecureRandom.uuid
      report_loss(claim_id, policy_id)
      assess_loss(claim_id, BigDecimal("300"))

      assert_events(
        stream(claim_id),
        ClaimSettled.new(data: { claim_id: claim_id, policy_id: policy_id, amount: BigDecimal("300") })
      ) { settle_claim(claim_id) }

      assert_equal([[claim_id, BigDecimal("300")]], payout_gateway.paid_out_transactions)
    end

    def test_compensation_can_not_be_paid_before_evaluation
      claim_id = SecureRandom.uuid
      report_loss(claim_id, SecureRandom.uuid)

      assert_raises(Claim::InvalidState) do
        settle_claim(claim_id)
      end
      assert_equal([], payout_gateway.paid_out_transactions)
    end

    def test_compensation_can_not_be_paid_twice
      claim_id = SecureRandom.uuid
      report_loss(claim_id, SecureRandom.uuid)
      assess_loss(claim_id)
      settle_claim(claim_id)

      assert_raises(Claim::InvalidState) do
        settle_claim(claim_id)
      end
      assert_equal(1, payout_gateway.paid_out_transactions.size)
    end
  end
end
