module Ordering
  class ItemAddedToBasket < Infra::Event
    attribute :order_id,   Infra::Types::UUID
    attribute :product_id, Infra::Types::UUID
  end
end