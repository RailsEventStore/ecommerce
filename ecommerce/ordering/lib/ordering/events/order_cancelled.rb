module Ordering
  class OrderCancelled < Infra::Event
    attribute :order_id, Infra::Types::UUID
  end
end
