# frozen_string_literal: true

module Underwriting
  class InsuranceApplication
    include AggregateRoot

    InvalidState = Class.new(StandardError)

    PREMIUM_RATES = {
      "low" => BigDecimal("0.02"),
      "standard" => BigDecimal("0.05"),
      "high" => BigDecimal("0.10")
    }.freeze

    def initialize(id)
      @id = id
    end

    def submit(coverage_amount)
      raise InvalidState if @state
      apply ApplicationSubmitted.new(data: { application_id: @id, coverage_amount: coverage_amount })
    end

    def evaluate_risk(risk_class)
      raise InvalidState unless @state.equal?(:submitted)
      apply RiskEvaluated.new(data: { application_id: @id, risk_class: risk_class })
    end

    def calculate_premium
      raise InvalidState unless @state.equal?(:risk_evaluated)
      apply PremiumCalculated.new(
        data: {
          application_id: @id,
          premium: @coverage_amount * PREMIUM_RATES.fetch(@risk_class)
        }
      )
    end

    def accept_offer
      raise InvalidState unless @state.equal?(:priced)
      apply OfferAccepted.new(data: { application_id: @id, premium: @premium })
    end

    on ApplicationSubmitted do |event|
      @state = :submitted
      @coverage_amount = event.data.fetch(:coverage_amount)
    end

    on RiskEvaluated do |event|
      @state = :risk_evaluated
      @risk_class = event.data.fetch(:risk_class)
    end

    on PremiumCalculated do |event|
      @state = :priced
      @premium = event.data.fetch(:premium)
    end

    on OfferAccepted do |event|
      @state = :accepted
    end
  end
end
