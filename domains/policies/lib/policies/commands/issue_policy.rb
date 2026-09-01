# frozen_string_literal: true

module Policies
  class IssuePolicy < Infra::Command
    attribute :policy_id, Infra::Types::UUID
    attribute :premium, Infra::Types::Price

    alias aggregate_id policy_id
  end
end
