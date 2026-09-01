# frozen_string_literal: true

module Policies
  class PolicyInForce < Infra::Event
    attribute :policy_id, Infra::Types::UUID
  end
end
