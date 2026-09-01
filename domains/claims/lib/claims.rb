require "infra"
require_relative "claims/events/loss_reported"
require_relative "claims/events/loss_assessed"
require_relative "claims/events/claim_settled"
require_relative "claims/commands/report_loss"
require_relative "claims/commands/assess_loss"
require_relative "claims/commands/settle_claim"
require_relative "claims/claim_service"
require_relative "claims/claim"
require_relative "claims/fake_gateway"

module Claims
  class Configuration
    def initialize(gateway)
      @gateway = gateway
    end

    def call(event_store, command_bus)
      command_bus.register(ReportLoss, OnReportLoss.new(event_store))
      command_bus.register(AssessLoss, OnAssessLoss.new(event_store))
      command_bus.register(SettleClaim, OnSettleClaim.new(event_store, @gateway))
    end
  end
end
