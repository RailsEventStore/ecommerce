module Crm
  class StageAddedToPipeline < Infra::Event
    attribute :pipeline_id, Infra::Types::UUID
    attribute :stage_name, Infra::Types::String
  end
end
