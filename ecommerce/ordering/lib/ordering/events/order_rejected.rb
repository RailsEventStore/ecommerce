module Ordering
  class OrderRejected < Infra::Event
    attribute :order_id, Infra::Types::UUID
  end
end
