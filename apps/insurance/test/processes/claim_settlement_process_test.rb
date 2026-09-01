require "test_helper"

module Processes
  class ClaimSettlementProcessTest < ProcessTest
    cover "Processes::ClaimSettlementProcess*"

    def test_settles_claim_when_in_force_policy_has_assessed_loss
      given([policy_in_force, loss_assessed], process: process)

      assert_all_commands(Claims::SettleClaim.new(claim_id: claim_id))
    end

    def test_pays_compensation_when_policy_activation_comes_last
      given([loss_assessed, policy_in_force], process: process)

      assert_all_commands(Claims::SettleClaim.new(claim_id: claim_id))
    end

    def test_no_settlement_without_in_force_policy
      given([loss_assessed], process: process)

      assert_no_command
    end

    def test_no_payout_without_evaluated_damage
      given([policy_in_force], process: process)

      assert_no_command
    end

    def test_no_payout_when_policy_terminated
      given([policy_in_force, policy_terminated, loss_assessed], process: process)

      assert_no_command
    end

    def test_no_second_payout_after_claim_settled
      given([policy_in_force, loss_assessed], process: process)
      command_bus.clear_all_received

      given([claim_settled], process: process)

      assert_no_command
    end

    def test_pays_next_claim_on_same_policy
      given([policy_in_force, loss_assessed, claim_settled], process: process)
      command_bus.clear_all_received

      given([next_loss_assessed], process: process)

      assert_all_commands(Claims::SettleClaim.new(claim_id: next_claim_id))
    end

    def test_claims_of_other_policies_do_not_mix
      given([policy_in_force, other_policy_loss_assessed], process: process)

      assert_no_command
    end

    private

    def process
      @process ||= ClaimSettlementProcess.new(event_store, command_bus)
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

    def policy_in_force
      Policies::PolicyInForce.new(data: { policy_id: policy_id })
    end

    def policy_terminated
      Policies::PolicyTerminated.new(data: { policy_id: policy_id })
    end

    def loss_assessed
      Claims::LossAssessed.new(data: { claim_id: claim_id, policy_id: policy_id, amount: BigDecimal("300") })
    end

    def claim_settled
      Claims::ClaimSettled.new(data: { claim_id: claim_id, policy_id: policy_id, amount: BigDecimal("300") })
    end

    def next_loss_assessed
      Claims::LossAssessed.new(data: { claim_id: next_claim_id, policy_id: policy_id, amount: BigDecimal("120") })
    end

    def other_policy_loss_assessed
      Claims::LossAssessed.new(data: { claim_id: claim_id, policy_id: other_policy_id, amount: BigDecimal("300") })
    end
  end
end
