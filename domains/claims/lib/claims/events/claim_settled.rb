# frozen_string_literal: true

module Claims
  class ClaimSettled < Infra::Event
    attribute :claim_id, Infra::Types::UUID
    attribute :policy_id, Infra::Types::UUID
    attribute :amount, Infra::Types::Price
  end
end
