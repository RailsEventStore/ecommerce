module Crm
  class AddStageToPipeline < Infra::Command
    attribute :pipeline_id, Infra::Types::UUID
    attribute :stage_name, Infra::Types::String
    alias aggregate_id pipeline_id
  end
end
