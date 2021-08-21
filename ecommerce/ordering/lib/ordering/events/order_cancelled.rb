module Ordering
  class OrderCancelled < Event
    attribute :order_id, Types::UUID
  end
end