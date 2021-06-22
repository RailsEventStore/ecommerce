module Ordering
  class OrderPaid < Event
    attribute :order_id,       Types::UUID
  end
end
