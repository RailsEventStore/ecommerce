module Ordering
  class OrderPaid < Infra::Event
    attribute :order_id, Infra::Types::UUID
  end
end
