module Crm
  class CreateDeal < Infra::Command
    attribute :deal_id, Infra::Types::UUID
    attribute :pipeline_id, Infra::Types::UUID
    attribute :name, Infra::Types::String
    alias aggregate_id deal_id
  end
end
