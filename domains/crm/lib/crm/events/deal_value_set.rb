module Crm
  class DealValueSet < Infra::Event
    attribute :deal_id, Infra::Types::UUID
    attribute :value, Infra::Types::Integer
  end
end
