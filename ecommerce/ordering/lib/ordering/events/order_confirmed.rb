module Ordering
  class OrderConfirmed < Infra::Event
    attribute :order_id, Infra::Types::UUID
  end
end
