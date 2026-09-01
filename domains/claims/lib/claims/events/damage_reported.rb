# frozen_string_literal: true

module Claims
  class DamageReported < Infra::Event
    attribute :claim_id, Infra::Types::UUID
    attribute :policy_id, Infra::Types::UUID
    attribute :description, Infra::Types::String
  end
end
