# frozen_string_literal: true

module Underwriting
  RiskClass = Infra::Types::Strict::String.enum("low", "standard", "high")
end
