module Ordering
  class OrderExpired < Infra::Event
    attribute :order_id, Infra::Types::UUID
  end
end
