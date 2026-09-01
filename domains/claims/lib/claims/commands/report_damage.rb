# frozen_string_literal: true

module Claims
  class ReportDamage < Infra::Command
    attribute :claim_id, Infra::Types::UUID
    attribute :policy_id, Infra::Types::UUID
    attribute :description, Infra::Types::String

    alias aggregate_id claim_id
  end
end
