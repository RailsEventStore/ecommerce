module Crm
  class MoveDealToStage < Infra::Command
    attribute :deal_id, Infra::Types::UUID
    attribute :stage, Infra::Types::String
    alias aggregate_id deal_id
  end
end
