module Crm
  class DealExpectedCloseDateSet < Infra::Event
    attribute :deal_id, Infra::Types::UUID
    attribute :expected_close_date, Infra::Types::String
  end
end
