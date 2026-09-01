# frozen_string_literal: true

module Policies
  class PolicyTerminated < Infra::Event
    attribute :policy_id, Infra::Types::UUID
  end
end
