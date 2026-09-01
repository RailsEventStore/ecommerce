require "test_helper"

module Processes
  class CompensationProcessTest < ProcessTest
    cover "Processes::CompensationProcess*"

    def test_pays_compensation_when_active_policy_has_evaluated_damage
      given([policy_activated, damage_evaluated], process: process)

      assert_all_commands(Claims::PayCompensation.new(claim_id: claim_id))
    end

    def test_pays_compensation_when_policy_activation_comes_last
      given([damage_evaluated, policy_activated], process: process)

      assert_all_commands(Claims::PayCompensation.new(claim_id: claim_id))
    end

    def test_no_payout_without_active_policy
      given([damage_evaluated], process: process)

      assert_no_command
    end

    def test_no_payout_without_evaluated_damage
      given([policy_activated], process: process)

      assert_no_command
    end

    def test_no_payout_when_policy_terminated
      given([policy_activated, policy_terminated, damage_evaluated], process: process)

      assert_no_command
    end

    def test_no_second_payout_after_compensation_paid
      given([policy_activated, damage_evaluated], process: process)
      command_bus.clear_all_received

      given([compensation_paid], process: process)

      assert_no_command
    end

    def test_pays_next_claim_on_same_policy
      given([policy_activated, damage_evaluated, compensation_paid], process: process)
      command_bus.clear_all_received

      given([next_damage_evaluated], process: process)

      assert_all_commands(Claims::PayCompensation.new(claim_id: next_claim_id))
    end

    def test_claims_of_other_policies_do_not_mix
      given([policy_activated, other_policy_damage_evaluated], process: process)

      assert_no_command
    end

    private

    def process
      @process ||= CompensationProcess.new(event_store, command_bus)
    end

    def policy_id
      @policy_id ||= SecureRandom.uuid
    end

    def other_policy_id
      @other_policy_id ||= SecureRandom.uuid
    end

    def claim_id
      @claim_id ||= SecureRandom.uuid
    end

    def next_claim_id
      @next_claim_id ||= SecureRandom.uuid
    end

    def policy_activated
      Policies::PolicyActivated.new(data: { policy_id: policy_id })
    end

    def policy_terminated
      Policies::PolicyTerminated.new(data: { policy_id: policy_id })
    end

    def damage_evaluated
      Claims::DamageEvaluated.new(data: { claim_id: claim_id, policy_id: policy_id, amount: BigDecimal("300") })
    end

    def compensation_paid
      Claims::CompensationPaid.new(data: { claim_id: claim_id, policy_id: policy_id, amount: BigDecimal("300") })
    end

    def next_damage_evaluated
      Claims::DamageEvaluated.new(data: { claim_id: next_claim_id, policy_id: policy_id, amount: BigDecimal("120") })
    end

    def other_policy_damage_evaluated
      Claims::DamageEvaluated.new(data: { claim_id: claim_id, policy_id: other_policy_id, amount: BigDecimal("300") })
    end
  end
end
