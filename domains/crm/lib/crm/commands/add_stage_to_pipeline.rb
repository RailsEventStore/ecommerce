module Crm
  class AddStageToPipeline
    UUID = /\A[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}\z/i
    attr_reader :pipeline_id, :stage_name
    alias aggregate_id pipeline_id

    def initialize(pipeline_id, stage_name)
      @pipeline_id = pipeline_id
      @stage_name = stage_name
      valid = @pipeline_id.is_a?(String) && UUID.match?(@pipeline_id) && @stage_name.is_a?(String)
      raise Infra::Command::Invalid unless valid
    end
  end
end
