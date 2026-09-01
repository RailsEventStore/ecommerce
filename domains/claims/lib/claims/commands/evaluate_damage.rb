# frozen_string_literal: true

module Claims
  class EvaluateDamage < Infra::Command
    attribute :claim_id, Infra::Types::UUID
    attribute :amount, Infra::Types::Price

    alias aggregate_id claim_id
  end
end
