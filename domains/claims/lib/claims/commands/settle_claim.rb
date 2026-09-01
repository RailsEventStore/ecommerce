# frozen_string_literal: true

module Claims
  class SettleClaim < Infra::Command
    attribute :claim_id, Infra::Types::UUID

    alias aggregate_id claim_id
  end
end
