module Crm
  class SetDealValue < Infra::Command
    attribute :deal_id, Infra::Types::UUID
    attribute :value, Infra::Types::Integer
    alias aggregate_id deal_id
  end
end
