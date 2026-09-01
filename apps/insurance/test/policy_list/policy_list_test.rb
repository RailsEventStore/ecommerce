require "test_helper"

module PolicyList
  class PolicyListTest < InMemoryRESTestCase
    cover "PolicyList*"

    def configure(event_store, _command_bus)
      PolicyList::Configuration.new.call(event_store)
    end

    def test_policy_issued
      issue_policy(policy_id, BigDecimal("50"))
      issue_policy(other_policy_id, BigDecimal("70"))

      assert_equal(2, PolicyList.all.count)
      assert_equal([other_policy_id, policy_id], PolicyList.all.map(&:policy_id))
      policy = PolicyList.all.find_by!(policy_id: policy_id)
      assert_equal(BigDecimal("50"), policy.premium)
      assert_equal("issued", policy.state)
    end

    def test_policy_in_force
      issue_policy(policy_id, BigDecimal("50"))
      issue_policy(other_policy_id, BigDecimal("70"))
      put_policy_in_force(policy_id)

      assert_equal("in force", PolicyList.all.find_by!(policy_id: policy_id).state)
      assert_equal("issued", PolicyList.all.find_by!(policy_id: other_policy_id).state)
    end

    def test_policy_terminated
      issue_policy(policy_id, BigDecimal("50"))
      issue_policy(other_policy_id, BigDecimal("70"))
      put_policy_in_force(policy_id)
      terminate_policy(policy_id)

      assert_equal("terminated", PolicyList.all.find_by!(policy_id: policy_id).state)
      assert_equal("issued", PolicyList.all.find_by!(policy_id: other_policy_id).state)
    end

    private

    def policy_id
      @policy_id ||= SecureRandom.uuid
    end

    def other_policy_id
      @other_policy_id ||= SecureRandom.uuid
    end

    def issue_policy(id, premium)
      event_store.publish(Policies::PolicyIssued.new(data: { policy_id: id, premium: premium }))
    end

    def put_policy_in_force(id)
      event_store.publish(Policies::PolicyInForce.new(data: { policy_id: id }))
    end

    def terminate_policy(id)
      event_store.publish(Policies::PolicyTerminated.new(data: { policy_id: id }))
    end
  end
end
