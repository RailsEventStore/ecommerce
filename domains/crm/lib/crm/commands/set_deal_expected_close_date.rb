module Crm
  class SetDealExpectedCloseDate
    UUID = /\A[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}\z/i
    attr_reader :deal_id, :expected_close_date
    alias aggregate_id deal_id

    def initialize(deal_id, expected_close_date)
      @deal_id = deal_id
      @expected_close_date = expected_close_date
      valid = @deal_id.is_a?(String) && UUID.match?(@deal_id) && @expected_close_date.is_a?(String)
      raise Infra::Command::Invalid unless valid
    end
  end
end
