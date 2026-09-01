require "infra"
require_relative "claims/events/damage_reported"
require_relative "claims/events/damage_evaluated"
require_relative "claims/events/compensation_paid"
require_relative "claims/commands/report_damage"
require_relative "claims/commands/evaluate_damage"
require_relative "claims/commands/pay_compensation"
require_relative "claims/claim_service"
require_relative "claims/claim"
require_relative "claims/fake_gateway"

module Claims
  class Configuration
    def initialize(gateway)
      @gateway = gateway
    end

    def call(event_store, command_bus)
      command_bus.register(ReportDamage, OnReportDamage.new(event_store))
      command_bus.register(EvaluateDamage, OnEvaluateDamage.new(event_store))
      command_bus.register(PayCompensation, OnPayCompensation.new(event_store, @gateway))
    end
  end
end
