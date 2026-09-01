# frozen_string_literal: true

module Policies
  class PolicyIssued < Infra::Event
    attribute :policy_id, Infra::Types::UUID
    attribute :premium, Infra::Types::Price
  end
end
