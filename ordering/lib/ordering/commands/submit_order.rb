module Ordering
  class SubmitOrder < Command
    attribute :order_id, Types::UUID
    attribute :customer_id, Types::UUID

    alias :aggregate_id :order_id
  end
end
