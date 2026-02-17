module Crm
  class DealCreated < Infra::Event
    attribute :deal_id, Infra::Types::UUID
    attribute :pipeline_id, Infra::Types::UUID
    attribute :name, Infra::Types::String
  end
end
