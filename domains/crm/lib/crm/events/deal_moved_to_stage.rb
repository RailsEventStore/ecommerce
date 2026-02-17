module Crm
  class DealMovedToStage < Infra::Event
    attribute :deal_id, Infra::Types::UUID
    attribute :stage, Infra::Types::String
  end
end
