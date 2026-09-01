require "infra"
require_relative "underwriting/risk_class"
require_relative "underwriting/events/application_submitted"
require_relative "underwriting/events/risk_evaluated"
require_relative "underwriting/events/premium_calculated"
require_relative "underwriting/events/offer_accepted"
require_relative "underwriting/commands/submit_application"
require_relative "underwriting/commands/evaluate_risk"
require_relative "underwriting/commands/calculate_premium"
require_relative "underwriting/commands/accept_offer"
require_relative "underwriting/insurance_application_service"
require_relative "underwriting/insurance_application"

module Underwriting
  class Configuration
    def call(event_store, command_bus)
      command_bus.register(SubmitApplication, OnSubmitApplication.new(event_store))
      command_bus.register(EvaluateRisk, OnEvaluateRisk.new(event_store))
      command_bus.register(CalculatePremium, OnCalculatePremium.new(event_store))
      command_bus.register(AcceptOffer, OnAcceptOffer.new(event_store))
    end
  end
end
