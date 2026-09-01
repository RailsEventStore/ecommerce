# frozen_string_literal: true

module Underwriting
  class AcceptOffer < Infra::Command
    attribute :application_id, Infra::Types::UUID

    alias aggregate_id application_id
  end
end
