require "minitest/autorun" unless defined?(Mutant)
require "mutant/minitest/coverage"

require_relative "../lib/underwriting"

module Underwriting
  class Test < Infra::InMemoryTest
    def before_setup
      super
      Configuration.new.call(event_store, command_bus)
    end

    private

    def stream(application_id)
      "Underwriting::InsuranceApplication$#{application_id}"
    end

    def submit_application(application_id, coverage_amount = BigDecimal("1000"))
      act(SubmitApplication.new(application_id: application_id, coverage_amount: coverage_amount))
    end

    def evaluate_risk(application_id, risk_class = "low")
      act(EvaluateRisk.new(application_id: application_id, risk_class: risk_class))
    end

    def calculate_premium(application_id)
      act(CalculatePremium.new(application_id: application_id))
    end

    def accept_offer(application_id)
      act(AcceptOffer.new(application_id: application_id))
    end
  end
end
