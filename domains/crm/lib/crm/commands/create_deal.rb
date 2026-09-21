module Crm
  class CreateDeal
    UUID = /\A[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}\z/i
    attr_reader :deal_id, :pipeline_id, :name
    alias aggregate_id deal_id

    def initialize(deal_id, pipeline_id, name)
      @deal_id = deal_id
      @pipeline_id = pipeline_id
      @name = name
      valid = [@deal_id, @pipeline_id].all? { |id| id.is_a?(String) && UUID.match?(id) } && @name.is_a?(String)
      raise Infra::Command::Invalid unless valid
    end
  end
end
