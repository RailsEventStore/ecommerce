module Crm
  class CreatePipeline < Infra::Command
    attribute :pipeline_id, Infra::Types::UUID
    attribute :name, Infra::Types::String
    alias aggregate_id pipeline_id
  end
end
