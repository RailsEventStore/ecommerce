# frozen_string_literal: true

module Policies
  class TerminatePolicy
    UUID = /\A[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}\z/i

    attr_reader :policy_id

    alias aggregate_id policy_id

    def initialize(policy_id)
      @policy_id = policy_id
      valid = UUID.match?(@policy_id)
    rescue TypeError
      raise Infra::Command::Invalid
    else
      raise Infra::Command::Invalid unless valid
    end
  end
end
