# frozen_string_literal: true

module Underwriting
  class EvaluateRisk
    UUID = /\A[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}\z/i
    RISK_CLASSES = %w[low standard high].freeze
    attr_reader :application_id, :risk_class

    alias aggregate_id application_id

    def initialize(application_id, risk_class)
      @application_id = application_id
      @risk_class = risk_class
      valid = UUID.match?(@application_id) && RISK_CLASSES.include?(@risk_class)
    rescue TypeError
      raise Infra::Command::Invalid
    else
      raise Infra::Command::Invalid unless valid
    end
  end
end
