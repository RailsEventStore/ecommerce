require_relative "test_helper"

module Claims
  class EvaluateDamageTest < Test
    cover "Claims*"

    def test_reported_damage_can_be_evaluated
      claim_id = SecureRandom.uuid
      policy_id = SecureRandom.uuid
      report_damage(claim_id, policy_id)

      assert_events(
        stream(claim_id),
        DamageEvaluated.new(data: { claim_id: claim_id, policy_id: policy_id, amount: BigDecimal("300") })
      ) { evaluate_damage(claim_id) }
    end

    def test_damage_can_not_be_evaluated_before_report
      claim_id = SecureRandom.uuid

      assert_raises(Claim::InvalidState) do
        evaluate_damage(claim_id)
      end
    end

    def test_damage_can_not_be_evaluated_twice
      claim_id = SecureRandom.uuid
      report_damage(claim_id, SecureRandom.uuid)
      evaluate_damage(claim_id)

      assert_raises(Claim::InvalidState) do
        evaluate_damage(claim_id)
      end
    end
  end
end
