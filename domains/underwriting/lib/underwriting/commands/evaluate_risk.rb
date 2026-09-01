# frozen_string_literal: true

module Underwriting
  class EvaluateRisk < Infra::Command
    attribute :application_id, Infra::Types::UUID
    attribute :risk_class, RiskClass

    alias aggregate_id application_id
  end
end
