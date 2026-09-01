# frozen_string_literal: true

module Underwriting
  class RiskEvaluated < Infra::Event
    attribute :application_id, Infra::Types::UUID
    attribute :risk_class, RiskClass
  end
end
