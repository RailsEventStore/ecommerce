module Crm
  class SetDealExpectedCloseDate < Infra::Command
    attribute :deal_id, Infra::Types::UUID
    attribute :expected_close_date, Infra::Types::String
    alias aggregate_id deal_id
  end
end
