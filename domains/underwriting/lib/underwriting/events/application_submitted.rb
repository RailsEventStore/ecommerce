# frozen_string_literal: true

module Underwriting
  class ApplicationSubmitted < Infra::Event
    attribute :application_id, Infra::Types::UUID
    attribute :coverage_amount, Infra::Types::Price
  end
end
