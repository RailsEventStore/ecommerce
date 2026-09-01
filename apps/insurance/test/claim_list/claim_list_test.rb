require "test_helper"

module ClaimList
  class ClaimListTest < InMemoryRESTestCase
    cover "ClaimList*"

    def configure(event_store, _command_bus)
      ClaimList::Configuration.new.call(event_store)
    end

    def test_loss_reported
      report_loss(claim_id, policy_id, "Flooded kitchen")
      report_loss(other_claim_id, policy_id, "Broken window")

      assert_equal(2, ClaimList.all.count)
      assert_equal([other_claim_id, claim_id], ClaimList.all.map(&:claim_id))
      claim = ClaimList.all.find_by!(claim_id: claim_id)
      assert_equal(policy_id, claim.policy_id)
      assert_equal("Flooded kitchen", claim.description)
      assert_equal("reported", claim.state)
    end

    def test_loss_assessed
      report_loss(claim_id, policy_id, "Flooded kitchen")
      report_loss(other_claim_id, policy_id, "Broken window")
      assess_loss(claim_id, BigDecimal("300"))

      claim = ClaimList.all.find_by!(claim_id: claim_id)
      assert_equal(BigDecimal("300"), claim.amount)
      assert_equal("assessed", claim.state)
      other = ClaimList.all.find_by!(claim_id: other_claim_id)
      assert_nil(other.amount)
      assert_equal("reported", other.state)
    end

    def test_claim_settled
      report_loss(claim_id, policy_id, "Flooded kitchen")
      report_loss(other_claim_id, policy_id, "Broken window")
      assess_loss(claim_id, BigDecimal("300"))
      settle_claim(claim_id, BigDecimal("300"))

      assert_equal("settled", ClaimList.all.find_by!(claim_id: claim_id).state)
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

    def report_loss(id, pid, description)
      event_store.publish(
        Claims::LossReported.new(data: { claim_id: id, policy_id: pid, description: description })
      )
    end

    def assess_loss(id, amount)
      event_store.publish(
        Claims::LossAssessed.new(data: { claim_id: id, policy_id: policy_id, amount: amount })
      )
    end

    def settle_claim(id, amount)
      event_store.publish(
        Claims::ClaimSettled.new(data: { claim_id: id, policy_id: policy_id, amount: amount })
      )
    end
  end
end
