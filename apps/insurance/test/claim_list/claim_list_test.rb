require "test_helper"

module ClaimList
  class ClaimListTest < InMemoryRESTestCase
    cover "ClaimList*"

    def configure(event_store, _command_bus)
      ClaimList::Configuration.new.call(event_store)
    end

    def test_damage_reported
      report_damage(claim_id, policy_id, "Flooded kitchen")
      report_damage(other_claim_id, policy_id, "Broken window")

      assert_equal(2, ClaimList.all.count)
      assert_equal([other_claim_id, claim_id], ClaimList.all.map(&:claim_id))
      claim = ClaimList.all.find_by!(claim_id: claim_id)
      assert_equal(policy_id, claim.policy_id)
      assert_equal("Flooded kitchen", claim.description)
      assert_equal("reported", claim.state)
    end

    def test_damage_evaluated
      report_damage(claim_id, policy_id, "Flooded kitchen")
      report_damage(other_claim_id, policy_id, "Broken window")
      evaluate_damage(claim_id, BigDecimal("300"))

      claim = ClaimList.all.find_by!(claim_id: claim_id)
      assert_equal(BigDecimal("300"), claim.amount)
      assert_equal("evaluated", claim.state)
      other = ClaimList.all.find_by!(claim_id: other_claim_id)
      assert_nil(other.amount)
      assert_equal("reported", other.state)
    end

    def test_compensation_paid
      report_damage(claim_id, policy_id, "Flooded kitchen")
      report_damage(other_claim_id, policy_id, "Broken window")
      evaluate_damage(claim_id, BigDecimal("300"))
      pay_compensation(claim_id, BigDecimal("300"))

      assert_equal("paid", ClaimList.all.find_by!(claim_id: claim_id).state)
      assert_equal("reported", ClaimList.all.find_by!(claim_id: other_claim_id).state)
    end

    private

    def claim_id
      @claim_id ||= SecureRandom.uuid
    end

    def other_claim_id
      @other_claim_id ||= SecureRandom.uuid
    end

    def policy_id
      @policy_id ||= SecureRandom.uuid
    end

    def report_damage(id, pid, description)
      event_store.publish(
        Claims::DamageReported.new(data: { claim_id: id, policy_id: pid, description: description })
      )
    end

    def evaluate_damage(id, amount)
      event_store.publish(
        Claims::DamageEvaluated.new(data: { claim_id: id, policy_id: policy_id, amount: amount })
      )
    end

    def pay_compensation(id, amount)
      event_store.publish(
        Claims::CompensationPaid.new(data: { claim_id: id, policy_id: policy_id, amount: amount })
      )
    end
  end
end
