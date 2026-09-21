module Crm
  class MoveDealToStage
    UUID = /\A[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}\z/i
    attr_reader :deal_id, :stage
    alias aggregate_id deal_id

    def initialize(deal_id, stage)
      @deal_id = deal_id
      @stage = stage
      valid = @deal_id.is_a?(String) && UUID.match?(@deal_id) && @stage.is_a?(String)
      raise Infra::Command::Invalid unless valid
    end
  end
end
