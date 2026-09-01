require "minitest/autorun" unless defined?(Mutant)
require "mutant/minitest/coverage"

require_relative "../lib/claims"

module Claims
  class Test < Infra::InMemoryTest
    attr_reader :payout_gateway

    def before_setup
      super
      @payout_gateway = FakeGateway.new
      Configuration.new(-> { @payout_gateway }).call(event_store, command_bus)
    end

    private

    def stream(claim_id)
      "Claims::Claim$#{claim_id}"
    end

    def report_damage(claim_id, policy_id, description = "Flooded kitchen")
      act(ReportDamage.new(claim_id: claim_id, policy_id: policy_id, description: description))
    end

    def evaluate_damage(claim_id, amount = BigDecimal("300"))
      act(EvaluateDamage.new(claim_id: claim_id, amount: amount))
    end

    def pay_compensation(claim_id)
      act(PayCompensation.new(claim_id: claim_id))
    end
  end
end
