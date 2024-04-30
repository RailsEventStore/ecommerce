module Ordering
  class OrderPlaced < Infra::Event
    attribute :order_id, Infra::Types::UUID
    attribute :order_number, Infra::Types::OrderNumber
  end
end
