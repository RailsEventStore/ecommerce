module Crm
  class SetDealValue
    UUID = /\A[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}\z/i
    attr_reader :deal_id, :value
    alias aggregate_id deal_id

    def initialize(deal_id, value)
      @deal_id = deal_id
      @value = value
      valid = @deal_id.is_a?(String) && UUID.match?(@deal_id) && @value.instance_of?(Integer)
      raise Infra::Command::Invalid unless valid
    end
  end
end
