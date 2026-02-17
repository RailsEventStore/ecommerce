module Crm
  class StageRemovedFromPipeline < Infra::Event
    attribute :pipeline_id, Infra::Types::UUID
    attribute :stage_name, Infra::Types::String
  end
end
