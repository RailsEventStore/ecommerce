module Crm
  class PipelineCreated < Infra::Event
    attribute :pipeline_id, Infra::Types::UUID
    attribute :name, Infra::Types::String
  end
end
