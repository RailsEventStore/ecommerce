# frozen_string_literal: true

module Underwriting
  class SubmitApplication < Infra::Command
    attribute :application_id, Infra::Types::UUID
    attribute :coverage_amount, Infra::Types::Price

    alias aggregate_id application_id
  end
end
