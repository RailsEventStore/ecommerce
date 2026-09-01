# frozen_string_literal: true

module Policies
  class PutPolicyInForce < Infra::Command
    attribute :policy_id, Infra::Types::UUID

    alias aggregate_id policy_id
  end
end
