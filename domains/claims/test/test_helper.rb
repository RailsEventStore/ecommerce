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

    def report_loss(claim_id, policy_id, description = "Flooded kitchen")
      act(ReportLoss.new(claim_id, policy_id, description))
    end

    def assess_loss(claim_id, amount = BigDecimal("300"))
      act(AssessLoss.new(claim_id, amount))
    end

    def settle_claim(claim_id)
      act(SettleClaim.new(claim_id))
    end
  end
end
